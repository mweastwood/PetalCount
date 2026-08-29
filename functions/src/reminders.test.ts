import {
  getLocalTimeInfo,
  checkChartHasObservationForDate,
  processDailyReminders,
} from "./reminders";
import * as admin from "firebase-admin";

describe("getLocalTimeInfo", () => {
  it("computes correct hour and dateKey for America/Los_Angeles (PDT / UTC-7)", () => {
    // 2026-08-21 04:30:00 UTC is 2026-08-20 21:30:00 PDT
    const utcDate = new Date(Date.UTC(2026, 7, 21, 4, 30, 0));
    const info = getLocalTimeInfo(utcDate, "America/Los_Angeles");

    expect(info.hour).toBe(21);
    expect(info.dateKey).toBe("2026-08-20");
  });

  it("computes correct hour and dateKey for America/New_York (EDT / UTC-4)", () => {
    // 2026-08-21 01:15:00 UTC is 2026-08-20 21:15:00 EDT
    const utcDate = new Date(Date.UTC(2026, 7, 21, 1, 15, 0));
    const info = getLocalTimeInfo(utcDate, "America/New_York");

    expect(info.hour).toBe(21);
    expect(info.dateKey).toBe("2026-08-20");
  });

  it("falls back gracefully when given an invalid timezone name", () => {
    const utcDate = new Date(Date.UTC(2026, 7, 21, 4, 0, 0));
    const info = getLocalTimeInfo(utcDate, "Invalid/Timezone_Name");

    // Verify structural validity of the fallback result
    expect(typeof info.hour).toBe("number");
    expect(info.hour).toBeGreaterThanOrEqual(0);
    expect(info.hour).toBeLessThan(24);
    expect(info.dateKey).toMatch(/^\d{4}-\d{2}-\d{2}$/);

    // Verify consistency: fallback matches explicit America/Los_Angeles call
    const laInfo = getLocalTimeInfo(utcDate, "America/Los_Angeles");
    expect(info).toEqual(laInfo);
  });
});

describe("checkChartHasObservationForDate", () => {
  it("returns true when an observation exists in the dailyEntries subcollection", async () => {
    const mockDailyDoc = {
      exists: true,
      data: () => ({
        date: "2026-08-20",
        observations: [{ id: "obs_1", sensation: "dry" }],
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockDailyDoc),
          }),
        }),
      },
      data: () => ({}),
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnThis(),
            orderBy: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({
                empty: false,
                docs: [mockCycleDoc],
              }),
            }),
          }),
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const result = await checkChartHasObservationForDate(
      mockDb,
      "chart_123",
      "2026-08-20"
    );
    expect(result).toBe(true);
  });

  it("returns true when eligibleCyclesSnap is empty but allCycles fallback finds observation", async () => {
    const mockDailyDoc = {
      exists: true,
      data: () => ({
        date: "2026-08-20",
        observations: [{ id: "obs_fallback", sensation: "lubricative" }],
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockDailyDoc),
          }),
        }),
      },
      data: () => ({}),
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnThis(),
            orderBy: jest.fn().mockReturnThis(),
            limit: jest.fn().mockImplementation((limitCount: number) => ({
              get: jest.fn().mockImplementation(() => {
                if (limitCount === 1) {
                  return Promise.resolve({ empty: true, docs: [] });
                }
                return Promise.resolve({ empty: false, docs: [mockCycleDoc] });
              }),
            })),
          }),
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const result = await checkChartHasObservationForDate(
      mockDb,
      "chart_fallback",
      "2026-08-20"
    );
    expect(result).toBe(true);
  });

  it("returns true when top-level dailyEntries map on cycle document contains observation", async () => {
    const mockDailyDoc = {
      exists: false,
      data: () => undefined,
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockDailyDoc),
          }),
        }),
      },
      data: () => ({
        dailyEntries: {
          "2026-08-20": {
            observations: [{ id: "obs_map", sensation: "damp" }],
          },
        },
      }),
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnThis(),
            orderBy: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({
                empty: false,
                docs: [mockCycleDoc],
              }),
            }),
          }),
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const result = await checkChartHasObservationForDate(
      mockDb,
      "chart_map",
      "2026-08-20"
    );
    expect(result).toBe(true);
  });

  it("returns false when no observations are recorded for dateKey", async () => {
    const mockDailyDoc = {
      exists: true,
      data: () => ({
        date: "2026-08-20",
        observations: [],
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue(mockDailyDoc),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue({
            where: jest.fn().mockReturnThis(),
            orderBy: jest.fn().mockReturnThis(),
            limit: jest.fn().mockReturnValue({
              get: jest.fn().mockResolvedValue({
                empty: false,
                docs: [mockCycleDoc],
              }),
            }),
          }),
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const result = await checkChartHasObservationForDate(
      mockDb,
      "chart_123",
      "2026-08-20"
    );
    expect(result).toBe(false);
  });
});

describe("processDailyReminders", () => {
  it("dispatches FCM reminders when 9:00 PM and nothing logged today", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0)); // 9:00 PM PDT on Aug 20

    const mockChartDoc = {
      id: "chart_1",
      data: () => ({
        id: "chart_1",
        userIds: ["user_husband", "user_wife"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockUserHusband = {
      id: "user_husband",
      exists: true,
      data: () => ({
        uid: "user_husband",
        fcmTokens: ["token_husband_device_1"],
      }),
    };

    const mockUserWife = {
      id: "user_wife",
      exists: true,
      data: () => ({
        uid: "user_wife",
        fcmTokens: ["token_wife_device_1"],
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const mockDb = {
      collection: jest.fn((colName: string) => {
        if (colName === "charts") {
          return {
            get: jest.fn().mockResolvedValue({
              docs: [mockChartDoc],
            }),
            doc: jest.fn().mockReturnValue({
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    empty: false,
                    docs: [mockCycleDoc],
                  }),
                }),
              }),
            }),
          };
        }
        if (colName === "users") {
          return {
            doc: jest.fn((uid: string) => ({
              id: uid,
              get: jest.fn().mockResolvedValue(
                uid === "user_husband" ? mockUserHusband : mockUserWife
              ),
              update: jest.fn().mockResolvedValue(undefined),
            })),
          };
        }
        return {};
      }),
      getAll: jest.fn().mockImplementation((...refs) =>
        Promise.all(refs.map((r: { get: () => Promise<unknown> }) => r.get()))
      ),
    } as unknown as admin.firestore.Firestore;

    const mockSendEach = jest.fn().mockResolvedValue({
      successCount: 2,
      failureCount: 0,
      responses: [{ success: true }, { success: true }],
    });

    const mockMessaging = {
      sendEachForMulticast: mockSendEach,
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(2);

    expect(mockSendEach).toHaveBeenCalledWith(
      expect.objectContaining({
        tokens: ["token_husband_device_1", "token_wife_device_1"],
        notification: {
          title: "Daily Observation Reminder",
          body: "Don't forget to log your Creighton observations for today!",
        },
      })
    );
  });

  it("processes chart regardless of local hour when forceChartId is provided", async () => {
    // 10:00 AM UTC -> 3:00 AM PDT (hour 3, not targetHour 21)
    const now = new Date(Date.UTC(2026, 7, 21, 10, 0, 0));

    const mockChartDoc = {
      id: "chart_forced",
      data: () => ({
        id: "chart_forced",
        userIds: ["user_1"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockUser1 = {
      id: "user_1",
      exists: true,
      data: () => ({
        uid: "user_1",
        fcmTokens: ["token_1"],
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const whereFn = jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue({
        docs: [mockChartDoc],
      }),
    });

    const mockDb = {
      collection: jest.fn((colName: string) => {
        if (colName === "charts") {
          return {
            where: whereFn,
            doc: jest.fn().mockReturnValue({
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    empty: false,
                    docs: [mockCycleDoc],
                  }),
                }),
              }),
            }),
          };
        }
        if (colName === "users") {
          return {
            doc: jest.fn((uid: string) => ({
              id: uid,
              get: jest.fn().mockResolvedValue(mockUser1),
              update: jest.fn().mockResolvedValue(undefined),
            })),
          };
        }
        return {};
      }),
      getAll: jest.fn().mockImplementation((...refs) =>
        Promise.all(refs.map((r: { get: () => Promise<unknown> }) => r.get()))
      ),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn().mockResolvedValue({
        successCount: 1,
        failureCount: 0,
        responses: [{ success: true }],
      }),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, {
      now,
      forceChartId: "chart_forced",
    });

    expect(whereFn).toHaveBeenCalledWith("id", "==", "chart_forced");
    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(1);
  });

  it("skips chart if reminderEnabled is false", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0));

    const mockChartDoc = {
      id: "chart_disabled",
      data: () => ({
        id: "chart_disabled",
        userIds: ["user_1"],
        reminderEnabled: false,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          docs: [mockChartDoc],
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn(),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(0);
    expect(result.remindersSent).toBe(0);
    expect(mockMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });

  it("skips chart silently when all users have no FCM tokens", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0));

    const mockChartDoc = {
      id: "chart_empty_tokens",
      data: () => ({
        id: "chart_empty_tokens",
        userIds: ["user_no_token", "user_empty_array"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockUserNoTokens = {
      id: "user_no_token",
      exists: true,
      data: () => ({
        uid: "user_no_token",
        fcmTokens: undefined,
      }),
    };

    const mockUserEmptyArray = {
      id: "user_empty_array",
      exists: true,
      data: () => ({
        uid: "user_empty_array",
        fcmTokens: ["", ""], // empty strings get filtered out
      }),
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const mockDb = {
      collection: jest.fn((colName: string) => {
        if (colName === "charts") {
          return {
            get: jest.fn().mockResolvedValue({
              docs: [mockChartDoc],
            }),
            doc: jest.fn().mockReturnValue({
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    empty: false,
                    docs: [mockCycleDoc],
                  }),
                }),
              }),
            }),
          };
        }
        if (colName === "users") {
          return {
            doc: jest.fn((uid: string) => ({
              id: uid,
              get: jest.fn().mockResolvedValue(
                uid === "user_no_token" ? mockUserNoTokens : mockUserEmptyArray
              ),
            })),
          };
        }
        return {};
      }),
      getAll: jest.fn().mockImplementation((...refs) =>
        Promise.all(refs.map((r: { get: () => Promise<unknown> }) => r.get()))
      ),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn(),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(0);
    expect(result.tokensNotified).toBe(0);
    expect(mockMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });

  it("handles non-existent user documents and prunes invalid fcmTokens cleanly", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0));

    const mockChartDoc = {
      id: "chart_with_missing_user",
      data: () => ({
        id: "chart_with_missing_user",
        userIds: ["user_valid", "user_missing"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockValidUser = {
      id: "user_valid",
      exists: true,
      data: () => ({
        uid: "user_valid",
        fcmTokens: ["valid_token_1", "invalid_token_expired", "invalid_token_bad_format"],
      }),
    };

    const mockMissingUser = {
      id: "user_missing",
      exists: false,
      data: () => undefined,
    };

    const mockCycleDoc = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const mockUserUpdate = jest.fn().mockResolvedValue(undefined);

    const mockDb = {
      collection: jest.fn((colName: string) => {
        if (colName === "charts") {
          return {
            get: jest.fn().mockResolvedValue({
              docs: [mockChartDoc],
            }),
            doc: jest.fn().mockReturnValue({
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    empty: false,
                    docs: [mockCycleDoc],
                  }),
                }),
              }),
            }),
          };
        }
        if (colName === "users") {
          return {
            doc: jest.fn((uid: string) => ({
              id: uid,
              get: jest.fn().mockResolvedValue(
                uid === "user_valid" ? mockValidUser : mockMissingUser
              ),
              update: mockUserUpdate,
            })),
          };
        }
        return {};
      }),
      getAll: jest.fn().mockImplementation((...refs) =>
        Promise.all(refs.map((r: { get: () => Promise<unknown> }) => r.get()))
      ),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn().mockResolvedValue({
        successCount: 1,
        failureCount: 2,
        responses: [
          { success: true },
          {
            success: false,
            error: { code: "messaging/registration-token-not-registered" },
          },
          {
            success: false,
            error: { code: "messaging/invalid-registration-token" },
          },
        ],
      }),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(1);
    expect(mockDb.getAll).toHaveBeenCalled();

    // Verifies invalid tokens were pruned and valid token retained
    expect(mockUserUpdate).toHaveBeenCalledWith({
      fcmTokens: ["valid_token_1"],
    });
  });
});
