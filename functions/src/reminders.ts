import * as admin from "firebase-admin";

export interface ChartData {
  id: string;
  userIds?: string[];
  emails?: string[];
  reminderEnabled?: boolean;
  timezone?: string;
}

export interface UserData {
  uid: string;
  email?: string;
  fcmTokens?: string[];
  timezone?: string;
}

export interface DailyEntryData {
  date?: string;
  observations?: unknown[];
}

/**
 * Returns the current local hour (0-23) and formatted date key (YYYY-MM-DD)
 * for a specific IANA timezone string. Defaults to 'America/Los_Angeles'.
 */
export function getLocalTimeInfo(
  now: Date = new Date(),
  timeZone: string = "America/Los_Angeles"
): { hour: number; dateKey: string } {
  try {
    const hourFormatter = new Intl.DateTimeFormat("en-US", {
      hour: "numeric",
      hourCycle: "h23",
      timeZone,
    });
    const hour = parseInt(hourFormatter.format(now), 10);

    const dateFormatter = new Intl.DateTimeFormat("en-CA", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      timeZone,
    });
    const dateKey = dateFormatter.format(now);

    return { hour, dateKey };
  } catch {
    // Fallback to America/Los_Angeles if invalid timezone string is provided
    return getLocalTimeInfo(now, "America/Los_Angeles");
  }
}

/**
 * Checks if a chart has any observations logged for the specified dateKey.
 */
export async function checkChartHasObservationForDate(
  db: admin.firestore.Firestore,
  chartId: string,
  dateKey: string
): Promise<boolean> {
  const chartRef = db.collection("charts").doc(chartId);

  // 1. Find the cycle that contains or starts on/before dateKey
  const eligibleCyclesSnap = await chartRef
    .collection("cycles")
    .where("startDate", "<=", dateKey)
    .orderBy("startDate", "desc")
    .limit(1)
    .get();

  if (eligibleCyclesSnap.empty) {
    return false;
  }

  const targetCycleDoc = eligibleCyclesSnap.docs[0];

  // Check subcollection dailyEntries first
  const dailyEntryDoc = await targetCycleDoc.ref
    .collection("dailyEntries")
    .doc(dateKey)
    .get();

  if (dailyEntryDoc.exists) {
    const data = dailyEntryDoc.data() as DailyEntryData;
    if (Array.isArray(data.observations) && data.observations.length > 0) {
      return true;
    }
  }

  // Fallback to top-level dailyEntries map on cycle document if present
  const cycleData = targetCycleDoc.data();
  if (cycleData && cycleData.dailyEntries && cycleData.dailyEntries[dateKey]) {
    const entry = cycleData.dailyEntries[dateKey] as DailyEntryData;
    if (Array.isArray(entry.observations) && entry.observations.length > 0) {
      return true;
    }
  }

  return false;
}

/**
 * Processes reminder notifications for a single eligible chart.
 */
async function processSingleChartReminder(
  db: admin.firestore.Firestore,
  messaging: admin.messaging.Messaging,
  eligibleChart: { chart: ChartData; chartId: string; dateKey: string },
  userCache: Map<string, UserData>
): Promise<{ reminderSent: boolean; tokensNotified: number }> {
  const { chart, chartId, dateKey } = eligibleChart;

  const hasObservation = await checkChartHasObservationForDate(
    db,
    chartId,
    dateKey
  );

  if (hasObservation) {
    // An observation has already been logged for today by user or partner
    return { reminderSent: false, tokensNotified: 0 };
  }

  const userIds = chart.userIds || [];
  if (userIds.length === 0) {
    return { reminderSent: false, tokensNotified: 0 };
  }

  // Collect all FCM tokens for all collaborators on this chart
  const tokensByUserId: Map<string, string[]> = new Map();
  const allTokens: string[] = [];

  for (const uid of userIds) {
    const userData = userCache.get(uid);
    if (userData) {
      const tokens = Array.isArray(userData.fcmTokens)
        ? userData.fcmTokens.filter((t) => typeof t === "string" && t.length > 0)
        : [];
      if (tokens.length > 0) {
        tokensByUserId.set(uid, tokens);
        allTokens.push(...tokens);
      }
    }
  }

  if (allTokens.length === 0) {
    return { reminderSent: false, tokensNotified: 0 };
  }

  // Dispatch Multicast Push Notification via Firebase Cloud Messaging
  const response = await messaging.sendEachForMulticast({
    tokens: allTokens,
    notification: {
      title: "Daily Observation Reminder",
      body: "Don't forget to log your Creighton observations for today!",
    },
    data: {
      chartId: chartId,
      date: dateKey,
      type: "daily_reminder",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "daily_logging_reminders",
        priority: "high",
        defaultSound: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: "Daily Observation Reminder",
            body: "Don't forget to log your Creighton observations for today!",
          },
          sound: "default",
          badge: 1,
        },
      },
    },
  });

  const reminderSent = true;
  const tokensNotified = response.successCount;

  // Prune stale / unregistered tokens
  if (response.failureCount > 0) {
    const invalidTokens = new Set<string>();
    response.responses.forEach((resp, idx) => {
      if (!resp.success && resp.error) {
        const errorCode = resp.error.code;
        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.add(allTokens[idx]);
        }
      }
    });

    if (invalidTokens.size > 0) {
      for (const [uid, tokens] of tokensByUserId.entries()) {
        const validTokens = tokens.filter((t) => !invalidTokens.has(t));
        if (validTokens.length !== tokens.length) {
          await db
            .collection("users")
            .doc(uid)
            .update({ fcmTokens: validTokens });

          const cached = userCache.get(uid);
          if (cached) {
            cached.fcmTokens = validTokens;
          }
        }
      }
    }
  }

  return { reminderSent, tokensNotified };
}

/**
 * Process all active charts and send 9:00 PM reminder notifications if no observations logged.
 */
export async function processDailyReminders(
  db: admin.firestore.Firestore,
  messaging: admin.messaging.Messaging,
  options: {
    now?: Date;
    targetHour?: number;
    forceChartId?: string;
  } = {}
): Promise<{
  chartsChecked: number;
  remindersSent: number;
  tokensNotified: number;
}> {
  const now = options.now ?? new Date();
  const targetHour = options.targetHour ?? 21; // 9:00 PM (21:00)

  let chartsQuery: admin.firestore.Query = db.collection("charts");
  if (options.forceChartId) {
    chartsQuery = db
      .collection("charts")
      .where("id", "==", options.forceChartId);
  }

  const chartsSnap = await chartsQuery.get();
  if (chartsSnap.empty) {
    return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
  }

  const eligibleCharts: Array<{
    chart: ChartData;
    chartId: string;
    dateKey: string;
  }> = [];

  for (const chartDoc of chartsSnap.docs) {
    const chart = chartDoc.data() as ChartData;
    const chartId = chart.id || chartDoc.id;

    // Skip charts that disabled reminders
    if (chart.reminderEnabled === false) {
      continue;
    }

    const timezone = chart.timezone || "America/Los_Angeles";
    const { hour, dateKey } = getLocalTimeInfo(now, timezone);

    // Only process charts that are currently in their 9:00 PM hour (unless forced)
    if (!options.forceChartId && hour !== targetHour) {
      continue;
    }

    eligibleCharts.push({ chart, chartId, dateKey });
  }

  if (eligibleCharts.length === 0) {
    return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
  }

  // Aggregate all unique userIds across all eligible charts
  const distinctUserIds = new Set<string>();
  for (const { chart } of eligibleCharts) {
    const userIds = chart.userIds || [];
    for (const uid of userIds) {
      if (uid) {
        distinctUserIds.add(uid);
      }
    }
  }

  const userCache = new Map<string, UserData>();
  if (distinctUserIds.size > 0) {
    const uids = Array.from(distinctUserIds);
    const CHUNK_SIZE = 500;
    for (let i = 0; i < uids.length; i += CHUNK_SIZE) {
      const chunkUids = uids.slice(i, i + CHUNK_SIZE);
      const userRefs = chunkUids.map((uid) => db.collection("users").doc(uid));
      const userDocs = await db.getAll(...userRefs);
      for (const userDoc of userDocs) {
        if (userDoc.exists) {
          userCache.set(userDoc.id, userDoc.data() as UserData);
        }
      }
    }
  }

  const results = await Promise.all(
    eligibleCharts.map((item) =>
      processSingleChartReminder(db, messaging, item, userCache)
    )
  );

  let remindersSent = 0;
  let tokensNotified = 0;
  for (const result of results) {
    if (result.reminderSent) {
      remindersSent++;
    }
    tokensNotified += result.tokensNotified;
  }

  return {
    chartsChecked: eligibleCharts.length,
    remindersSent,
    tokensNotified,
  };
}
