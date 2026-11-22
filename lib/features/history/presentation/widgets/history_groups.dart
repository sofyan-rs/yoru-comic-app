import 'package:yoru/core/constants/texts.dart';
import 'package:yoru/features/history/domain/entities/read_history.dart';

/// Comics last read on the same day, newest day first.
class HistoryDay {
  const HistoryDay(this.label, this.items);

  /// "Today", "Yesterday" or `19 Oct 2026`.
  final String label;
  final List<ComicLatestHistory> items;

  /// Groups [latest] (newest first, one entry per comic) by local day.
  static List<HistoryDay> group(List<ComicLatestHistory> latest, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime, List<ComicLatestHistory>>{};
    for (final item in latest) {
      final read = item.latestHistory.readDate.toLocal();
      days
          .putIfAbsent(DateTime(read.year, read.month, read.day), () => [])
          .add(item);
    }
    return [
      for (final MapEntry(key: day, value: items) in days.entries)
        HistoryDay(dayLabel(day, today), items),
    ];
  }

  static String dayLabel(DateTime day, DateTime today) {
    final diff = today.difference(day).inDays;
    if (diff == 0) return AppText.t.today;
    if (diff == 1) return AppText.t.yesterday;
    return '${day.day} ${AppText.t.monthsShort.split(',')[day.month - 1]} ${day.year}';
  }

  /// `09:12`.
  static String time(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}';
  }
}
