/// Namaz vakti veri modelleri. Tüm anlar UTC olarak tutulur; gösterim için
/// Europe/Istanbul (UTC+3, yaz saati yok) kullanılır.
enum Prayer {
  imsak('İmsak'),
  gunes('Güneş'),
  ogle('Öğle'),
  ikindi('İkindi'),
  aksam('Akşam'),
  yatsi('Yatsı');

  const Prayer(this.label);
  final String label;
}

const Duration turkeyOffset = Duration(hours: 3);

/// Şu anki Türkiye saati (duvar saati değerleri UTC alanında).
DateTime turkeyNow([DateTime? now]) =>
    (now ?? DateTime.now()).toUtc().add(turkeyOffset);

/// Türkiye takvim gününün anahtarı (UTC gece yarısı).
DateTime turkeyDay([DateTime? now]) {
  final t = turkeyNow(now);
  return DateTime.utc(t.year, t.month, t.day);
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Bir anı Türkiye saatine göre "HH:mm" olarak biçimlendirir.
String formatTurkeyTime(DateTime instant) {
  final t = instant.toUtc().add(turkeyOffset);
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class DayTimes {
  DayTimes({
    required this.date,
    required this.hijri,
    required this.times,
  });

  /// Türkiye takvim günü, UTC gece yarısı olarak.
  final DateTime date;
  final String hijri;
  final Map<Prayer, DateTime> times;

  DateTime operator [](Prayer p) => times[p]!;

  /// API yanıtındaki bir günü ayrıştırır. Geçersizse null.
  static DayTimes? fromApi(Map<String, dynamic> m) {
    try {
      final parts = (m['MiladiTarihKisa'] as String).split('.');
      final day = DateTime.utc(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      DateTime parse(String key) {
        final hm = (m[key] as String).split(':');
        return day
            .add(Duration(hours: int.parse(hm[0]), minutes: int.parse(hm[1])))
            .subtract(turkeyOffset);
      }

      return DayTimes(
        date: day,
        hijri: (m['HicriTarihUzun'] as String?) ?? '',
        times: {
          Prayer.imsak: parse('Imsak'),
          Prayer.gunes: parse('Gunes'),
          Prayer.ogle: parse('Ogle'),
          Prayer.ikindi: parse('Ikindi'),
          Prayer.aksam: parse('Aksam'),
          Prayer.yatsi: parse('Yatsi'),
        },
      );
    } catch (_) {
      return null;
    }
  }

  static List<DayTimes> parseApi(List<dynamic> list) => [
        for (final e in list)
          if (e is Map<String, dynamic>) ?DayTimes.fromApi(e)
      ];

  Map<String, dynamic> toJson() => {
        'date': dayKey(date),
        'hijri': hijri,
        'times': {
          for (final e in times.entries)
            e.key.name: e.value.millisecondsSinceEpoch ~/ 1000
        },
      };

  static DayTimes? fromJson(Map<String, dynamic> j) {
    try {
      final d = (j['date'] as String).split('-');
      final t = j['times'] as Map<String, dynamic>;
      return DayTimes(
        date: DateTime.utc(int.parse(d[0]), int.parse(d[1]), int.parse(d[2])),
        hijri: j['hijri'] as String? ?? '',
        times: {
          for (final p in Prayer.values)
            p: DateTime.fromMillisecondsSinceEpoch((t[p.name] as int) * 1000,
                isUtc: true)
        },
      );
    } catch (_) {
      return null;
    }
  }
}
