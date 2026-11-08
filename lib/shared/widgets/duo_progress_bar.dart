import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DuoProgressBar extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final Color fillColor;
  final Color trackColor;
  final double height;
  final Duration animationDuration;

  const DuoProgressBar({
    super.key,
    double? value,
    double? progress,
    Color? fillColor,
    Color? progressColor,
    this.trackColor = const Color(0xFFE5E5E5),
    this.height = 14.0,
    this.animationDuration = const Duration(milliseconds: 600),
  })  : value = value ?? progress ?? 0.0,
        fillColor = progressColor ?? fillColor ?? AppColors.green;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final targetWidth = constraints.maxWidth * clampedValue;

          return Stack(
            children: [
              // Animated Fill Bar
              AnimatedContainer(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                width: targetWidth,
                height: height,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: Stack(
                  children: [
                    // Top Glossy highlight strip
                    Positioned(
                      top: 2,
                      left: 6,
                      right: 6,
                      height: (height / 2) - 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(height),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

