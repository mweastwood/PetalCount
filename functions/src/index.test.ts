import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { processDailyReminders } from "./reminders";
import {
  checkDailyObservationsAndNotify,
  triggerDailyRemindersManually,
} from "./index";

jest.mock("firebase-admin", () => {
  const mockDb = { id: "mockDb" };
  const mockMsg = { id: "mockMsg" };
  return {
    initializeApp: jest.fn(),
    firestore: jest.fn(() => mockDb),
    messaging: jest.fn(() => mockMsg),
  };
});

jest.mock("firebase-functions/v2/scheduler", () => ({
  onSchedule: jest.fn((_config, handler) => handler),
}));

jest.mock("firebase-functions/v2/https", () => ({
  onRequest: jest.fn((_config, handler) => handler),
}));

jest.mock("firebase-functions/logger", () => ({
  info: jest.fn(),
  error: jest.fn(),
}));

jest.mock("./reminders", () => ({
  processDailyReminders: jest.fn(),
}));

describe("Cloud Function Handlers (functions/src/index.ts)", () => {
  const mockProcessDailyReminders = processDailyReminders as jest.Mock;
  const mockLoggerInfo = logger.info as jest.Mock;
  const mockLoggerError = logger.error as jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("checkDailyObservationsAndNotify (Scheduled Handler)", () => {
    it("executes scheduled job successfully and logs completion metrics", async () => {
      mockProcessDailyReminders.mockResolvedValue({
        chartsChecked: 5,
        remindersSent: 2,
        tokensNotified: 3,
      });

      // Call the scheduled handler
      await (checkDailyObservationsAndNotify as unknown as (event: unknown) => Promise<void>)({});

      expect(mockLoggerInfo).toHaveBeenCalledWith(
        "Executing checkDailyObservationsAndNotify scheduled cron job..."
      );
      expect(mockProcessDailyReminders).toHaveBeenCalledTimes(1);
      expect(mockLoggerInfo).toHaveBeenCalledWith(
        "Completed daily reminder run: 5 charts checked, 2 reminders dispatched, 3 devices notified."
      );
      expect(mockLoggerError).not.toHaveBeenCalled();
    });

    it("catches and logs errors gracefully when reminder processing rejects", async () => {
      const testError = new Error("Firestore unavailable");
      mockProcessDailyReminders.mockRejectedValue(testError);

      await (checkDailyObservationsAndNotify as unknown as (event: unknown) => Promise<void>)({});

      expect(mockLoggerInfo).toHaveBeenCalledWith(
        "Executing checkDailyObservationsAndNotify scheduled cron job..."
      );
      expect(mockProcessDailyReminders).toHaveBeenCalledTimes(1);
      expect(mockLoggerError).toHaveBeenCalledWith(
        "Error executing checkDailyObservationsAndNotify:",
        testError
      );
    });
  });

  describe("triggerDailyRemindersManually (HTTP Handler)", () => {
    let mockReq: any;
    let mockRes: any;
    let mockStatus: jest.Mock;
    let mockJson: jest.Mock;

    beforeEach(() => {
      mockJson = jest.fn();
      mockStatus = jest.fn().mockReturnValue({ json: mockJson });
      mockRes = {
        status: mockStatus,
        json: mockJson,
      };
    });

    it("handles request with chartId and targetHour query parameters and returns 200", async () => {
      mockReq = {
        query: {
          chartId: "chart_abc_123",
          targetHour: "20",
        },
      };

      mockProcessDailyReminders.mockResolvedValue({
        chartsChecked: 1,
        remindersSent: 1,
        tokensNotified: 2,
      });

      await (triggerDailyRemindersManually as unknown as (req: any, res: any) => Promise<void>)(
        mockReq,
        mockRes
      );

      expect(mockProcessDailyReminders).toHaveBeenCalledWith(
        admin.firestore(),
        admin.messaging(),
        {
          forceChartId: "chart_abc_123",
          targetHour: 20,
        }
      );
      expect(mockStatus).toHaveBeenCalledWith(200);
      expect(mockJson).toHaveBeenCalledWith({
        success: true,
        chartsChecked: 1,
        remindersSent: 1,
        tokensNotified: 2,
      });
      expect(mockLoggerError).not.toHaveBeenCalled();
    });

    it("handles request without query parameters and returns 200", async () => {
      mockReq = {
        query: {},
      };

      mockProcessDailyReminders.mockResolvedValue({
        chartsChecked: 3,
        remindersSent: 0,
        tokensNotified: 0,
      });

      await (triggerDailyRemindersManually as unknown as (req: any, res: any) => Promise<void>)(
        mockReq,
        mockRes
      );

      expect(mockProcessDailyReminders).toHaveBeenCalledWith(
        admin.firestore(),
        admin.messaging(),
        {
          forceChartId: undefined,
          targetHour: undefined,
        }
      );
      expect(mockStatus).toHaveBeenCalledWith(200);
      expect(mockJson).toHaveBeenCalledWith({
        success: true,
        chartsChecked: 3,
        remindersSent: 0,
        tokensNotified: 0,
      });
    });

    it("returns HTTP 500 when processDailyReminders throws an Error instance", async () => {
      mockReq = { query: {} };
      const error = new Error("Database connection failed");
      mockProcessDailyReminders.mockRejectedValue(error);

      await (triggerDailyRemindersManually as unknown as (req: any, res: any) => Promise<void>)(
        mockReq,
        mockRes
      );

      expect(mockLoggerError).toHaveBeenCalledWith(
        "Error triggering reminders manually:",
        error
      );
      expect(mockStatus).toHaveBeenCalledWith(500);
      expect(mockJson).toHaveBeenCalledWith({
        success: false,
        error: "Database connection failed",
      });
    });

    it("returns HTTP 500 when processDailyReminders throws a non-Error string rejection", async () => {
      mockReq = { query: {} };
      mockProcessDailyReminders.mockRejectedValue("Unexpected string failure");

      await (triggerDailyRemindersManually as unknown as (req: any, res: any) => Promise<void>)(
        mockReq,
        mockRes
      );

      expect(mockLoggerError).toHaveBeenCalledWith(
        "Error triggering reminders manually:",
        "Unexpected string failure"
      );
      expect(mockStatus).toHaveBeenCalledWith(500);
      expect(mockJson).toHaveBeenCalledWith({
        success: false,
        error: "Unexpected string failure",
      });
    });
  });
});
