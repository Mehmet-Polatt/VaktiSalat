import 'models.dart';

/// Mevcut/sonraki vakit. Bilinmeyen değerler null'dır; veri uydurulmaz.
class PrayerState {
  const PrayerState({
    this.current,
    this.currentStart,
    this.next,
    this.nextTime,
  });

  /// Şu an geçerli olan vakit (İmsak'tan önce: önceki günün Yatsı'sı; veri yoksa null).
  final Prayer? current;
  final DateTime? currentStart;
  final Prayer? next;
  final DateTime? nextTime;

  /// Sonraki vakit biliniyor mu (geri sayım gösterilebilir mi).
  bool get hasNext => next != null && nextTime != null;

  /// Geçen oran; başlangıç ya da bitiş bilinmiyorsa null.
  double? progress(DateTime now) {
    if (currentStart == null || nextTime == null) return null;
    final total = nextTime!.difference(currentStart!).inMilliseconds;
    if (total <= 0) return 0;
    final el = now.difference(currentStart!).inMilliseconds;
    return (el / total).clamp(0.0, 1.0);
  }
}

/// Eldeki (null olmayan) günlerden geçerli/sonraki vakti bulur.
PrayerState computeState(
  DateTime now,
  DayTimes? yesterday,
  DayTimes? today,
  DayTimes? tomorrow,
) {
  final entries = <MapEntry<Prayer, DateTime>>[
    for (final d in [yesterday, today, tomorrow])
      if (d != null)
        for (final p in Prayer.values) MapEntry(p, d[p]),
  ];
  final n = now.toUtc();
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].value.isAfter(n)) {
      final prev = i > 0 ? entries[i - 1] : null;
      return PrayerState(
        current: prev?.key,
        currentStart: prev?.value,
        next: entries[i].key,
        nextTime: entries[i].value,
      );
    }
  }
  if (entries.isEmpty) return const PrayerState();
  final last = entries.last;
  return PrayerState(current: last.key, currentStart: last.value);
}
