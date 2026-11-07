import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import 'controller.dart';
import 'theme.dart';

const _icons = {
  Prayer.imsak: Icons.nights_stay_outlined,
  Prayer.gunes: Icons.wb_twilight_rounded,
  Prayer.ogle: Icons.wb_sunny_outlined,
  Prayer.ikindi: Icons.wb_cloudy_outlined,
  Prayer.aksam: Icons.bedtime_outlined,
  Prayer.yatsi: Icons.dark_mode_outlined,
};

class PrayerScreen extends StatelessWidget {
  const PrayerScreen({super.key, required this.controller});
  final PrayerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.ready) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }
        final c = controller;
        final st = c.state;
        final today = c.today;
        final trNow = turkeyNow(c.now);
        final dateStr = DateFormat('d MMMM y EEEE', 'tr_TR').format(trNow);
        final nowUtc = c.now.toUtc();
        String? cd;
        if (st.hasNext) {
          final secs =
              st.nextTime!.difference(nowUtc).inSeconds.clamp(0, 999999);
          cd = '${(secs ~/ 3600).toString().padLeft(2, '0')}:'
              '${((secs % 3600) ~/ 60).toString().padLeft(2, '0')}:'
              '${(secs % 60).toString().padLeft(2, '0')}';
        }
        return SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.gold,
            backgroundColor: AppColors.card,
            onRefresh: c.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                _Header(date: dateStr, hijri: today?.hijri ?? ''),
                const SizedBox(height: 14),
                if (today == null)
                  _EmptyState(refreshing: c.refreshing, onRefresh: c.refresh)
                else ...[
                  _Hero(
                      name: st.next?.label,
                      time: st.nextTime == null
                          ? null
                          : formatTurkeyTime(st.nextTime!),
                      countdown: cd,
                      progress: st.progress(c.now)),
                  const SizedBox(height: 14),
                  for (final p in Prayer.values)
                    _Row(
                      prayer: p,
                      time: formatTurkeyTime(today[p]),
                      isCurrent: p == st.current,
                      isPast: today[p].isBefore(nowUtc),
                    ),
                ],
                const SizedBox(height: 14),
                _Footer(
                    last: c.repo.lastUpdate,
                    refreshing: c.refreshing,
                    lowData: c.repo.futureDays(c.now) < 3),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.refreshing, required this.onRefresh});
  final bool refreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.card.withValues(alpha: 0.85),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.gold),
        const SizedBox(height: 16),
        Text('Diyanet vakit verisi alınamadı',
            textAlign: TextAlign.center,
            style: display(28, color: AppColors.goldSoft)),
        const SizedBox(height: 8),
        Text('İnternete bağlanıp yenileyin',
            textAlign: TextAlign.center,
            style: body(14, color: AppColors.textDim)),
        const SizedBox(height: 22),
        SizedBox(
          height: 44,
          child: refreshing
              ? const Center(
                  child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.gold)))
              : OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Yenile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: const BorderSide(color: AppColors.gold),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    textStyle: body(15, weight: FontWeight.w700),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.hijri});
  final String date, hijri;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.location_on, size: 16, color: AppColors.gold),
        const SizedBox(width: 6),
        Text('Tokat',
            style: display(36, color: AppColors.gold, spacing: 1.5)),
      ]),
      const SizedBox(height: 6),
      Text(date, style: body(15, weight: FontWeight.w600)),
      if (hijri.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(hijri, style: body(13, color: AppColors.textDim)),
      ],
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.name,
      required this.time,
      required this.countdown,
      required this.progress});
  final String? name, time, countdown;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppColors.card.withValues(alpha: 0.85),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.08),
              blurRadius: 30,
              spreadRadius: 1),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: CustomPaint(
          painter: _RingPainter(progress ?? 0, showProgress: progress != null),
          child: Center(
            child: name == null || countdown == null || time == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: Text('Yarının vakitleri henüz yüklenmedi',
                        textAlign: TextAlign.center,
                        style: display(26, color: AppColors.goldSoft)),
                  )
                : Column(mainAxisSize: MainAxisSize.min, children: [
              Text('SONRAKİ VAKİT',
                  style: body(11.5,
                      color: AppColors.textDim,
                      weight: FontWeight.w700,
                      spacing: 2)),
              const SizedBox(height: 4),
              Text(name!, style: display(38, color: AppColors.goldSoft)),
              const SizedBox(height: 6),
              Text(countdown!,
                  style: body(32, weight: FontWeight.w300, spacing: 1)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 6),
              Text(time!,
                  style: body(16,
                      color: AppColors.gold, weight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, {required this.showProgress});
  final double progress;
  final bool showProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 8;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppColors.gold.withValues(alpha: 0.14);
    canvas.drawCircle(c, r, track);
    final rect = Rect.fromCircle(center: c, radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: const [AppColors.goldSoft, AppColors.gold, AppColors.goldSoft],
        transform: const GradientRotation(0),
      ).createShader(rect);
    if (showProgress) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }
    // ince iç halka
    canvas.drawCircle(
        c,
        r - 14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.gold.withValues(alpha: 0.25));
    // ilerleme noktası
    if (!showProgress) return;
    final a = -math.pi / 2 + 2 * math.pi * progress;
    final dot = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(dot, 9, Paint()..color = AppColors.gold.withValues(alpha: 0.25));
    canvas.drawCircle(dot, 4.5, Paint()..color = AppColors.goldSoft);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.showProgress != showProgress;
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.prayer,
      required this.time,
      required this.isCurrent,
      required this.isPast});
  final Prayer prayer;
  final String time;
  final bool isCurrent, isPast;

  @override
  Widget build(BuildContext context) {
    final dim = isPast && !isCurrent;
    final fg = isCurrent
        ? AppColors.goldSoft
        : (dim ? AppColors.textDim.withValues(alpha: 0.7) : AppColors.text);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isCurrent
            ? AppColors.gold.withValues(alpha: 0.12)
            : AppColors.card.withValues(alpha: 0.6),
        border: Border.all(
            color: isCurrent
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.08),
            width: isCurrent ? 1.4 : 0.8),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 18)
              ]
            : null,
      ),
      child: Row(children: [
        Icon(_icons[prayer], size: 22, color: isCurrent ? AppColors.gold : fg),
        const SizedBox(width: 14),
        Expanded(
            child: Text(prayer.label,
                style: display(24, color: fg, weight: FontWeight.w600))),
        if (isCurrent)
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Text('ŞİMDİ',
                style: body(10,
                    color: AppColors.gold,
                    weight: FontWeight.w800,
                    spacing: 1.2)),
          ),
        Text(time,
            style: body(20, color: fg, weight: FontWeight.w600).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer(
      {required this.last, required this.refreshing, required this.lowData});
  final bool refreshing, lowData;
  final DateTime? last;

  @override
  Widget build(BuildContext context) {
    final upd = last == null
        ? 'Henüz güncellenmedi'
        : 'Son güncelleme: ${DateFormat('d MMM HH:mm', 'tr_TR').format(last!)}';
    return Column(children: [
      Text(refreshing ? 'Güncelleniyor…' : 'Kaynak: Diyanet İşleri Başkanlığı',
          style: body(12, color: AppColors.textDim, weight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(upd, style: body(11, color: AppColors.textDim.withValues(alpha: 0.7))),
      if (lowData) ...[
        const SizedBox(height: 4),
        Text('Veri az kaldı, internete bağlanın',
            style: body(11, color: AppColors.gold.withValues(alpha: 0.8))),
      ],
    ]);
  }
}
