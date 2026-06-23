import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class KidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final EdgeInsets? padding;

  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.fontSize = 18,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final resolvedColor = enabled ? color : AppColors.neutral;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: resolvedColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
