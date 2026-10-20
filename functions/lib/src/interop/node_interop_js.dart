import 'dart:js' as js;

final Map<String, String?> _testEnvOverrides = {};

void setTestEnvOverride(String name, String? value) {
  _testEnvOverrides[name] = value;
}

void clearTestEnvOverrides() {
  _testEnvOverrides.clear();
}

String? getEnv(String name) {
  if (_testEnvOverrides.containsKey(name)) {
    return _testEnvOverrides[name];
  }
  final process = js.context['process'];
  if (process != null) {
    final env = process['env'];
    if (env != null) {
      return env[name] as String?;
    }
  }
  return null;
}

void exportFunction(String name, dynamic fn) {
  final exports = js.context['exports'];
  if (exports != null) {
    exports[name] = fn;
  }
}

void Function(String message)? onLogInfo;
void Function(String message)? onLogWarn;
void Function(String message, dynamic error)? onLogError;

js.JsObject? _loggerInstance;
js.JsObject get _logger {
  _loggerInstance ??= js.context
      .callMethod('require', ['firebase-functions/logger']) as js.JsObject;
  return _loggerInstance!;
}

void logInfo(String message) {
  onLogInfo?.call(message);
  try {
    _logger.callMethod('info', [message]);
  } catch (_) {
    // ignore: avoid_print
    print('[INFO] $message');
  }
}

void logWarn(String message) {
  onLogWarn?.call(message);
  try {
    _logger.callMethod('warn', [message]);
  } catch (_) {
    // ignore: avoid_print
    print('[WARN] $message');
  }
}

void logError(String message, [dynamic error]) {
  onLogError?.call(message, error);
  try {
    if (error != null) {
      _logger.callMethod('error', [message, error]);
    } else {
      _logger.callMethod('error', [message]);
    }
  } catch (_) {
    // ignore: avoid_print
    print('[ERROR] $message ${error ?? ""}');
  }
}

({int hour, String dateKey}) formatLocalTimeInZone(
  DateTime now,
  String timeZone,
) {
  final intl = js.context['Intl'] as js.JsObject;
  final dateTimeFormatCtor = intl['DateTimeFormat'] as js.JsFunction;
  final jsDate = js.JsObject(js.context['Date'], [now.millisecondsSinceEpoch]);

  final hourFormatter = js.JsObject(dateTimeFormatCtor, [
    'en-US',
    js.JsObject.jsify({
      'hour': 'numeric',
      'hourCycle': 'h23',
      'timeZone': timeZone,
    }),
  ]);
  final hourStr = hourFormatter.callMethod('format', [jsDate]) as String;
  final hour = int.parse(hourStr);

  final dateFormatter = js.JsObject(dateTimeFormatCtor, [
    'en-CA',
    js.JsObject.jsify({
      'year': 'numeric',
      'month': '2-digit',
      'day': '2-digit',
      'timeZone': timeZone,
    }),
  ]);
  final dateKey = dateFormatter.callMethod('format', [jsDate]) as String;

  return (hour: hour, dateKey: dateKey);
}
