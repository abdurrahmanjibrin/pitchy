import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/vision/body_language_analyzer.dart';
import '../../../shared/widgets/duo_mascot_avatar.dart';

class BodyLanguageHudOverlay extends StatelessWidget {
  final BodyLanguageLiveFeedback feedback;
  final bool isFrontCamera;

  const BodyLanguageHudOverlay({
    super.key,
    required this.feedback,
    this.isFrontCamera = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Custom Painter for Strike Zone Guide and Hand Points
        CustomPaint(
          size: Size.infinite,
          painter: _StrikeZonePainter(
            feedback: feedback,
            isFrontCamera: isFrontCamera,
          ),
        ),

        // 2. Top 4-Dimension Duolingo Metric Badges
        Positioned(
          top: 68,
          left: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDimensionChip(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Postur',
                  value: feedback.isPostureOpen ? 'Bagus' : 'Bungkuk',
                  isGood: feedback.isPostureOpen,
                ),
                _buildDivider(),
                _buildDimensionChip(
                  icon: Icons.pan_tool_alt_rounded,
                  label: 'Strike Zone',
                  value: '${feedback.currentStrikeZoneRatio.toInt()}%',
                  isGood: feedback.inStrikeZone,
                ),
                _buildDivider(),
                _buildDimensionChip(
                  icon: Icons.anchor_rounded,
                  label: 'Kuda-kuda',
                  value: feedback.isAnchored ? 'Kokoh' : 'Goyang',
                  isGood: feedback.isAnchored,
                ),
                _buildDivider(),
                _buildDimensionChip(
                  icon: Icons.visibility_rounded,
                  label: 'Tatapan',
                  value: feedback.hasEyeContact ? 'Fokus' : 'Menunduk',
                  isGood: feedback.hasEyeContact,
                ),
              ],
            ),
          ),
        ),

        // 3. Floating Duolingo Mascot Active Coaching Pill (Center-Bottom)
        Positioned(
          bottom: 110,
          left: 18,
          right: 18,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: feedback.isPostureOpen && feedback.inStrikeZone
                    ? AppColors.green
                    : AppColors.orange,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white30, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: feedback.isPostureOpen && feedback.inStrikeZone
                        ? AppColors.greenDark
                        : AppColors.orangeDark,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DuoMascotAvatar(size: 28),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      feedback.primaryAlert,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isGood,
  }) {
    final statusColor = isGood ? AppColors.green : AppColors.yellow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 22,
      width: 1,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _StrikeZonePainter extends CustomPainter {
  final BodyLanguageLiveFeedback feedback;
  final bool isFrontCamera;

  _StrikeZonePainter({
    required this.feedback,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Duolingo Strike Zone Box (Chest to Hip, 45% - 85% width)
    final left = size.width * 0.15;
    final top = size.height * 0.35;
    final right = size.width * 0.85;
    final bottom = size.height * 0.75;
    final strikeRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(20),
    );

    // Guide Box Background & Border
    final isGood = feedback.inStrikeZone;
    final zoneColor = isGood ? AppColors.green : AppColors.yellow;

    final fillPaint = Paint()
      ..color = zoneColor.withValues(alpha: isGood ? 0.08 : 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(strikeRect, fillPaint);

    final borderPaint = Paint()
      ..color = zoneColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    _drawDashedRRect(canvas, strikeRect, borderPaint);

    // Text Label: "Duolingo Strike Zone"
    final textSpan = TextSpan(
      text: isGood ? '✓ STRIKE ZONE IDEAL' : 'AREA GESTUR TANGAN',
      style: TextStyle(
        color: zoneColor,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(left + 12, top + 10),
    );

    // Render Hand Points if detected
    final handPaint = Paint()
      ..color = isGood ? AppColors.green : AppColors.orange
      ..style = PaintingStyle.fill;

    final handBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    if (feedback.leftWristNormalized != null) {
      final point = _mapPoint(feedback.leftWristNormalized!, size);
      canvas.drawCircle(point, 9, handPaint);
      canvas.drawCircle(point, 9, handBorder);
    }

    if (feedback.rightWristNormalized != null) {
      final point = _mapPoint(feedback.rightWristNormalized!, size);
      canvas.drawCircle(point, 9, handPaint);
      canvas.drawCircle(point, 9, handBorder);
    }
  }

  Offset _mapPoint(Offset normalized, Size size) {
    // Camera coordinates mapping (front camera mirrored)
    double x = normalized.dx * size.width;
    double y = normalized.dy * size.height;

    if (isFrontCamera) {
      x = size.width - x;
    }
    return Offset(x, y);
  }

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint) {
    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0.0;
      const dashWidth = 8.0;
      const dashSpace = 5.0;

      while (distance < metric.length) {
        final len = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + len);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrikeZonePainter oldDelegate) {
    return oldDelegate.feedback != feedback;
  }
}
