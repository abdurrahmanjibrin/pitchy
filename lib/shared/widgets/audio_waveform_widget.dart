import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AudioWaveformWidget extends StatelessWidget {
  final double amplitude; // 0.0 to 1.0
  final bool isRecording;
  final bool isPaused;

  const AudioWaveformWidget({
    super.key,
    required this.amplitude,
    required this.isRecording,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 28;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          // Create wave shape offset
          final distanceToCenter = (index - barCount / 2).abs() / (barCount / 2);
          final baseHeight = 8.0;

          double barHeight;
          if (!isRecording || isPaused) {
            barHeight = baseHeight;
          } else {
            // Pseudo-random variations based on index and real amplitude
            final variance = ((index * 7) % 11) / 10.0;
            final dynamicAmp = (amplitude * (1.0 - distanceToCenter * 0.4) + variance * 0.2)
                .clamp(0.05, 1.0);
            barHeight = baseHeight + (dynamicAmp * 54.0);
          }

          final isCenter = distanceToCenter < 0.35;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: 4,
            height: barHeight,
            decoration: BoxDecoration(
              color: isPaused
                  ? AppColors.textMuted
                  : (isCenter ? AppColors.primaryLight : AppColors.secondary),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

