import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const String apiUrl = 'https://ezanvakti.emushaf.net/vakitler/9887';
const String _cacheKey = 'tokat_cache_v1';
const String _updatedKey = 'tokat_last_update_v1';

class PrayerRepository {
  PrayerRepository({http.Client? client, this._prefs})
      : _client = client ?? http.Client();

  final http.Client _client;
  SharedPreferences? _prefs;

  /// Gün anahtarı -> gün
  final Map<String, DayTimes> _cache = {};
  DateTime? lastUpdate;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final p = await _p;
    final s = p.getString(_cacheKey);
    if (s != null) {
      try {
        for (final e in jsonDecode(s) as List<dynamic>) {
          final d = DayTimes.fromJson(e as Map<String, dynamic>);
          if (d != null) _cache[dayKey(d.date)] = d;
        }
      } catch (_) {}
    }
    final u = p.getInt(_updatedKey);
    if (u != null) lastUpdate = DateTime.fromMillisecondsSinceEpoch(u);
  }

  int futureDays([DateTime? now]) {
    final today = turkeyDay(now);
    return _cache.values.where((d) => d.date.isAfter(today)).length;
  }

  /// Yetersiz veri: 7'den az ileri gün VEYA bugün/yarın eksik.
  bool needsFetch([DateTime? now]) {
    final today = turkeyDay(now);
    return futureDays(now) < 7 ||
        !hasCached(today) ||
        !hasCached(today.add(const Duration(days: 1)));
  }

  /// Önbelleğe yeni günleri ekler. Başarılıysa true.
  Future<bool> fetch({DateTime? now}) async {
    try {
      final r = await _client
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return false;
      final days = DayTimes.parseApi(jsonDecode(utf8.decode(r.bodyBytes)));
      if (days.isEmpty) return false;
      for (final d in days) {
        _cache[dayKey(d.date)] = d;
      }
      final cutoff = turkeyDay(now).subtract(const Duration(days: 1));
      _cache.removeWhere((_, d) => d.date.isBefore(cutoff));
      lastUpdate = DateTime.now();
      final p = await _p;
      await p.setString(
          _cacheKey, jsonEncode([for (final d in _cache.values) d.toJson()]));
      await p.setInt(_updatedKey, lastUpdate!.millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint('fetch failed: $e');
      return false;
    }
  }

  Future<void> fetchIfNeeded() async {
    if (needsFetch()) await fetch();
  }

  /// Yalnızca Diyanet verisi: önbellekte yoksa null (tahmin yok).
  DayTimes? forDay(DateTime day) => _cache[dayKey(day)];

  /// Önbellekteki gerçek günler ([back] gün öncesinden [count] gün ileriye).
  List<DayTimes> upcoming(int count, {DateTime? now, int back = 1}) {
    final today = turkeyDay(now);
    return [
      for (var i = -back; i < count; i++)
        ?forDay(today.add(Duration(days: i))),
    ];
  }

  bool hasCached(DateTime day) => _cache.containsKey(dayKey(day));
}
