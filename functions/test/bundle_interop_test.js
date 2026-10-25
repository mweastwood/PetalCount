/**
 * Integration / Interop Test for the compiled Dart-to-JS bundle (`lib/index.js`).
 *
 * This script loads the compiled JavaScript output (`lib/index.js`) in Node.js,
 * intercepts the `firebase-admin` and `firebase-functions` modules, and invokes
 * all exported Cloud Functions (`checkDailyObservationsAndNotify`,
 * `triggerDailyRemindersManually`, `onCycleWriteNotifyCollaborators`) and
 * direct helpers (`getLocalTimeInfo`, `checkChartHasObservationForDate`,
 * `processDailyReminders`, `processCollaboratorFertilityNotification`,
 * `getFirebaseAdminDb`) to verify:
 * 1. `JsObject` unwrapping works across `dart2js` boundaries (`promiseToFuture`).
 * 2. Firestore `getAll(...refs)`, `set(data, { merge: true })`, `FieldValue.arrayRemove(...)`,
 *    and `where().orderBy().limit().get()` chains execute properly.
 * 3. `messaging.sendEachForMulticast` dispatches and parses `BatchResponse` accurately.
 */

const assert = require('assert');
const Module = require('module');

let currentMockDb = null;
let currentMockMessaging = null;
let verifyTokenBehavior = async (token) => ({ uid: 'user_123', email: 'test@example.com' });
let getFirestoreShouldFail = false;

const defaultMockDb = {
  id: 'default_mock_firestore_db',
  collection: (path) => ({
    doc: (id) => ({
      id: id || 'default_doc',
      get: () => Promise.resolve({ id: id || 'default_doc', exists: false, data: () => null }),
      set: () => Promise.resolve(),
      update: () => Promise.resolve(),
      delete: () => Promise.resolve(),
      collection: () => ({
        where: function () { return this; },
        orderBy: function () { return this; },
        limit: function () { return this; },
        get: () => Promise.resolve({ empty: true, size: 0, docs: [] }),
      }),
    }),
    where: function () { return this; },
    orderBy: function () { return this; },
    limit: function () { return this; },
    get: () => Promise.resolve({ empty: true, size: 0, docs: [] }),
  }),
  getAll: (...refs) => Promise.all(refs.map((r) => r.get())),
};

const defaultMockMessaging = {
  id: 'default_mock_messaging',
  sendEachForMulticast: async (msg) => ({
    successCount: (msg.tokens || []).length,
    failureCount: 0,
    responses: (msg.tokens || []).map(() => ({ success: true })),
  }),
};

const mockFieldValue = {
  delete: () => ({ __fieldValue: 'delete' }),
  arrayRemove: (...elements) => ({ __fieldValue: 'arrayRemove', elements }),
};

const mockTimestamp = {
  fromMillis: (ms) => ({ __timestampMillis: ms, toMillis: () => ms }),
};

const mockAdmin = {
  apps: [],
  getApps: function () { return this.apps; },
  initializeApp: function () {
    const app = { name: '[DEFAULT]' };
    this.apps.push(app);
    return app;
  },
  getFirestore: () => {
    if (getFirestoreShouldFail) throw new Error('Simulated getFirestore failure');
    return currentMockDb || defaultMockDb;
  },
  firestore: Object.assign(
    () => currentMockDb || defaultMockDb,
    { FieldValue: mockFieldValue, Timestamp: mockTimestamp }
  ),
  FieldValue: mockFieldValue,
  Timestamp: mockTimestamp,
  getAuth: () => ({
    verifyIdToken: (token) => verifyTokenBehavior(token),
  }),
  auth: () => ({
    verifyIdToken: (token) => verifyTokenBehavior(token),
  }),
  getMessaging: () => currentMockMessaging || defaultMockMessaging,
  messaging: () => currentMockMessaging || defaultMockMessaging,
};

const originalRequire = Module.prototype.require;
Module.prototype.require = function (id) {
  if (
    id === 'firebase-admin' ||
    id === 'firebase-admin/app' ||
    id === 'firebase-admin/firestore' ||
    id === 'firebase-admin/auth' ||
    id === 'firebase-admin/messaging'
  ) {
    return mockAdmin;
  }
  if (id === 'firebase-functions/v2/https') {
    return {
      onRequest: (opts, handler) => {
        const fn = (req, res) => handler(req, res);
        fn.__opts = opts;
        return fn;
      },
    };
  }
  if (id === 'firebase-functions/v2/scheduler') {
    return {
      onSchedule: (opts, handler) => {
        const fn = (event) => handler(event);
        fn.__opts = opts;
        return fn;
      },
    };
  }
  if (id === 'firebase-functions/v2/firestore') {
    return {
      onDocumentWritten: (docPath, handler) => {
        const fn = (event) => handler(event);
        fn.__docPath = docPath;
        return fn;
      },
    };
  }
  if (id === 'firebase-functions/logger') {
    return {
      info: () => {},
      warn: () => {},
      error: () => {},
    };
  }
  return originalRequire.apply(this, arguments);
};

const bundle = require('../lib/index.js');

function createMockRes() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(data) {
      this.body = data;
      return this;
    },
    send(data) {
      this.body = data;
      return this;
    },
  };
}

async function runTests() {
  console.log('Running compiled JS bundle interop tests for PetalCount functions...');

  // 1. Verify all expected Cloud Functions & direct helpers are exported
  assert.strictEqual(typeof bundle.checkDailyObservationsAndNotify, 'function');
  assert.strictEqual(typeof bundle.triggerDailyRemindersManually, 'function');
  assert.strictEqual(typeof bundle.onCycleWriteNotifyCollaborators, 'function');
  assert.strictEqual(typeof bundle.getLocalTimeInfo, 'function');
  assert.strictEqual(typeof bundle.checkChartHasObservationForDate, 'function');
  assert.strictEqual(typeof bundle.processDailyReminders, 'function');
  assert.strictEqual(typeof bundle.processCollaboratorFertilityNotification, 'function');
  assert.strictEqual(typeof bundle.getFirebaseAdminDb, 'function');
  console.log('  ✓ All Cloud Functions and direct test helpers are exported');

  // 2. Test getLocalTimeInfo via compiled JS bundle (uses Node V8 Intl.DateTimeFormat)
  {
    const utcDate = new Date(Date.UTC(2026, 7, 21, 4, 30, 0)); // 2026-08-20 21:30 PDT
    const laInfo = bundle.getLocalTimeInfo(utcDate, 'America/Los_Angeles');
    assert.strictEqual(laInfo.hour, 21);
    assert.strictEqual(laInfo.dateKey, '2026-08-20');

    const nyDate = new Date(Date.UTC(2026, 7, 21, 1, 15, 0)); // 2026-08-20 21:15 EDT
    const nyInfo = bundle.getLocalTimeInfo(nyDate, 'America/New_York');
    assert.strictEqual(nyInfo.hour, 21);
    assert.strictEqual(nyInfo.dateKey, '2026-08-20');

    const invalidInfo = bundle.getLocalTimeInfo(utcDate, 'Invalid/Zone_Name');
    assert.strictEqual(invalidInfo.hour, laInfo.hour);
    assert.strictEqual(invalidInfo.dateKey, laInfo.dateKey);
    console.log('  ✓ getLocalTimeInfo works accurately via JS Intl.DateTimeFormat');
  }

  // 3. Test checkChartHasObservationForDate (dailyEntries map and subcollection fallback)
  {
    const mockDbWithMap = {
      collection: () => ({
        doc: () => ({
          collection: () => ({
            where: function () { return this; },
            orderBy: function () { return this; },
            limit: function () {
              return {
                get: () =>
                  Promise.resolve({
                    empty: false,
                    docs: [
                      {
                        data: () => ({
                          dailyEntries: {
                            '2026-08-20': {
                              observations: [{ id: 'obs_1' }],
                            },
                          },
                        }),
                      },
                    ],
                  }),
              };
            },
          }),
        }),
      }),
    };
    const hasObs = await bundle.checkChartHasObservationForDate(
      mockDbWithMap,
      'chart_1',
      '2026-08-20'
    );
    assert.strictEqual(hasObs, true);
    console.log('  ✓ checkChartHasObservationForDate resolves Promise across JS-Dart boundary');
  }

  // 4. Test processDailyReminders (with timezone backfill via set(..., {merge: true}), db.getAll, and FieldValue.arrayRemove)
  {
    const backfillSetCalls = [];
    const userUpdateCalls = [];
    const getAllBatches = [];

    const mockChartDoc = {
      id: 'chart_backfill_1',
      exists: true,
      ref: {
        id: 'chart_backfill_1',
        set: (data, opts) => {
          backfillSetCalls.push({ data, opts });
          return Promise.resolve();
        },
      },
      data: () => ({
        id: 'chart_backfill_1',
        userIds: ['user_1'],
        reminderEnabled: true,
      }),
    };

    const mockUserDoc = {
      id: 'user_1',
      exists: true,
      data: () => ({
        uid: 'user_1',
        timezone: 'America/New_York',
        fcmTokens: ['valid_tok', 'stale_tok'],
      }),
    };

    const mockCycleDoc = {
      data: () => ({ dailyEntries: {} }),
    };

    const mockDb = {
      collection: (colName) => {
        if (colName === 'charts') {
          return {
            get: () => Promise.resolve({ empty: false, docs: [mockChartDoc] }),
            doc: () => ({
              collection: () => ({
                where: function () { return this; },
                orderBy: function () { return this; },
                limit: () => ({
                  get: () => Promise.resolve({ empty: false, docs: [mockCycleDoc] }),
                }),
              }),
            }),
          };
        }
        if (colName === 'users') {
          return {
            doc: (uid) => ({
              id: uid,
              get: () => Promise.resolve(mockUserDoc),
              update: (data) => {
                userUpdateCalls.push(data);
                return Promise.resolve();
              },
            }),
          };
        }
        return {};
      },
      getAll: (...refs) => {
        getAllBatches.push(refs);
        return Promise.all(refs.map((r) => r.get()));
      },
    };

    const mockMessaging = {
      sendEachForMulticast: async () => ({
        successCount: 1,
        failureCount: 1,
        responses: [
          { success: true },
          {
            success: false,
            error: { code: 'messaging/registration-token-not-registered' },
          },
        ],
      }),
    };

    // 2026-08-21 01:00 UTC is 21:00 EDT in America/New_York
    const now = new Date(Date.UTC(2026, 7, 21, 1, 0, 0));
    const result = await bundle.processDailyReminders(mockDb, mockMessaging, { now });

    assert.strictEqual(result.chartsChecked, 1);
    assert.strictEqual(result.remindersSent, 1);
    assert.strictEqual(result.tokensNotified, 1);
    assert.strictEqual(getAllBatches.length, 2);
    assert.strictEqual(backfillSetCalls.length, 1);
    assert.deepStrictEqual(backfillSetCalls[0].data, { timezone: 'America/New_York' });
    assert.deepStrictEqual(backfillSetCalls[0].opts, { merge: true });
    assert.strictEqual(userUpdateCalls.length, 1);
    assert.deepStrictEqual(userUpdateCalls[0].fcmTokens, {
      __fieldValue: 'arrayRemove',
      elements: ['stale_tok'],
    });
    console.log('  ✓ processDailyReminders handles getAll, set({merge: true}), and FieldValue.arrayRemove');
  }

  // 5. Test triggerDailyRemindersManually HTTP handler (auth + query params)
  {
    process.env.NODE_ENV = 'production';
    delete process.env.FUNCTIONS_EMULATOR;
    process.env.REMINDER_TRIGGER_SECRET = 'secret_123';

    // Unauthorized request -> 401
    const unauthRes = createMockRes();
    await bundle.triggerDailyRemindersManually({ headers: {}, query: {} }, unauthRes);
    assert.strictEqual(unauthRes.statusCode, 401);
    assert.strictEqual(unauthRes.body.success, false);

    // Authorized with x-admin-secret -> 200
    currentMockDb = defaultMockDb;
    currentMockMessaging = defaultMockMessaging;
    const authRes = createMockRes();
    await bundle.triggerDailyRemindersManually(
      {
        headers: { 'x-admin-secret': 'secret_123' },
        query: { chartId: 'nonexistent_chart', targetHour: '21' },
      },
      authRes
    );
    assert.strictEqual(authRes.statusCode, 200);
    assert.strictEqual(authRes.body.success, true);
    assert.strictEqual(authRes.body.chartsChecked, 0);
    console.log('  ✓ triggerDailyRemindersManually enforces auth and returns 200/401');
  }

  // 6. Test onCycleWriteNotifyCollaborators Firestore trigger
  {
    const sentMulticasts = [];
    currentMockDb = {
      collection: (colName) => {
        if (colName === 'charts') {
          return {
            doc: () => ({
              get: () =>
                Promise.resolve({
                  exists: true,
                  data: () => ({
                    id: 'chart_collab',
                    userIds: ['user_wife', 'user_husband'],
                    notificationPreferences: {
                      fertilePatternAlerts: true,
                      partnerSupportReminders: true,
                    },
                  }),
                }),
            }),
          };
        }
        if (colName === 'users') {
          return {
            doc: (uid) => ({
              id: uid,
              get: () =>
                Promise.resolve({
                  id: uid,
                  exists: true,
                  data: () => ({
                    uid: 'user_husband',
                    role: 'husband',
                    fcmTokens: ['husband_tok_1'],
                  }),
                }),
              update: () => Promise.resolve(),
            }),
          };
        }
        return {};
      },
      getAll: (...refs) => Promise.all(refs.map((r) => r.get())),
    };
    currentMockMessaging = {
      sendEachForMulticast: async (msg) => {
        sentMulticasts.push(msg);
        return {
          successCount: 1,
          failureCount: 0,
          responses: [{ success: true }],
        };
      },
    };

    await bundle.onCycleWriteNotifyCollaborators({
      params: { chartId: 'chart_collab', cycleId: 'cycle_1' },
      data: {
        before: {
          exists: true,
          data: () => ({ id: 'cycle_1', dailyEntries: {} }),
        },
        after: {
          exists: true,
          data: () => ({
            id: 'cycle_1',
            dailyEntries: {
              '2026-06-15': {
                date: '2026-06-15',
                stampType: 'WhiteBaby',
                peakDayLabel: 'P',
                observations: [{ id: 'obs_1', userId: 'user_wife' }],
              },
            },
          }),
        },
      },
    });

    assert.strictEqual(sentMulticasts.length, 1);
    assert.strictEqual(sentMulticasts[0].notification.title, 'Peak Day Identified');
    assert.strictEqual(
      sentMulticasts[0].notification.body,
      'Partner alert: Today is marked as Peak (P) on your shared chart.'
    );
    console.log('  ✓ onCycleWriteNotifyCollaborators processes Firestore event and sends FCM push');
  }

  // 7. Test checkDailyObservationsAndNotify scheduled trigger
  {
    currentMockDb = defaultMockDb;
    currentMockMessaging = defaultMockMessaging;
    await bundle.checkDailyObservationsAndNotify({});
    console.log('  ✓ checkDailyObservationsAndNotify scheduled handler executes cleanly');
  }

  // 8. Test getFirebaseAdminDb fallback when getFirestore throws
  {
    getFirestoreShouldFail = true;
    currentMockDb = defaultMockDb;
    const rawDb = bundle.getFirebaseAdminDb();
    assert.strictEqual(rawDb.id, 'default_mock_firestore_db');
    getFirestoreShouldFail = false;
    console.log('  ✓ getFirebaseAdminDb initializes and returns Firestore instance');
  }

  console.log('All PetalCount bundle interop tests passed!');
}

runTests().catch((err) => {
  console.error('Bundle interop test failed:', err);
  process.exit(1);
});
