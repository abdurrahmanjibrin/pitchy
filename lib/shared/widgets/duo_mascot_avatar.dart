import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum MascotMood {
  happy,
  excited,
  thinking,
  encouraging,
}

class DuoMascotAvatar extends StatefulWidget {
  final String? speechText;
  final MascotMood mood;
  final double size;
  final bool animate;

  const DuoMascotAvatar({
    super.key,
    this.speechText,
    this.mood = MascotMood.happy,
    this.size = 80.0,
    this.animate = true,
  });

  @override
  State<DuoMascotAvatar> createState() => _DuoMascotAvatarState();
}

class _DuoMascotAvatarState extends State<DuoMascotAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // In widget tests, infinite repeat causes pumpAndSettle to time out
    final isTestEnvironment =
        WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
    if (widget.animate && !isTestEnvironment) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mascotWidget = AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
      child: _buildMascotBody(),
    );

    if (widget.speechText == null || widget.speechText!.isEmpty) {
      return mascotWidget;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mascotWidget,
        const SizedBox(width: 6),
        Expanded(
          child: _buildSpeechBubble(),
        ),
      ],
    );
  }

  Widget _buildMascotBody() {
    final s = widget.size;

    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greenDark, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.greenDark,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Belly patch (lighter green curved tummy)
          Positioned(
            bottom: 0,
            child: Container(
              width: s * 0.62,
              height: s * 0.40,
              decoration: const BoxDecoration(
                color: Color(0xFF89E219),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          // Cute rosy cheeks
          Positioned(
            top: s * 0.44,
            left: s * 0.08,
            child: Container(
              width: s * 0.16,
              height: s * 0.09,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9EA5).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Positioned(
            top: s * 0.44,
            right: s * 0.08,
            child: Container(
              width: s * 0.16,
              height: s * 0.09,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9EA5).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: s * 0.18,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(),
                SizedBox(width: s * 0.06),
                _buildEye(),
              ],
            ),
          ),
          // Beak
          Positioned(
            top: s * 0.42,
            child: Container(
              width: s * 0.24,
              height: s * 0.16,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.orangeDark, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.orangeDark,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          // Mic badge
          Positioned(
            bottom: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.blueDark, width: 1.2),
              ),
              child: const Icon(
                Icons.mic,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    final eyeSize = widget.size * 0.30;
    return Container(
      width: eyeSize,
      height: eyeSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3C3C3C), width: 1.5),
      ),
      child: Center(
        child: Container(
          width: eyeSize * 0.58,
          height: eyeSize * 0.58,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
          child: Align(
            alignment: const Alignment(0.4, -0.4),
            child: Container(
              width: eyeSize * 0.22,
              height: eyeSize * 0.22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechBubble() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 2.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFE5E5E5),
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.speechText ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ),
        // Triangle tail pointer
        Positioned(
          left: 0,
          child: CustomPaint(
            size: const Size(9, 12),
            painter: _BubbleTailPainter(),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
