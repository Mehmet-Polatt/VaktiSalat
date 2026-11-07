import 'dart:math' as math;


const double tokatLat = 40.3139;
const double tokatLng = 36.5544;

const double kaabaLat = 21.4225;
const double kaabaLng = 39.8262;

/// Tokat'ın manyetik sapması (yaklaşık, doğuya doğru).
const double tokatDeclination = 6.0;

/// Büyük daire başlangıç yönü (derece, 0-360, gerçek kuzeye göre).
double qiblaBearing({
  double lat = tokatLat,
  double lng = tokatLng,
}) {
  final p1 = lat * math.pi / 180;
  final p2 = kaabaLat * math.pi / 180;
  final dl = (kaabaLng - lng) * math.pi / 180;
  final y = math.sin(dl) * math.cos(p2);
  final x = math.cos(p1) * math.sin(p2) -
      math.sin(p1) * math.cos(p2) * math.cos(dl);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// a-b farkı, -180..180
double angleDiff(double a, double b) => ((a - b + 540) % 360) - 180;
