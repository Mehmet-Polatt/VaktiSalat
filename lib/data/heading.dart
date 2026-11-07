import 'dart:async';

import 'package:flutter/services.dart';

import 'qibla.dart';

class HeadingSample {
  const HeadingSample(this.heading, this.accuracy);

  /// Gerçek kuzeye göre derece.
  final double heading;
  final double accuracy;
}

/// Yerel pusula akışı. Sensör yoksa akış hata verir.
Stream<HeadingSample> headingStream() {
  const channel = EventChannel('tokat/heading');
  return channel.receiveBroadcastStream().map((e) {
    final m = Map<dynamic, dynamic>.from(e as Map);
    final t = (m['true'] as num).toDouble();
    final mag = (m['magnetic'] as num).toDouble();
    final h = t >= 0 ? t : (mag + tokatDeclination) % 360;
    return HeadingSample(h, (m['accuracy'] as num).toDouble());
  });
}

/// Açılar için alçak geçiren filtre (359→0 geçişine dayanıklı).
double smoothAngle(double? previous, double next, {double alpha = 0.25}) {
  if (previous == null) return next;
  return (previous + alpha * angleDiff(next, previous) + 360) % 360;
}
