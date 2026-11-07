import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppColors {
  static const bgTop = Color(0xFF0B1020);
  static const bgBottom = Color(0xFF161D3A);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE9D28A);
  static const text = Color(0xFFF1ECDD);
  static const textDim = Color(0xFF8D93AD);
  static const card = Color(0xFF121935);
  static const green = Color(0xFF5FD38D);
}

TextStyle display(double size,
        {Color color = AppColors.text,
        FontWeight weight = FontWeight.w600,
        double? spacing}) =>
    TextStyle(
        fontFamily: 'Cormorant',
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.1);

TextStyle body(double size,
        {Color color = AppColors.text,
        FontWeight weight = FontWeight.w500,
        double? spacing}) =>
    TextStyle(
        fontFamily: 'Manrope',
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing);

ThemeData buildTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgTop,
      fontFamily: 'Manrope',
      colorScheme: const ColorScheme.dark(
          primary: AppColors.gold, surface: AppColors.card),
      useMaterial3: true,
    );

/// Gradyan + hafif İslami geometrik desen arka planı.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
      ),
      const RepaintBoundary(child: CustomPaint(painter: PatternPainter())),
      child,
    ]);
  }
}

/// Sekiz köşeli yıldız (Rub el Hizb) ağından oluşan desen.
class PatternPainter extends CustomPainter {
  const PatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.gold.withValues(alpha: 0.07);
    for (double y = 0; y < size.height + cell; y += cell) {
      for (double x = 0; x < size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), cell * 0.42, paint);
        _star(canvas, Offset(x + cell / 2, y + cell / 2), cell * 0.2, paint);
      }
    }
    // Üstten alta yumuşak solma
    final fade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0x55000000)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fade);
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final a = Path();
    final b = Path();
    for (var i = 0; i < 4; i++) {
      final ang = i * math.pi / 2;
      final pa = o + Offset(math.cos(ang), math.sin(ang)) * r;
      final pb = o +
          Offset(math.cos(ang + math.pi / 4), math.sin(ang + math.pi / 4)) * r;
      i == 0 ? a.moveTo(pa.dx, pa.dy) : a.lineTo(pa.dx, pa.dy);
      i == 0 ? b.moveTo(pb.dx, pb.dy) : b.lineTo(pb.dx, pb.dy);
    }
    a.close();
    b.close();
    c.drawPath(a, p);
    c.drawPath(b, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
