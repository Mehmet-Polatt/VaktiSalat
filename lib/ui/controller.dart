import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/models.dart';
import '../data/prayer_logic.dart';
import '../data/repository.dart';
import '../data/widget_sync.dart';

/// Veriyi, saniyelik zamanlayıcıyı ve yaşam döngüsünü yönetir.
const bool _noData = bool.fromEnvironment('NO_DATA');

class PrayerController extends ChangeNotifier with WidgetsBindingObserver {
  PrayerController(this.repo);

  final PrayerRepository repo;
  Timer? _timer;
  DateTime now = DateTime.now();
  bool ready = false;
  bool refreshing = false;
  DayTimes? today;
  PrayerState state = const PrayerState();
  DateTime _day = DateTime.utc(2000);

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    // NO_DATA: yalnızca geliştirme; boş durum ekranını denemek için önbelleği ve ağı atlar.
    if (!_noData) await repo.load();
    _recompute();
    ready = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (!_noData) await _sync(fetchIfNeeded: true);
  }

  Future<void> _sync({bool fetchIfNeeded = false, bool force = false}) async {
    if (force) {
      refreshing = true;
      notifyListeners();
      await repo.fetch();
      refreshing = false;
    } else if (fetchIfNeeded) {
      await repo.fetchIfNeeded();
    }
    _recompute();
    notifyListeners();
    await WidgetSync.push(repo);
  }

  Future<void> refresh() => _noData ? Future.value() : _sync(force: true);

  void _recompute() {
    now = DateTime.now();
    final d = turkeyDay(now);
    _day = d;
    today = repo.forDay(d);
    state = computeState(now, repo.forDay(d.subtract(const Duration(days: 1))),
        today, repo.forDay(d.add(const Duration(days: 1))));
  }

  void _tick() {
    now = DateTime.now();
    final nt = state.nextTime;
    if (!turkeyDay(now).isAtSameMomentAs(_day) ||
        nt == null ||
        !now.toUtc().isBefore(nt)) {
      _recompute();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recompute();
      notifyListeners();
      if (!_noData) _sync(fetchIfNeeded: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
