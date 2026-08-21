import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { processDailyReminders } from "./reminders";

// Initialize Firebase Admin SDK
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Scheduled Cloud Function that runs every hour at minute 0.
 * It identifies any active charts currently in their 9:00 PM (21:00) local hour,
 * checks if an observation was logged for today across either partner,
 * and sends an FCM push notification if missing.
 */
export const checkDailyObservationsAndNotify = onSchedule(
  {
    schedule: "0 * * * *",
    timeZone: "UTC",
    memory: "256MiB",
    maxInstances: 1,
  },
  async () => {
    logger.info("Executing checkDailyObservationsAndNotify scheduled cron job...");
    try {
      const result = await processDailyReminders(db, messaging);
      logger.info(
        `Completed daily reminder run: ${result.chartsChecked} charts checked, ${result.remindersSent} reminders dispatched, ${result.tokensNotified} devices notified.`
      );
    } catch (error) {
      logger.error("Error executing checkDailyObservationsAndNotify:", error);
    }
  }
);

/**
 * HTTP endpoint for manual invocation / diagnostic testing.
 * Protected with basic checks or chart ID query parameter.
 */
export const triggerDailyRemindersManually = onRequest(
  { memory: "256MiB" },
  async (req, res) => {
    const chartId = req.query.chartId as string | undefined;
    const targetHourStr = req.query.targetHour as string | undefined;
    const targetHour = targetHourStr ? parseInt(targetHourStr, 10) : undefined;

    try {
      const result = await processDailyReminders(db, messaging, {
        forceChartId: chartId,
        targetHour: targetHour,
      });
      res.status(200).json({ success: true, ...result });
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error("Error triggering reminders manually:", error);
      res.status(500).json({ success: false, error: errorMessage });
    }
  }
);
