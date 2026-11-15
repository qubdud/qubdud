/// Ile dni kalendarzowych (data lokalna) minęło od [d]: 0 = dziś, 1 = wczoraj.
int calendarDaysAgo(DateTime d) {
  final now = DateTime.now();
  final local = d.toLocal();
  return DateTime.utc(now.year, now.month, now.day)
      .difference(DateTime.utc(local.year, local.month, local.day))
      .inDays;
}
