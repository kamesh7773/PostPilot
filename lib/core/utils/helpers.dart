import 'package:flutter/material.dart';

/// e.g. "7:30 PM", in the device's locale and 12/24h setting.
String formatPostTimeOfDay(BuildContext context, DateTime time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );

/// e.g. "Oct 9, 2026 · 7:30 PM".
String formatPostTime(BuildContext context, DateTime time) =>
    '${MaterialLocalizations.of(context).formatMediumDate(time)} · '
    '${formatPostTimeOfDay(context, time)}';

/// "Today", "Tomorrow", or e.g. "Friday, October 10, 2026".
String formatPostDay(BuildContext context, DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(day.year, day.month, day.day).difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return MaterialLocalizations.of(context).formatFullDate(day);
}
