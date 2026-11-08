import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class ScoreBadge extends StatelessWidget {
  final double? score;
  final String label;
  final double size;
  final bool showLabel;

  const ScoreBadge({
    super.key,
    required this.score,
    this.label = 'Skor',
    this.size = 72,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Formatters.getScoreColor(score);
    final displayScore = score != null ? score!.toStringAsFixed(0) : '-';

    Color getDarkShade(Color c) {
      if (c == AppColors.green) return AppColors.greenDark;
      if (c == AppColors.yellow || c == AppColors.warning) {
        return AppColors.orangeDark;
      }
      if (c == AppColors.red || c == AppColors.error) return AppColors.redDark;
      return const Color(0xFFCCCCCC);
    }

    final darkShade = getDarkShade(color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: color, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: darkShade.withValues(alpha: 0.35),
                offset: const Offset(0, 3.5),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            displayScore,
            style: TextStyle(
              color: color,
              fontSize: size * 0.40,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
