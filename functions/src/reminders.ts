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
    // If no cycle starts before dateKey, check any cycle that might have this entry
    const allCyclesSnap = await chartRef.collection("cycles").limit(5).get();
    for (const cycleDoc of allCyclesSnap.docs) {
      const dailyEntryDoc = await cycleDoc.ref
        .collection("dailyEntries")
        .doc(dateKey)
        .get();
      if (dailyEntryDoc.exists) {
        const data = dailyEntryDoc.data() as DailyEntryData;
        if (Array.isArray(data.observations) && data.observations.length > 0) {
          return true;
        }
      }
    }
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
  let chartsChecked = 0;
  let remindersSent = 0;
  let tokensNotified = 0;

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

    chartsChecked++;

    const hasObservation = await checkChartHasObservationForDate(
      db,
      chartId,
      dateKey
    );

    if (hasObservation) {
      // An observation has already been logged for today by user or partner
      continue;
    }

    const userIds = chart.userIds || [];
    if (userIds.length === 0) continue;

    // Collect all FCM tokens for all collaborators on this chart
    const tokensByUserId: Map<string, string[]> = new Map();
    const allTokens: string[] = [];

    for (const uid of userIds) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data() as UserData;
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
      continue;
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

    remindersSent++;
    tokensNotified += response.successCount;

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
          }
        }
      }
    }
  }

  return { chartsChecked, remindersSent, tokensNotified };
}
