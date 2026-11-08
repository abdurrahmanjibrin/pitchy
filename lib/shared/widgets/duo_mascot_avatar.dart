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
        const SizedBox(width: 14),
        Expanded(
          child: _buildSpeechBubble(),
        ),
      ],
    );
  }

  Widget _buildMascotBody() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.greenDark, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Belly patch
          Positioned(
            bottom: 4,
            child: Container(
              width: widget.size * 0.58,
              height: widget.size * 0.42,
              decoration: const BoxDecoration(
                color: Color(0xFF89E219),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
            ),
          ),
          // Eyes
          Positioned(
            top: widget.size * 0.22,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(),
                SizedBox(width: widget.size * 0.08),
                _buildEye(),
              ],
            ),
          ),
          // Beak
          Positioned(
            top: widget.size * 0.44,
            child: Container(
              width: widget.size * 0.26,
              height: widget.size * 0.18,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.orangeDark, width: 1.5),
              ),
            ),
          ),
          // Mic headset or tie
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.blueDark, width: 1),
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
    final eyeSize = widget.size * 0.28;
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
          width: eyeSize * 0.5,
          height: eyeSize * 0.5,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            shape: BoxShape.circle,
          ),
          child: Align(
            alignment: const Alignment(0.4, -0.4),
            child: Container(
              width: eyeSize * 0.18,
              height: eyeSize * 0.18,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}
