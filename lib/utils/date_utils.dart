class DateUtilsX {
  static DateTime startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  static DateTime endOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day, 23, 59, 59);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isOverdue(DateTime dueAt, DateTime now) {
    // overdue if due time is before "now" and not on a future day
    return dueAt.isBefore(now) && !isSameDay(dueAt, now) || (isSameDay(dueAt, now) && dueAt.isBefore(now));
  }

  static bool isDueToday(DateTime dueAt, DateTime now) => isSameDay(dueAt, now);

  static DateTime addDays(DateTime dt, int days) => dt.add(Duration(days: days));
}
