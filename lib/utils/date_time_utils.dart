import 'dart:math' as math;

DateTime addMonths(DateTime date, int months) {
  final totalMonths = (date.month - 1) + months;
  final year = date.year + (totalMonths ~/ 12);
  final month = (totalMonths % 12) + 1;

  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = math.min(date.day, lastDayOfTargetMonth);

  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}
