import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'repository.dart';

const String appGroupId = 'group.com.mehmetpolat.vaktisalat';

/// Widget'a gidecek JSON: yalnızca önbellekteki gerçek Diyanet günleri.
String buildWidgetPayload(PrayerRepository repo, {DateTime? now}) {
  final days = repo.upcoming(16, now: now);
  return jsonEncode([
    for (final d in days)
      {
        'date': d.toJson()['date'],
        'times': d.toJson()['times'], // epoch saniye (UTC)
      }
  ]);
}

class WidgetSync {
  static bool _inited = false;

  static Future<void> push(PrayerRepository repo, {DateTime? now}) async {
    try {
      if (!_inited) {
        await HomeWidget.setAppGroupId(appGroupId);
        _inited = true;
      }
      await HomeWidget.saveWidgetData<String>(
          'prayer_days', buildWidgetPayload(repo, now: now));
      await HomeWidget.updateWidget(iOSName: 'PrayerWidget');
    } catch (e) {
      debugPrint('widget sync failed: $e');
    }
  }
}
