# PetalCount Cloud Functions (Dart)

This directory contains Firebase Cloud Functions (v2) for **PetalCount**, written in Dart and compiled to JavaScript via `dart compile js`. It shares domain models, fertility stamp classification, and notification formatting with the Flutter app via `package:core` (`../core`).

## Scripts

- `npm run build`: Compiles the Dart entrypoint (`bin/index.dart`) to a JavaScript bundle via `dart compile js` and injects the Node.js preamble into `lib/index.js`.
- `npm run watch`: Fast development compile (`-O1`) of the Dart entrypoint to JavaScript.
- `npm test`: Runs the Dart unit test suite (`dart test`) and the compiled Node.js bundle interop test (`npm run test:interop`).
- `npm run serve`: Builds the bundle and launches the local Firebase Functions emulator.

## Exported Cloud Functions

- `checkDailyObservationsAndNotify`: Scheduled hourly cron job (`0 * * * *` UTC) that identifies active charts in their 9:00 PM local hour and sends an FCM reminder if no observation was logged for today.
- `triggerDailyRemindersManually`: Authenticated HTTP endpoint for manual invocation and diagnostic testing.
- `onCycleWriteNotifyCollaborators`: Firestore `onDocumentWritten("charts/{chartId}/cycles/{cycleId}")` trigger that sends FCM push notifications to partner/collaborator devices when a fertile or Peak observation is logged.
