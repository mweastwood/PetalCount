import * as admin from "firebase-admin";

export interface NotificationPreferencesData {
  fertilePatternAlerts?: boolean;
  partnerSupportReminders?: boolean;
  dailyLoggingReminder?: boolean;
}

export interface ChartData {
  id?: string;
  userIds?: string[];
  emails?: string[];
  reminderEnabled?: boolean;
  timezone?: string;
  notificationPreferences?: NotificationPreferencesData;
}

export interface UserData {
  uid: string;
  email?: string;
  role?: string;
  fcmTokens?: string[];
  timezone?: string;
}

export interface ObservationData {
  id?: string;
  userId?: string;
  userRole?: string;
}

export interface DailyEntryData {
  date?: string;
  stampType?: string;
  peakDayLabel?: string | null;
  isPeakDay?: boolean;
  observations?: ObservationData[];
}

export interface CycleData {
  id?: string;
  startDate?: string;
  dailyEntries?: Record<string, DailyEntryData>;
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
 * Reads directly from the Cycle document's dailyEntries map, with a fallback
 * to the legacy dailyEntries subcollection only when the cycle document does
 * not contain a dailyEntries map.
 */
export async function checkChartHasObservationForDate(
  db: admin.firestore.Firestore,
  chartId: string,
  dateKey: string
): Promise<boolean> {
  const chartRef = db.collection("charts").doc(chartId);

  // 1. Find the cycle that contains or starts on/before dateKey
  const eligibleCyclesSnapshot = await chartRef
    .collection("cycles")
    .where("startDate", "<=", dateKey)
    .orderBy("startDate", "desc")
    .limit(1)
    .get();

  if (eligibleCyclesSnapshot.empty) {
    return false;
  }

  const targetCycleDoc = eligibleCyclesSnapshot.docs[0];
  const cycleData = targetCycleDoc.data() as CycleData | undefined;

  // Primary source of truth: top-level dailyEntries map on cycle document
  if (cycleData && cycleData.dailyEntries) {
    const entry = cycleData.dailyEntries[dateKey];
    if (entry && Array.isArray(entry.observations) && entry.observations.length > 0) {
      return true;
    }
    return false;
  }

  // Legacy fallback: check dailyEntries subcollection only when dailyEntries map is absent
  if (targetCycleDoc.ref && typeof targetCycleDoc.ref.collection === "function") {
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

  // Collect all unique FCM tokens for all collaborators on this chart
  const tokensByUserId: Map<string, string[]> = new Map();
  const uniqueTokensSet = new Set<string>();

  for (const userId of userIds) {
    const userData = userCache.get(userId);
    if (userData) {
      const tokens = Array.isArray(userData.fcmTokens)
        ? userData.fcmTokens.filter(
            (token) => typeof token === "string" && token.length > 0
          )
        : [];
      if (tokens.length > 0) {
        tokensByUserId.set(userId, tokens);
        for (const token of tokens) {
          uniqueTokensSet.add(token);
        }
      }
    }
  }

  const allTokens = Array.from(uniqueTokensSet);
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

  const tokensNotified = response.successCount;
  const reminderSent = tokensNotified > 0;

  // Prune stale / unregistered tokens atomically
  if (response.failureCount > 0) {
    const invalidTokens = new Set<string>();
    response.responses.forEach((sendResponse, responseIndex) => {
      if (!sendResponse.success && sendResponse.error) {
        const errorCode = sendResponse.error.code;
        if (
          errorCode === "messaging/invalid-registration-token" ||
          errorCode === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.add(allTokens[responseIndex]);
        }
      }
    });

    if (invalidTokens.size > 0) {
      for (const [userId, tokens] of tokensByUserId.entries()) {
        const invalidTokensForUser = tokens.filter((token) =>
          invalidTokens.has(token)
        );
        if (invalidTokensForUser.length > 0) {
          await db
            .collection("users")
            .doc(userId)
            .update({
              fcmTokens: admin.firestore.FieldValue.arrayRemove(
                ...invalidTokensForUser
              ),
            });

          const cached = userCache.get(userId);
          if (cached) {
            cached.fcmTokens = tokens.filter(
              (token) => !invalidTokens.has(token)
            );
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
  const forceChartId =
    typeof options.forceChartId === "string"
      ? options.forceChartId.trim()
      : undefined;

  let chartDocs: admin.firestore.DocumentSnapshot[];
  if (options.forceChartId !== undefined) {
    if (!forceChartId) {
      return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
    }
    const chartDoc = await db
      .collection("charts")
      .doc(forceChartId)
      .get();
    if (!chartDoc.exists) {
      return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
    }
    chartDocs = [chartDoc];
  } else {
    const chartsSnapshot = await db.collection("charts").get();
    if (chartsSnapshot.empty) {
      return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
    }
    chartDocs = chartsSnapshot.docs;
  }

  // Collect distinct primary user IDs needing timezone lookup
  const usersNeedingTimezone = new Set<string>();
  for (const chartDoc of chartDocs) {
    const chart = (chartDoc.data() || {}) as ChartData;
    if ((forceChartId || chart.reminderEnabled !== false) && !chart.timezone) {
      const primaryUserId =
        chart.userIds && chart.userIds.length > 0
          ? chart.userIds[0]
          : undefined;
      if (primaryUserId) {
        usersNeedingTimezone.add(primaryUserId);
      }
    }
  }

  // Batch fetch users in chunks of 500
  const timezoneCache = new Map<string, string>();
  if (usersNeedingTimezone.size > 0) {
    const userIds = Array.from(usersNeedingTimezone);
    const CHUNK_SIZE = 500;
    for (let i = 0; i < userIds.length; i += CHUNK_SIZE) {
      const chunkUserIds = userIds.slice(i, i + CHUNK_SIZE);
      const userRefs = chunkUserIds.map((userId) =>
        db.collection("users").doc(userId)
      );
      try {
        const userDocs = await db.getAll(...userRefs);
        for (const userDoc of userDocs) {
          if (userDoc.exists) {
            const userData = userDoc.data() as UserData;
            if (
              userData &&
              typeof userData.timezone === "string" &&
              userData.timezone.trim().length > 0
            ) {
              timezoneCache.set(userDoc.id, userData.timezone.trim());
            }
          }
        }
      } catch {
        // Graceful fallback if batch fetch fails
      }
    }
  }

  const eligibleCharts: Array<{
    chart: ChartData;
    chartId: string;
    dateKey: string;
  }> = [];

  const backfillPromises: Promise<unknown>[] = [];

  for (const chartDoc of chartDocs) {
    const chart = (chartDoc.data() || {}) as ChartData;
    const chartId = chartDoc.id || chart.id;
    if (!chartId) {
      continue;
    }

    // Skip charts that disabled reminders (unless explicitly forced)
    if (!forceChartId && chart.reminderEnabled === false) {
      continue;
    }

    let timezone = chart.timezone;
    if (!timezone) {
      const primaryUserId =
        chart.userIds && chart.userIds.length > 0
          ? chart.userIds[0]
          : undefined;
      if (primaryUserId && timezoneCache.has(primaryUserId)) {
        timezone = timezoneCache.get(primaryUserId);
        if (chartDoc.ref && typeof chartDoc.ref.set === "function") {
          backfillPromises.push(
            chartDoc.ref.set({ timezone }, { merge: true }).catch(() => {
              // Graceful fallback if individual backfill write fails
            })
          );
        }
      }
    }

    if (!timezone) {
      timezone = "America/Los_Angeles";
    }
    chart.timezone = timezone;
    const { hour, dateKey } = getLocalTimeInfo(now, timezone);

    // Only process charts that are currently in their 9:00 PM hour (unless forced)
    if (!forceChartId && hour !== targetHour) {
      continue;
    }

    eligibleCharts.push({ chart, chartId, dateKey });
  }

  if (backfillPromises.length > 0) {
    await Promise.allSettled(backfillPromises);
  }

  if (eligibleCharts.length === 0) {
    return { chartsChecked: 0, remindersSent: 0, tokensNotified: 0 };
  }

  // Aggregate all unique userIds across all eligible charts
  const distinctUserIds = new Set<string>();
  for (const { chart } of eligibleCharts) {
    const userIds = chart.userIds || [];
    for (const userId of userIds) {
      if (userId) {
        distinctUserIds.add(userId);
      }
    }
  }

  const userCache = new Map<string, UserData>();
  if (distinctUserIds.size > 0) {
    const userIds = Array.from(distinctUserIds);
    const CHUNK_SIZE = 500;
    for (let i = 0; i < userIds.length; i += CHUNK_SIZE) {
      const chunkUserIds = userIds.slice(i, i + CHUNK_SIZE);
      const userRefs = chunkUserIds.map((userId) =>
        db.collection("users").doc(userId)
      );
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

/**
 * Dispatches FCM push notifications to partner/collaborator devices when a new
 * observation is logged on a fertile or Peak-count day.
 */
export async function processCollaboratorFertilityNotification(
  database: admin.firestore.Firestore,
  messaging: admin.messaging.Messaging,
  chartIdentifier: string,
  previousCycleData: CycleData | undefined,
  currentCycleData: CycleData | undefined
): Promise<{ notificationsDispatched: number; tokensNotified: number }> {
  if (!currentCycleData || !currentCycleData.dailyEntries) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  const previousEntries = previousCycleData?.dailyEntries ?? {};
  const currentEntries = currentCycleData.dailyEntries;

  // Find a date entry where a new observation was added
  let modifiedDateKey: string | undefined;
  let modifiedDailyEntry: DailyEntryData | undefined;
  let authorUserIdentifier: string | undefined;

  for (const [dateKey, currentEntry] of Object.entries(currentEntries)) {
    const currentObservations = Array.isArray(currentEntry.observations)
      ? currentEntry.observations
      : [];
    if (currentObservations.length === 0) {
      continue;
    }

    const previousObservations = Array.isArray(
      previousEntries[dateKey]?.observations
    )
      ? previousEntries[dateKey]!.observations!
      : [];

    if (currentObservations.length > previousObservations.length) {
      modifiedDateKey = dateKey;
      modifiedDailyEntry = currentEntry;
      const previousIds = new Set(
        previousObservations
          .map((observation) => observation.id)
          .filter((id): id is string => typeof id === "string")
      );
      const newlyAddedObservation =
        currentObservations.find(
          (observation) => observation.id && !previousIds.has(observation.id)
        ) ?? currentObservations[currentObservations.length - 1];
      authorUserIdentifier = newlyAddedObservation?.userId;
      break;
    }
  }

  if (!modifiedDateKey || !modifiedDailyEntry) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  const stampType = modifiedDailyEntry.stampType ?? "";
  const peakDayLabel = modifiedDailyEntry.peakDayLabel ?? null;
  const isFertileStamp =
    stampType === "whiteBaby" ||
    stampType === "yellowBaby" ||
    stampType === "greenBaby" ||
    stampType === "peak" ||
    stampType === "redFertile";
  const hasPeakLabel =
    typeof peakDayLabel === "string" && peakDayLabel.trim().length > 0;

  if (!isFertileStamp && !hasPeakLabel && !modifiedDailyEntry.isPeakDay) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  const chartSnapshot = await database
    .collection("charts")
    .doc(chartIdentifier)
    .get();
  if (!chartSnapshot.exists) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  const chartData = (chartSnapshot.data() || {}) as ChartData;
  const preferences = chartData.notificationPreferences ?? {};
  const fertilePatternAlertsEnabled =
    preferences.fertilePatternAlerts !== false;
  const partnerSupportRemindersEnabled =
    preferences.partnerSupportReminders !== false;

  if (!fertilePatternAlertsEnabled && !partnerSupportRemindersEnabled) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  const collaboratorUserIdentifiers = (chartData.userIds || []).filter(
    (userIdentifier) =>
      userIdentifier && userIdentifier !== authorUserIdentifier
  );
  if (collaboratorUserIdentifiers.length === 0) {
    return { notificationsDispatched: 0, tokensNotified: 0 };
  }

  let notificationsDispatched = 0;
  let tokensNotified = 0;

  for (const collaboratorIdentifier of collaboratorUserIdentifiers) {
    const userSnapshot = await database
      .collection("users")
      .doc(collaboratorIdentifier)
      .get();
    if (!userSnapshot.exists) {
      continue;
    }

    const userData = (userSnapshot.data() || {}) as UserData;
    const recipientTokens = Array.isArray(userData.fcmTokens)
      ? Array.from(
          new Set(
            userData.fcmTokens.filter(
              (token) => typeof token === "string" && token.length > 0
            )
          )
        )
      : [];
    if (recipientTokens.length === 0) {
      continue;
    }

    const recipientRole =
      userData.role === "husband" ? "husband" : "wife";

    let notificationTitle = "Fertile Pattern Detected";
    let notificationBody =
      recipientRole === "husband"
        ? "Partner alert: Your chart indicates a fertile mucus pattern today."
        : "Your latest observation indicates a fertile mucus pattern today.";

    if (hasPeakLabel && fertilePatternAlertsEnabled) {
      const normalizedPeakLabel = peakDayLabel!.trim();
      notificationTitle =
        normalizedPeakLabel === "P"
          ? "Peak Day Identified"
          : `Peak +${normalizedPeakLabel} Count`;
      notificationBody =
        recipientRole === "husband"
          ? `Partner alert: Today is marked as Peak (${normalizedPeakLabel}) on your shared chart.`
          : `Today is marked as Peak (${normalizedPeakLabel}) on your chart.`;
    } else if (
      !fertilePatternAlertsEnabled &&
      partnerSupportRemindersEnabled
    ) {
      notificationTitle =
        recipientRole === "husband"
          ? "Kindness & Support Reminder"
          : "Self-Care Reminder";
      notificationBody =
        recipientRole === "husband"
          ? "Your chart is in a fertile phase—a thoughtful gesture or word of encouragement goes a long way today!"
          : "You are in a fertile phase—remember to take a moment for rest and self-care today.";
    }

    const multicastResponse = await messaging.sendEachForMulticast({
      tokens: recipientTokens,
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        chartId: chartIdentifier,
        date: modifiedDateKey,
        type: "collaborator_fertility_alert",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "fertility_alerts",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notificationTitle,
              body: notificationBody,
            },
            sound: "default",
          },
        },
      },
    });

    if (multicastResponse.successCount > 0) {
      notificationsDispatched++;
      tokensNotified += multicastResponse.successCount;
    }

    if (multicastResponse.failureCount > 0 && Array.isArray(multicastResponse.responses)) {
      const invalidRecipientTokens: string[] = [];
      multicastResponse.responses.forEach((sendResponse, responseIndex) => {
        if (!sendResponse.success && sendResponse.error) {
          const errorCode = sendResponse.error.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            invalidRecipientTokens.push(recipientTokens[responseIndex]);
          }
        }
      });

      if (invalidRecipientTokens.length > 0) {
        await database
          .collection("users")
          .doc(collaboratorIdentifier)
          .update({
            fcmTokens: admin.firestore.FieldValue.arrayRemove(
              ...invalidRecipientTokens
            ),
          });
      }
    }
  }

  return { notificationsDispatched, tokensNotified };
}

