import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/card_deck.dart';

class PlayingCardWidget extends StatelessWidget {
  final PlayingCard card;
  final double width;
  final double height;

  const PlayingCardWidget({
    super.key,
    required this.card,
    this.width = 70,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: card.isFaceDown ? const Color(0xFF1E3A5F) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(2, 4))],
      ),
      child: card.isFaceDown ? _buildCardBack() : _buildCardFront(),
    ).animate().scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildCardBack() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2540),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F), width: 3),
      ),
      child: Center(
        child: Text(
          '★',
          style: TextStyle(fontSize: 32, color: AppColors.gold.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    final color = card.isRed ? AppColors.suitRed : AppColors.suitBlack;
    final style = GoogleFonts.nunito(
      color: color,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.rankLabel, style: style.copyWith(fontSize: 16)),
              Text(card.suitSymbol, style: style.copyWith(fontSize: 14)),
            ],
          ),
          Center(
            child: Text(card.suitSymbol, style: style.copyWith(fontSize: 28)),
          ),
          RotatedBox(
            quarterTurns: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.rankLabel, style: style.copyWith(fontSize: 16)),
                Text(card.suitSymbol, style: style.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
