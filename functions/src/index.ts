import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {
  CycleData,
  processCollaboratorFertilityNotification,
  processDailyReminders,
} from "./reminders";

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
    logger.info(
      "Executing checkDailyObservationsAndNotify scheduled cron job..."
    );
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
 * Requires a valid Firebase ID token or admin secret outside test/emulator environments.
 */
export const triggerDailyRemindersManually = onRequest(
  { memory: "256MiB" },
  async (req, res) => {
    const isTestOrEmulator =
      process.env.NODE_ENV === "test" ||
      process.env.FUNCTIONS_EMULATOR === "true";

    if (!isTestOrEmulator) {
      const authorizationHeader =
        typeof req.headers?.authorization === "string"
          ? req.headers.authorization
          : "";
      const adminSecretHeader =
        typeof req.headers?.["x-admin-secret"] === "string"
          ? req.headers["x-admin-secret"]
          : "";
      const configuredSecret = process.env.REMINDER_TRIGGER_SECRET || "";

      let isAuthorized =
        configuredSecret.length > 0 && adminSecretHeader === configuredSecret;

      if (!isAuthorized && authorizationHeader.startsWith("Bearer ")) {
        const idToken = authorizationHeader.substring("Bearer ".length).trim();
        try {
          await admin.auth().verifyIdToken(idToken);
          isAuthorized = true;
        } catch {
          isAuthorized = false;
        }
      }

      if (!isAuthorized) {
        res.status(401).json({
          success: false,
          error: "Unauthorized request",
        });
        return;
      }
    }

    const chartId = req.query.chartId as string | undefined;
    const targetHourStr = req.query.targetHour as string | undefined;
    const parsedTargetHour = targetHourStr
      ? parseInt(targetHourStr, 10)
      : undefined;
    const targetHour =
      parsedTargetHour !== undefined && !Number.isNaN(parsedTargetHour)
        ? parsedTargetHour
        : undefined;

    try {
      const result = await processDailyReminders(db, messaging, {
        forceChartId: chartId,
        targetHour: targetHour,
      });
      res.status(200).json({ success: true, ...result });
    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      logger.error("Error triggering reminders manually:", error);
      res.status(500).json({ success: false, error: errorMessage });
    }
  }
);

/**
 * Firestore document write trigger that notifies partner/collaborator devices
 * via FCM push notification when a fertile or Peak observation is logged.
 */
export const onCycleWriteNotifyCollaborators = onDocumentWritten(
  "charts/{chartId}/cycles/{cycleId}",
  async (event) => {
    const chartId = event.params?.chartId;
    if (!chartId || !event.data) {
      return;
    }

    const previousCycleData = event.data.before.exists
      ? (event.data.before.data() as CycleData)
      : undefined;
    const currentCycleData = event.data.after.exists
      ? (event.data.after.data() as CycleData)
      : undefined;

    try {
      await processCollaboratorFertilityNotification(
        db,
        messaging,
        chartId,
        previousCycleData,
        currentCycleData
      );
    } catch (error) {
      logger.error("Error in onCycleWriteNotifyCollaborators:", error);
    }
  }
);
