import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/heading.dart';
import '../data/qibla.dart';
import 'theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.active});
  final bool active;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final double bearing = qiblaBearing();
  StreamSubscription<HeadingSample>? _sub;
  Timer? _noSensorTimer;
  double? heading; // gerçek kuzeye göre, yumuşatılmış
  double accuracy = 0;
  bool noSensor = false;
  bool aligned = false;

  @override
  void initState() {
    super.initState();
    _sub = headingStream().listen(_onSample, onError: (_) {
      if (mounted) setState(() => noSensor = true);
    });
    _noSensorTimer = Timer(const Duration(seconds: 3), () {
      if (heading == null && mounted) setState(() => noSensor = true);
    });
  }

  void _onSample(HeadingSample s) {
    final h = smoothAngle(heading, s.heading);
    final nowAligned = angleDiff(bearing, h).abs() <= 3;
    if (nowAligned && !aligned) HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      heading = h;
      accuracy = s.accuracy;
      aligned = nowAligned;
      noSensor = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _noSensorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = heading ?? 0;
    final poor = accuracy > 25;
    final color = aligned ? AppColors.green : AppColors.gold;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(children: [
          Text('Kıble', style: display(34, color: AppColors.gold, spacing: 1.5)),
          const SizedBox(height: 4),
          Text('Tokat’tan Kâbe yönü',
              style: body(13, color: AppColors.textDim)),
          const SizedBox(height: 14),
          Text('${bearing.toStringAsFixed(1)}°',
              style: body(52, color: AppColors.goldSoft, weight: FontWeight.w300)),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              aligned ? 'Kıble yönündesiniz' : (heading == null ? ' ' : 'Telefonu çevirin'),
              key: ValueKey(aligned),
              style: body(16,
                  color: aligned ? AppColors.green : AppColors.textDim,
                  weight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: h),
                  duration: const Duration(milliseconds: 120),
                  builder: (_, v, _) => CustomPaint(
                    painter: _CompassPainter(
                        heading: v, bearing: bearing, accent: color, aligned: aligned),
                  ),
                ),
              ),
            ),
          ),
          if (noSensor)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.sensors_off, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        'Bu cihazda pusula sensörü bulunamadı. Kıble açısı yukarıda gösterilmektedir.',
                        style: body(13, color: AppColors.textDim))),
              ]),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.gesture,
                    size: poor ? 22 : 18,
                    color: poor ? AppColors.gold : AppColors.textDim),
                const SizedBox(width: 8),
                Text(
                    poor
                        ? 'Pusula hassasiyeti düşük: Telefonu 8 çizerek kalibre edin'
                        : 'Telefonu 8 çizerek kalibre edin',
                    style: poor
                        ? body(14, color: AppColors.gold, weight: FontWeight.w700)
                        : body(13, color: AppColors.textDim)),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(
      {required this.heading,
      required this.bearing,
      required this.accent,
      required this.aligned});
  final double heading, bearing;
  final Color accent;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    // Sabit üst işaret (telefonun yönü)
    final tri = Path()
      ..moveTo(c.dx, c.dy - r - 2)
      ..lineTo(c.dx - 9, c.dy - r - 18)
      ..lineTo(c.dx + 9, c.dy - r - 18)
      ..close();
    canvas.drawPath(tri, Paint()..color = accent);

    final rr = r - 14;
    // Dolgu
    canvas.drawCircle(
        c,
        rr,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFF1A2347),
            AppColors.card.withValues(alpha: 0.9)
          ]).createShader(Rect.fromCircle(center: c, radius: rr)));
    if (aligned) {
      canvas.drawCircle(
          c,
          rr,
          Paint()
            ..color = AppColors.green.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 18));
    }
    canvas.drawCircle(
        c, rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = accent);
    canvas.drawCircle(
        c,
        rr - 8,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = AppColors.gold.withValues(alpha: 0.4));

    // Dönen kadran
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-heading * math.pi / 180);

    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var d = 0; d < 360; d += 5) {
      final major = d % 90 == 0;
      final mid = d % 30 == 0;
      final len = major ? 0 : (mid ? 14.0 : 7.0);
      if (major) continue;
      tick
        ..strokeWidth = mid ? 2 : 1
        ..color = AppColors.gold.withValues(alpha: mid ? 0.9 : 0.45);
      final a = d * math.pi / 180;
      final p1 = Offset(math.sin(a), -math.cos(a)) * (rr - 10);
      final p2 = Offset(math.sin(a), -math.cos(a)) * (rr - 10 - len);
      canvas.drawLine(p1, p2, tick);
    }
    const letters = {0: 'K', 90: 'D', 180: 'G', 270: 'B'};
    letters.forEach((deg, t) {
      final a = deg * math.pi / 180;
      final pos = Offset(math.sin(a), -math.cos(a)) * (rr - 34);
      final tp = TextPainter(
        text: TextSpan(
            text: t,
            style: display(26,
                color: deg == 0 ? const Color(0xFFE5655A) : AppColors.goldSoft,
                weight: FontWeight.w700)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(a);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });

    // Kıble işaretçisi (Kâbe)
    final qa = bearing * math.pi / 180;
    final dir = Offset(math.sin(qa), -math.cos(qa));
    final needle = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(dir * 18, dir * (rr - 66), needle);
    // iğnenin kuyruğu
    canvas.drawLine(
        dir * -6, dir * -30, needle..color = accent.withValues(alpha: 0.35));
    final kPos = dir * (rr - 52);
    canvas.save();
    canvas.translate(kPos.dx, kPos.dy);
    canvas.rotate(qa);
    final box = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -14, 28, 28), const Radius.circular(5));
    canvas.drawRRect(box, Paint()..color = const Color(0xFF0B0B0B));
    canvas.drawRRect(
        box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = accent);
    canvas.drawRect(const Rect.fromLTWH(-14, -6, 28, 4),
        Paint()..color = accent.withValues(alpha: 0.9));
    canvas.restore();
    canvas.restore();

    // Merkez
    canvas.drawCircle(c, 7, Paint()..color = accent);
    canvas.drawCircle(c, 3, Paint()..color = AppColors.bgTop);
  }

  @override
  bool shouldRepaint(_CompassPainter o) =>
      o.heading != heading || o.aligned != aligned || o.bearing != bearing;
}
