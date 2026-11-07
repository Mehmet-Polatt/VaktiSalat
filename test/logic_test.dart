import 'package:flutter_test/flutter_test.dart';
import 'package:vakti_salat/data/heading.dart';
import 'package:vakti_salat/data/models.dart';
import 'package:vakti_salat/data/prayer_logic.dart';
import 'package:vakti_salat/data/qibla.dart';

DayTimes day(int d) => DayTimes.fromApi({
      'MiladiTarihKisa': '$d.11.2026',
      'HicriTarihUzun': 'x',
      'Imsak': '05:00',
      'Gunes': '06:30',
      'Ogle': '12:00',
      'Ikindi': '15:00',
      'Aksam': '17:30',
      'Yatsi': '19:00',
    })!;

// Türkiye saatinden UTC an
DateTime tr(int d, int h, int m) =>
    DateTime.utc(2026, 11, d, h, m).subtract(turkeyOffset);

void main() {
  test('parse API entry', () {
    final x = day(6);
    expect(formatTurkeyTime(x[Prayer.aksam]), '17:30');
    expect(x[Prayer.imsak], DateTime.utc(2026, 11, 6, 2, 0));
  });

  test('json roundtrip', () {
    final x = DayTimes.fromJson(day(6).toJson())!;
    expect(x[Prayer.yatsi], day(6)[Prayer.yatsi]);
    expect(dayKey(x.date), '2026-11-06');
  });

  test('bad entry returns null', () {
    expect(DayTimes.fromApi({'MiladiTarihKisa': 'zzz'}), isNull);
  });

  test('mid-day: next is Ikindi, current Ogle', () {
    final s = computeState(tr(6, 13, 0), day(5), day(6), day(7));
    expect(s.current, Prayer.ogle);
    expect(s.next, Prayer.ikindi);
    expect(s.progress(tr(6, 13, 30))!, closeTo(0.5, 1e-9));
  });

  test('after Yatsi: next is tomorrow Imsak', () {
    final s = computeState(tr(6, 22, 0), day(5), day(6), day(7));
    expect(s.current, Prayer.yatsi);
    expect(s.next, Prayer.imsak);
    expect(s.nextTime, day(7)[Prayer.imsak]);
  });

  test('before Imsak: current is yesterday Yatsi', () {
    final s = computeState(tr(6, 3, 0), day(5), day(6), day(7));
    expect(s.current, Prayer.yatsi);
    expect(s.currentStart, day(5)[Prayer.yatsi]);
    expect(s.next, Prayer.imsak);
  });

  test('qibla bearing from Tokat is about 170 degrees', () {
    expect(qiblaBearing(), inInclusiveRange(165, 175));
  });

  test('angleDiff wraps', () {
    expect(angleDiff(359, 1), -2);
    expect(angleDiff(1, 359), 2);
  });

  test('smoothAngle handles 359 to 0 wrap', () {
    expect(smoothAngle(null, 10), 10);
    final v = smoothAngle(359, 1, alpha: 0.5);
    expect(v, closeTo(0, 1e-9));
    expect(smoothAngle(1, 359, alpha: 0.5), closeTo(0, 1e-9));
  });

  test('after Yatsi with tomorrow missing: next unknown, no invented time', () {
    final s = computeState(tr(6, 22, 0), day(5), day(6), null);
    expect(s.current, Prayer.yatsi);
    expect(s.hasNext, isFalse);
    expect(s.nextTime, isNull);
    expect(s.progress(tr(6, 22, 0)), isNull);
  });

  test('before Imsak with yesterday missing: next known, current unknown', () {
    final s = computeState(tr(6, 3, 0), null, day(6), day(7));
    expect(s.next, Prayer.imsak);
    expect(s.nextTime, day(6)[Prayer.imsak]);
    expect(s.current, isNull);
    expect(s.progress(tr(6, 3, 0)), isNull);
  });

  test('no data at all', () {
    final s = computeState(tr(6, 3, 0), null, null, null);
    expect(s.hasNext, isFalse);
    expect(s.current, isNull);
  });
}
