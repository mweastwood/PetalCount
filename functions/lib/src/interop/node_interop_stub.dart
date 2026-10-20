import 'dart:io';

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
  return Platform.environment[name];
}

void exportFunction(String name, dynamic fn) {
  // No-op on VM stub
}

void Function(String message)? onLogInfo;
void Function(String message)? onLogWarn;
void Function(String message, dynamic error)? onLogError;

void logInfo(String message) {
  onLogInfo?.call(message);
  // ignore: avoid_print
  print('[INFO] $message');
}

void logWarn(String message) {
  onLogWarn?.call(message);
  // ignore: avoid_print
  print('[WARN] $message');
}

void logError(String message, [dynamic error]) {
  onLogError?.call(message, error);
  // ignore: avoid_print
  print('[ERROR] $message ${error ?? ""}');
}

bool _isUsDst(DateTime utc, int standardOffsetHours) {
  // US DST starts on the second Sunday in March at 02:00 local standard time
  // and ends on the first Sunday in November at 02:00 local daylight time.
  final year = utc.year;
  final march1 = DateTime.utc(year, 3, 1);
  final daysUntilFirstSunMarch = (DateTime.sunday - march1.weekday) % 7;
  final secondSundayMarchDay = 1 + daysUntilFirstSunMarch + 7;
  final dstStartUtc = DateTime.utc(
    year,
    3,
    secondSundayMarchDay,
    2 - standardOffsetHours,
  );

  final nov1 = DateTime.utc(year, 11, 1);
  final daysUntilFirstSunNov = (DateTime.sunday - nov1.weekday) % 7;
  final firstSundayNovDay = 1 + daysUntilFirstSunNov;
  final dstEndUtc = DateTime.utc(
    year,
    11,
    firstSundayNovDay,
    2 - (standardOffsetHours + 1),
  );

  return !utc.isBefore(dstStartUtc) && utc.isBefore(dstEndUtc);
}

bool _isEuDst(DateTime utc) {
  // EU/UK DST starts on the last Sunday of March at 01:00 UTC
  // and ends on the last Sunday of October at 01:00 UTC.
  final year = utc.year;
  final march31 = DateTime.utc(year, 3, 31);
  final lastSundayMarchDay = 31 - (march31.weekday % 7);
  final dstStartUtc = DateTime.utc(year, 3, lastSundayMarchDay, 1);

  final oct31 = DateTime.utc(year, 10, 31);
  final lastSundayOctDay = 31 - (oct31.weekday % 7);
  final dstEndUtc = DateTime.utc(year, 10, lastSundayOctDay, 1);

  return !utc.isBefore(dstStartUtc) && utc.isBefore(dstEndUtc);
}

int _resolveUtcOffsetMinutes(DateTime utc, String timeZone) {
  switch (timeZone) {
    case 'UTC':
    case 'Etc/UTC':
    case 'GMT':
      return 0;
    case 'America/Los_Angeles':
    case 'America/Vancouver':
    case 'US/Pacific':
      return (_isUsDst(utc, -8) ? -7 : -8) * 60;
    case 'America/Denver':
    case 'US/Mountain':
      return (_isUsDst(utc, -7) ? -6 : -7) * 60;
    case 'America/Phoenix':
      return -7 * 60;
    case 'America/Chicago':
    case 'US/Central':
      return (_isUsDst(utc, -6) ? -5 : -6) * 60;
    case 'America/New_York':
    case 'America/Toronto':
    case 'US/Eastern':
      return (_isUsDst(utc, -5) ? -4 : -5) * 60;
    case 'America/Anchorage':
      return (_isUsDst(utc, -9) ? -8 : -9) * 60;
    case 'Pacific/Honolulu':
      return -10 * 60;
    case 'Europe/London':
      return (_isEuDst(utc) ? 1 : 0) * 60;
    case 'Europe/Paris':
    case 'Europe/Berlin':
    case 'Europe/Madrid':
    case 'Europe/Rome':
      return (_isEuDst(utc) ? 2 : 1) * 60;
    case 'Asia/Tokyo':
      return 9 * 60;
    case 'Asia/Kolkata':
      return 330;
    case 'Australia/Sydney':
      return 10 * 60;
    default:
      throw ArgumentError('Unsupported or invalid timeZone: $timeZone');
  }
}

({int hour, String dateKey}) formatLocalTimeInZone(
  DateTime now,
  String timeZone,
) {
  final utc = now.toUtc();
  final offsetMinutes = _resolveUtcOffsetMinutes(utc, timeZone);
  final shifted = utc.add(Duration(minutes: offsetMinutes));
  final year = shifted.year.toString().padLeft(4, '0');
  final month = shifted.month.toString().padLeft(2, '0');
  final day = shifted.day.toString().padLeft(2, '0');
  return (hour: shifted.hour, dateKey: '$year-$month-$day');
}
