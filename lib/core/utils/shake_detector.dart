import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  // limiar testado manualmente — abaixo disso pega muito ruído
  static const double _threshold = 25.0;
  static const double _maxMagnitude = 55.0;
  static const int _cooldownMs = 1200;

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  final void Function(double intensity) onShake;

  ShakeDetector({required this.onShake});

  void start() {
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final agora = DateTime.now();

      if (mag > _threshold && agora.difference(_lastShake).inMilliseconds > _cooldownMs) {
        _lastShake = agora;
        // normaliza a intensidade entre 0 e 1
        final intensidade = ((mag - _threshold) / (_maxMagnitude - _threshold)).clamp(0.0, 1.0);
        onShake(intensidade);
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
