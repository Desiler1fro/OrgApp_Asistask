import 'package:intl/intl.dart';

class TimeFormat {
  const TimeFormat._();

  static String minutesToClock(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String range(int startMinutes, int endMinutes) {
    return '${minutesToClock(startMinutes)} — ${minutesToClock(endMinutes)}';
  }

  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m min';
    if (m == 0) return h == 1 ? '1 h' : '$h h';
    return '$h h $m min';
  }

  static String fullDate(DateTime date) {
    return DateFormat("EEEE d 'de' MMMM", 'es').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat("d 'de' MMM", 'es').format(date);
  }

  static String weekdayShort(DateTime date) {
    return DateFormat('EEE', 'es').format(date);
  }
}

DateTime dateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);
