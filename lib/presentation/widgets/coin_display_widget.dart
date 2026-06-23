import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/user_provider.dart';

class CoinDisplayWidget extends StatelessWidget {
  const CoinDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<UserProvider>().coins;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.goldDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 0, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            _formatCoins(coins),
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatCoins(int coins) {
    if (coins >= 1000000) return '${(coins / 1000000).toStringAsFixed(1)}M';
    if (coins >= 1000) return '${(coins / 1000).toStringAsFixed(1)}K';
    return coins.toString();
  }
}
