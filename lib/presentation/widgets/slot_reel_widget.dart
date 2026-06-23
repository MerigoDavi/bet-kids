import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

const slotSymbols = ['🍎', '🍋', '🍇', '🍒', '⭐', '💎'];

class SlotReelWidget extends StatefulWidget {
  final int targetIndex;
  final bool isSpinning;
  final Duration stopDelay;
  final VoidCallback? onStopped;

  const SlotReelWidget({
    super.key,
    required this.targetIndex,
    required this.isSpinning,
    this.stopDelay = Duration.zero,
    this.onStopped,
  });

  @override
  State<SlotReelWidget> createState() => SlotReelWidgetState();
}

class SlotReelWidgetState extends State<SlotReelWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayIndex = 0;
  Timer? _spinTimer;
  Timer? _stopTimer;
  bool _stopped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _displayIndex = Random().nextInt(slotSymbols.length);
  }

  @override
  void didUpdateWidget(SlotReelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSpinning && !oldWidget.isSpinning) {
      _startSpinning();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _scheduleStop();
    }
  }

  void _startSpinning() {
    _stopped = false;
    _spinTimer?.cancel();
    _spinTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!_stopped) {
        setState(() => _displayIndex = (_displayIndex + 1) % slotSymbols.length);
      }
    });
  }

  void _scheduleStop() {
    _stopTimer = Timer(widget.stopDelay, () {
      _stopped = true;
      _spinTimer?.cancel();
      setState(() => _displayIndex = widget.targetIndex % slotSymbols.length);
      widget.onStopped?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spinTimer?.cancel();
    _stopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 60),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: Center(
            key: ValueKey(_displayIndex),
            child: Text(
              slotSymbols[_displayIndex],
              style: const TextStyle(fontSize: 52),
            ),
          ),
        ),
      ),
    );
  }

  String get currentSymbol => slotSymbols[_displayIndex];
}

Map<String, int> calculateSlotPayout(List<String> symbols, int bet) {
  final a = symbols[0];
  final b = symbols[1];
  final c = symbols[2];

  if (a == b && b == c) {
    final multiplier = switch (a) {
      '💎' => 50,
      '⭐' => 20,
      '🍒' => 10,
      '🍇' => 8,
      '🍋' => 5,
      _ => 4,
    };
    return {'payout': bet * multiplier, 'multiplier': multiplier};
  }

  if (a == b || b == c || a == c) {
    return {'payout': bet * 2, 'multiplier': 2};
  }

  return {'payout': 0, 'multiplier': 0};
}
