import 'package:intl/intl.dart';

/// Vietnamese date-group buckets used for conversation list grouping (HIST-03).
///
/// SIMPLIFICATION (documented per plan action):
/// The [thisMonth] bucket is the bucket-of-last-resort — every conversation
/// older than 7 days lands here regardless of how old it is. This keeps the
/// drawer simple: there are exactly 4 possible group headers and every
/// conversation always belongs to one. Future phases may add an "Older" bucket.
enum ChatDateGroup {
  /// Same calendar day as now.
  today,

  /// One calendar day before now.
  yesterday,

  /// Within the last 7 calendar days (not today or yesterday).
  thisWeek,

  /// Everything older than 7 days (bucket-of-last-resort — no item is dropped).
  thisMonth,
}

extension ChatDateGroupLabel on ChatDateGroup {
  /// Vietnamese display label for the drawer section header.
  String get label {
    switch (this) {
      case ChatDateGroup.today:
        return 'Hôm nay';
      case ChatDateGroup.yesterday:
        return 'Hôm qua';
      case ChatDateGroup.thisWeek:
        return 'Tuần này';
      case ChatDateGroup.thisMonth:
        return 'Tháng này';
    }
  }
}

/// Returns the [ChatDateGroup] that [dt] belongs to relative to [now].
///
/// If [now] is not supplied, `DateTime.now()` is used. The comparison is
/// calendar-day based (year + month + day), not duration based, so a
/// conversation created at 23:59 yesterday is correctly placed in
/// [ChatDateGroup.yesterday] even if it was only a few minutes ago.
///
/// Bucketing rules:
///   - [today]: `dt` falls on the same calendar day as `now`.
///   - [yesterday]: `dt` falls on the calendar day immediately before `now`.
///   - [thisWeek]: `dt` is within the 7 calendar days before today
///     (exclusive of today and yesterday already matched above).
///   - [thisMonth]: everything else (older than 7 days). This is the
///     bucket-of-last-resort — no conversation is ever dropped.
ChatDateGroup chatDateGroup(DateTime dt, {DateTime? now}) {
  final today = now ?? DateTime.now();

  // Normalise to midnight (calendar-day comparison).
  final todayDate = DateTime(today.year, today.month, today.day);
  final dtDate = DateTime(dt.year, dt.month, dt.day);

  final diff = todayDate.difference(dtDate).inDays;

  if (diff == 0) return ChatDateGroup.today;
  if (diff == 1) return ChatDateGroup.yesterday;
  if (diff <= 7) return ChatDateGroup.thisWeek;
  return ChatDateGroup.thisMonth;
}

/// Returns a short display date for a conversation list item.
///
/// - Today (same calendar day as [now]): `HH:mm` format (e.g. "09:05").
/// - Any other day: `d MMM` format (e.g. "3 Thg 5").
///
/// Uses `DateFormat` with NO locale argument — the vi locale data is not
/// initialised (`flutter_localizations` is not installed). Group labels are
/// hand-rolled Vietnamese strings; only the per-item short date uses
/// DateFormat with the system/default locale.
String itemShortDate(DateTime dt, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final dtDate = DateTime(dt.year, dt.month, dt.day);

  if (dtDate == todayDate) {
    return DateFormat('HH:mm').format(dt);
  }
  return DateFormat('d MMM').format(dt);
}
