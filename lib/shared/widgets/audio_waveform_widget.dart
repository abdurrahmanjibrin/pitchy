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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE5E5E5),
            offset: Offset(0, 3.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (index) {
          final distanceToCenter =
              (index - barCount / 2).abs() / (barCount / 2);
          const baseHeight = 8.0;

          double barHeight;
          if (!isRecording || isPaused) {
            barHeight = baseHeight;
          } else {
            final variance = ((index * 7) % 11) / 10.0;
            final dynamicAmp =
                (amplitude * (1.0 - distanceToCenter * 0.4) + variance * 0.2)
                    .clamp(0.08, 1.0);
            barHeight = baseHeight + (dynamicAmp * 52.0);
          }

          final isCenter = distanceToCenter < 0.35;
          final color = isPaused
              ? const Color(0xFFD6D6D6)
              : (isCenter ? AppColors.blue : AppColors.secondaryLight);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutQuad,
            width: 4.5,
            height: barHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
