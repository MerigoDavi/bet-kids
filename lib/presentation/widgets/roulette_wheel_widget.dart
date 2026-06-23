import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class RouletteSegment {
  final String label;
  final int multiplier;
  final Color color;

  const RouletteSegment({
    required this.label,
    required this.multiplier,
    required this.color,
  });
}

const rouletteSegments = [
  RouletteSegment(label: '2x', multiplier: 2, color: Color(0xFF9B59B6)),
  RouletteSegment(label: '❌', multiplier: 0, color: Color(0xFFE74C3C)),
  RouletteSegment(label: '3x', multiplier: 3, color: Color(0xFFF39C12)),
  RouletteSegment(label: '5x', multiplier: 5, color: Color(0xFF27AE60)),
  RouletteSegment(label: '2x', multiplier: 2, color: Color(0xFF3498DB)),
  RouletteSegment(label: '❌', multiplier: 0, color: Color(0xFFE74C3C)),
  RouletteSegment(label: '4x', multiplier: 4, color: Color(0xFF8E44AD)),
  RouletteSegment(label: '❌', multiplier: 0, color: Color(0xFFE74C3C)),
  RouletteSegment(label: '2x', multiplier: 2, color: Color(0xFFE67E22)),
  RouletteSegment(label: '🎯10x', multiplier: 10, color: Color(0xFFFFD700)),
  RouletteSegment(label: '❌', multiplier: 0, color: Color(0xFFE74C3C)),
  RouletteSegment(label: '3x', multiplier: 3, color: Color(0xFF1ABC9C)),
];

class RouletteWheelWidget extends StatefulWidget {
  final AnimationController animationController;
  final double targetRotation;
  final Duration spinDuration;

  const RouletteWheelWidget({
    super.key,
    required this.animationController,
    required this.targetRotation,
    required this.spinDuration,
  });

  @override
  State<RouletteWheelWidget> createState() => _RouletteWheelWidgetState();
}

class _RouletteWheelWidgetState extends State<RouletteWheelWidget> {
  late Animation<double> _rotationAnimation;
  CurvedAnimation? _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _curvedAnimation = CurvedAnimation(
      parent: widget.animationController,
      curve: Curves.easeOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: widget.targetRotation)
        .animate(_curvedAnimation!);
  }

  @override
  void didUpdateWidget(RouletteWheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetRotation != oldWidget.targetRotation) {
      final inicio = _rotationAnimation.value;
      _curvedAnimation?.dispose();
      _curvedAnimation = CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeOut,
      );
      _rotationAnimation = Tween<double>(
        begin: inicio,
        end: widget.targetRotation,
      ).animate(_curvedAnimation!);
      widget.animationController
        ..duration = widget.spinDuration
        ..forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _curvedAnimation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(300, 300),
              painter: _WheelPainter(rotation: _rotationAnimation.value),
            ),
            _buildPointer(),
            _buildCenterHub(),
          ],
        );
      },
    );
  }

  Widget _buildPointer() {
    return Positioned(
      top: 0,
      child: CustomPaint(
        size: const Size(30, 40),
        painter: _PointerPainter(),
      ),
    );
  }

  Widget _buildCenterHub() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold,
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(0, 4))
        ],
      ),
      child: const Center(
        child: Text('⭐', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final double rotation;

  const _WheelPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final numSegments = rouletteSegments.length;
    final sweepAngle = 2 * pi / numSegments;

    final borderPaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < numSegments; i++) {
      final startAngle = rotation + i * sweepAngle - pi / 2;
      final segment = rouletteSegments[i];

      final fillPaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        fillPaint,
      );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      _drawLabel(
          canvas, segment.label, center, radius, startAngle + sweepAngle / 2);
    }

    final outerRingPaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, outerRingPaint);
  }

  void _drawLabel(
      Canvas canvas, String text, Offset center, double radius, double angle) {
    final labelRadius = radius * 0.65;
    final x = center.dx + labelRadius * cos(angle);
    final y = center.dy + labelRadius * sin(angle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.nunito(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle + pi / 2);
    textPainter.paint(
        canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) => old.rotation != rotation;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => false;
}

// a roleta gira no sentido horário, então o segmento que fica no ponteiro
// é dado por (-rotação) mod (2π) — o sinal negativo é o pulo do gato
int getWinningSegment(double totalRotation) {
  final n = rouletteSegments.length;
  final sweep = 2 * pi / n;
  final norm = (-totalRotation) % (2 * pi);
  return ((norm / sweep).floor() % n).toInt();
}

// calcula quanto a roleta precisa girar a mais para parar no segmento certo
double getTargetRotation(int segAlvo, double rotacaoAtual,
    {int extraSpins = 5}) {
  final sweep = 2 * pi / rouletteSegments.length;
  final faseAtual = rotacaoAtual % (2 * pi);
  final faseAlvo = (-segAlvo * sweep - sweep / 2) % (2 * pi);
  final delta = (faseAlvo - faseAtual + 2 * pi) % (2 * pi);
  return extraSpins * 2 * pi + delta;
}
