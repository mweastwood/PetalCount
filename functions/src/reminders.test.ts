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

  it("returns false immediately when eligibleCyclesSnap is empty without querying allCycles fallback", async () => {
    const mockLimit = jest.fn().mockReturnValue({
      get: jest.fn().mockResolvedValue({ empty: true, docs: [] }),
    });

    const mockCyclesCollection = {
      where: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      limit: mockLimit,
    };

    const mockDb = {
      collection: jest.fn().mockReturnValue({
        doc: jest.fn().mockReturnValue({
          collection: jest.fn().mockReturnValue(mockCyclesCollection),
        }),
      }),
    } as unknown as admin.firestore.Firestore;

    const result = await checkChartHasObservationForDate(
      mockDb,
      "chart_fallback",
      "2026-08-20"
    );
    expect(result).toBe(false);
    expect(mockLimit).toHaveBeenCalledTimes(1);
    expect(mockLimit).toHaveBeenCalledWith(1);
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

  it("returns early with zeroes when charts collection is empty without calling getAll", async () => {
    const mockDb = {
      collection: jest.fn().mockReturnValue({
        get: jest.fn().mockResolvedValue({
          empty: true,
          docs: [],
        }),
      }),
      getAll: jest.fn(),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn(),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging);

    expect(result).toEqual({
      chartsChecked: 0,
      remindersSent: 0,
      tokensNotified: 0,
    });
    expect(mockDb.getAll).not.toHaveBeenCalled();
    expect(mockMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });

  it("processes multiple eligible charts concurrently with deduplicated batch user fetch and aggregates metrics", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0)); // 9:00 PM PDT on Aug 20

    const mockChartDoc1 = {
      id: "chart_1",
      data: () => ({
        id: "chart_1",
        userIds: ["user_shared", "user_1"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockChartDoc2 = {
      id: "chart_2",
      data: () => ({
        id: "chart_2",
        userIds: ["user_shared", "user_2"],
        reminderEnabled: true,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockUserShared = {
      id: "user_shared",
      exists: true,
      data: () => ({
        uid: "user_shared",
        fcmTokens: ["token_shared_1"],
      }),
    };

    const mockUser1 = {
      id: "user_1",
      exists: true,
      data: () => ({
        uid: "user_1",
        fcmTokens: ["token_user1_1"],
      }),
    };

    const mockUser2 = {
      id: "user_2",
      exists: true,
      data: () => ({
        uid: "user_2",
        fcmTokens: ["token_user2_1"],
      }),
    };

    // Chart 1 has no observation logged; Chart 2 has an observation logged
    const mockCycleDocWithoutObs = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({ exists: false }),
          }),
        }),
      },
      data: () => ({ dailyEntries: {} }),
    };

    const mockCycleDocWithObs = {
      ref: {
        collection: jest.fn().mockReturnValue({
          doc: jest.fn().mockReturnValue({
            get: jest.fn().mockResolvedValue({
              exists: true,
              data: () => ({
                observations: [{ id: "obs_today" }],
              }),
            }),
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
              docs: [mockChartDoc1, mockChartDoc2],
            }),
            doc: jest.fn((chartId: string) => ({
              collection: jest.fn().mockReturnValue({
                where: jest.fn().mockReturnThis(),
                orderBy: jest.fn().mockReturnThis(),
                limit: jest.fn().mockReturnValue({
                  get: jest.fn().mockResolvedValue({
                    empty: false,
                    docs: [
                      chartId === "chart_1"
                        ? mockCycleDocWithoutObs
                        : mockCycleDocWithObs,
                    ],
                  }),
                }),
              }),
            })),
          };
        }
        if (colName === "users") {
          return {
            doc: jest.fn((uid: string) => ({
              id: uid,
              get: jest.fn().mockResolvedValue(
                uid === "user_shared"
                  ? mockUserShared
                  : uid === "user_1"
                  ? mockUser1
                  : mockUser2
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

    const mockMessaging = {
      sendEachForMulticast: jest.fn().mockResolvedValue({
        successCount: 2,
        failureCount: 0,
        responses: [{ success: true }, { success: true }],
      }),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(2);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(2);

    // Verify deduplicated batch fetch across all eligible charts: exactly 1 getAll call with 3 user refs
    expect(mockDb.getAll).toHaveBeenCalledTimes(1);
    const getAllArgs = (mockDb.getAll as jest.Mock).mock.calls[0];
    expect(getAllArgs).toHaveLength(3);
    const fetchedUserIds = getAllArgs.map((ref: { id: string }) => ref.id).sort();
    expect(fetchedUserIds).toEqual(["user_1", "user_2", "user_shared"].sort());

    // Verify only Chart 1 sent notifications
    expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledTimes(1);
    expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        tokens: ["token_shared_1", "token_user1_1"],
        data: expect.objectContaining({ chartId: "chart_1" }),
      })
    );
  });

  it("ignores non-eligible charts without fetching user docs or checking observations", async () => {
    const now = new Date(Date.UTC(2026, 7, 21, 4, 0, 0)); // 9:00 PM PDT on Aug 20

    const mockDisabledChart = {
      id: "chart_disabled",
      data: () => ({
        id: "chart_disabled",
        userIds: ["user_disabled"],
        reminderEnabled: false,
        timezone: "America/Los_Angeles",
      }),
    };

    const mockWrongHourChart = {
      id: "chart_wrong_hour",
      data: () => ({
        id: "chart_wrong_hour",
        userIds: ["user_wrong_hour"],
        reminderEnabled: true,
        timezone: "Europe/London", // 5:00 AM local time, not 21:00
      }),
    };

    const mockDb = {
      collection: jest.fn((colName: string) => {
        if (colName === "charts") {
          return {
            get: jest.fn().mockResolvedValue({
              docs: [mockDisabledChart, mockWrongHourChart],
            }),
            doc: jest.fn(),
          };
        }
        return {};
      }),
      getAll: jest.fn(),
    } as unknown as admin.firestore.Firestore;

    const mockMessaging = {
      sendEachForMulticast: jest.fn(),
    } as unknown as admin.messaging.Messaging;

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result).toEqual({
      chartsChecked: 0,
      remindersSent: 0,
      tokensNotified: 0,
    });
    expect(mockDb.getAll).not.toHaveBeenCalled();
    expect(mockMessaging.sendEachForMulticast).not.toHaveBeenCalled();
  });

  it("respects explicit chart.timezone for non-Pacific timezones (e.g. America/New_York at 21:00 EDT)", async () => {
    // 2026-08-21 01:00:00 UTC is 2026-08-20 21:00:00 EDT (and 18:00:00 PDT)
    const now = new Date(Date.UTC(2026, 7, 21, 1, 0, 0));

    const mockChartDoc = {
      id: "chart_ny",
      data: () => ({
        id: "chart_ny",
        userIds: ["user_ny"],
        reminderEnabled: true,
        timezone: "America/New_York",
      }),
    };

    const mockUserNY = {
      id: "user_ny",
      exists: true,
      data: () => ({
        uid: "user_ny",
        timezone: "America/New_York",
        fcmTokens: ["token_ny_1"],
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
              get: jest.fn().mockResolvedValue(mockUserNY),
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

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(1);
    expect(mockMessaging.sendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        tokens: ["token_ny_1"],
        data: expect.objectContaining({
          date: "2026-08-20",
        }),
      })
    );
  });

  it("falls back to userData.timezone when chart.timezone is undefined and backfills the chart doc", async () => {
    // 2026-08-21 01:00:00 UTC is 2026-08-20 21:00:00 EDT
    const now = new Date(Date.UTC(2026, 7, 21, 1, 0, 0));

    const mockBackfillSet = jest.fn().mockResolvedValue(undefined);
    const mockChartDoc = {
      id: "chart_needs_backfill",
      ref: {
        set: mockBackfillSet,
      },
      data: () => ({
        id: "chart_needs_backfill",
        userIds: ["user_owner"],
        reminderEnabled: true,
        // timezone intentionally undefined
      }),
    };

    const mockUserOwner = {
      id: "user_owner",
      exists: true,
      data: () => ({
        uid: "user_owner",
        timezone: "America/New_York",
        fcmTokens: ["token_owner_1"],
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
              get: jest.fn().mockResolvedValue(mockUserOwner),
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

    const result = await processDailyReminders(mockDb, mockMessaging, { now });

    // Assert that backfill occurred on the chart doc ref
    expect(mockBackfillSet).toHaveBeenCalledWith(
      { timezone: "America/New_York" },
      { merge: true }
    );
    expect(result.chartsChecked).toBe(1);
    expect(result.remindersSent).toBe(1);
    expect(result.tokensNotified).toBe(1);
  });

  it("falls back to default America/Los_Angeles when both chart.timezone and user timezone are absent", async () => {
    // 2026-08-21 01:00:00 UTC is 18:00 PDT (not 21:00)
    const nowNot9PM = new Date(Date.UTC(2026, 7, 21, 1, 0, 0));
    // 2026-08-21 04:00:00 UTC is 21:00 PDT
    const now9PMPacific = new Date(Date.UTC(2026, 7, 21, 4, 0, 0));

    const mockChartDoc = {
      id: "chart_no_tz",
      ref: {
        set: jest.fn().mockResolvedValue(undefined),
      },
      data: () => ({
        id: "chart_no_tz",
        userIds: ["user_no_tz"],
        reminderEnabled: true,
      }),
    };

    const mockUserNoTz = {
      id: "user_no_tz",
      exists: true,
      data: () => ({
        uid: "user_no_tz",
        // timezone absent
        fcmTokens: ["token_no_tz_1"],
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
              get: jest.fn().mockResolvedValue(mockUserNoTz),
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

    // At 18:00 PDT, Pacific chart should NOT be checked
    const resultNot9PM = await processDailyReminders(mockDb, mockMessaging, {
      now: nowNot9PM,
    });
    expect(resultNot9PM.chartsChecked).toBe(0);
    expect(resultNot9PM.remindersSent).toBe(0);

    // At 21:00 PDT, Pacific fallback triggers processing
    const result9PM = await processDailyReminders(mockDb, mockMessaging, {
      now: now9PMPacific,
    });
    expect(result9PM.chartsChecked).toBe(1);
    expect(result9PM.remindersSent).toBe(1);
  });
});
