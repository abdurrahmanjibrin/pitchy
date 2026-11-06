import 'package:flutter/material.dart';
import '../../../services/vision/body_language_analyzer.dart';

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

        // 2. Top 4-Dimension Metric Badges
        Positioned(
          top: 70,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDimensionChip(
                  icon: Icons.accessibility_new_rounded,
                  label: 'Postur',
                  value: feedback.isPostureOpen ? 'Terbuka' : 'Perbaiki',
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
                  value: feedback.isAnchored ? 'Stabil' : 'Pacing',
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

        // 3. Floating Active Coaching Pill (Center-Bottom)
        Positioned(
          bottom: 120,
          left: 24,
          right: 24,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: feedback.primaryAlertColor.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: feedback.primaryAlertColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    feedback.isPostureOpen && feedback.inStrikeZone
                        ? Icons.check_circle_rounded
                        : Icons.lightbulb_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      feedback.primaryAlert,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
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
    final statusColor = isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white.withValues(alpha: 0.15),
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
    // If a strike zone is detected from pose, render bounding box
    final rectNorm = feedback.strikeZoneNormalized;
    if (rectNorm == null) return;

    double left = rectNorm.left * size.width;
    double right = rectNorm.right * size.width;
    double top = rectNorm.top * size.height;
    double bottom = rectNorm.bottom * size.height;

    // Front camera is horizontally mirrored in preview
    if (isFrontCamera) {
      final tempLeft = size.width - right;
      final tempRight = size.width - left;
      left = tempLeft;
      right = tempRight;
    }

    final strikeRect = Rect.fromLTRB(left, top, right, bottom);

    // Box background glow
    final bgPaint = Paint()
      ..color = (feedback.inStrikeZone
              ? const Color(0xFF10B981)
              : const Color(0xFF06B6D4))
          .withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(strikeRect, const Radius.circular(16)),
      bgPaint,
    );

    // Box border (dashed or elegant viewfinder brackets)
    final borderPaint = Paint()
      ..color = (feedback.inStrikeZone
              ? const Color(0xFF10B981)
              : const Color(0xFF06B6D4))
          .withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(strikeRect, const Radius.circular(16)),
      borderPaint,
    );

    // Corner brackets
    final cornerLength = (strikeRect.width * 0.18).clamp(16.0, 32.0);
    final cornerPaint = Paint()
      ..color = feedback.inStrikeZone
          ? const Color(0xFF10B981)
          : const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    // Top-left
    canvas.drawLine(strikeRect.topLeft, strikeRect.topLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(strikeRect.topLeft, strikeRect.topLeft + Offset(0, cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(strikeRect.topRight, strikeRect.topRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(strikeRect.topRight, strikeRect.topRight + Offset(0, cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(strikeRect.bottomLeft, strikeRect.bottomLeft + Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(strikeRect.bottomLeft, strikeRect.bottomLeft + Offset(0, -cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(strikeRect.bottomRight, strikeRect.bottomRight + Offset(-cornerLength, 0), cornerPaint);
    canvas.drawLine(strikeRect.bottomRight, strikeRect.bottomRight + Offset(0, -cornerLength), cornerPaint);

    // Draw label
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    );
    final textSpan = TextSpan(
      text: 'STRIKE ZONE (Dada - Pinggang)',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(strikeRect.left + 12, strikeRect.top + 8),
    );

    // Draw wrists if detected
    _drawWrist(canvas, size, feedback.leftWristNormalized);
    _drawWrist(canvas, size, feedback.rightWristNormalized);
  }

  void _drawWrist(Canvas canvas, Size size, Offset? wristNorm) {
    if (wristNorm == null) return;
    double x = wristNorm.dx * size.width;
    double y = wristNorm.dy * size.height;

    if (isFrontCamera) {
      x = size.width - x;
    }

    final wristPoint = Offset(x, y);

    final dotGlow = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(wristPoint, 10, dotGlow);

    final dotCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(wristPoint, 4, dotCore);
  }

  @override
  bool shouldRepaint(covariant _StrikeZonePainter oldDelegate) {
    return oldDelegate.feedback != feedback;
  }
}
