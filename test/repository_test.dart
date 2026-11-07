import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vakti_salat/data/models.dart';
import 'package:vakti_salat/data/repository.dart';
import 'package:vakti_salat/data/widget_sync.dart';

void main() {
  final body = File('test/fixtures/tokat.json').readAsStringSync();
  final now = DateTime.utc(2026, 11, 1, 9); // Türkiye 12:00, fixture kapsamında

  MockClient ok(void Function() onCall) => MockClient((_) async {
        onCall();
        return http.Response.bytes(utf8.encode(body), 200);
      });

  test('fetch fills cache; forDay is null when not cached', () async {
    SharedPreferences.setMockInitialValues({});
    var calls = 0;
    final repo = PrayerRepository(client: ok(() => calls++));
    await repo.load();
    expect(repo.forDay(turkeyDay(now)), isNull);
    expect(repo.needsFetch(now), isTrue);
    expect(await repo.fetch(now: now), isTrue);
    expect(calls, 1);
    expect(repo.needsFetch(now), isFalse);
    expect(repo.forDay(turkeyDay(now)), isNotNull);
    // Kapsam dışı gün: tahmin yok
    expect(repo.forDay(DateTime.utc(2027, 3, 1)), isNull);
    final repo2 = PrayerRepository(client: ok(() {}));
    await repo2.load();
    expect(repo2.hasCached(turkeyDay(now)), isTrue);
  });

  test('fetches when tomorrow is missing even with 7+ future days', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrayerRepository(client: ok(() {}));
    await repo.load();
    await repo.fetch(now: now);
    // 'now' fixture'ın ortasında; bugün = 1 Kasım. Yarın var -> fetch gerekmez.
    expect(repo.needsFetch(now), isFalse);
    // Fixture sonundan (1 Aralık) sonrası: bugün/yarın yok -> fetch gerekir.
    final late = DateTime.utc(2026, 12, 1, 9);
    expect(repo.hasCached(turkeyDay(late)), isTrue);
    expect(repo.hasCached(turkeyDay(late).add(const Duration(days: 1))), isFalse);
    expect(repo.needsFetch(late), isTrue);
  });

  test('widget payload contains only cached days', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrayerRepository(client: ok(() {}));
    await repo.load();
    expect(jsonDecode(buildWidgetPayload(repo, now: now)), isEmpty);
    await repo.fetch(now: now);
    final late = DateTime.utc(2026, 11, 28, 9); // 28 Kasım; veri 1 Aralık'ta biter
    final list = jsonDecode(buildWidgetPayload(repo, now: late)) as List;
    // dün (27) .. 1 Aralık = 5 gün; 16 günlük pencere uydurma günle doldurulmaz
    expect(list.length, 5);
    expect(list.last['date'], '2026-12-01');
  });

  test('network failure is silent and keeps cache empty', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrayerRepository(
        client: MockClient((_) async => throw const SocketException('x')));
    await repo.load();
    expect(await repo.fetch(), isFalse);
    expect(repo.forDay(turkeyDay(now)), isNull);
  });
}
