import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

enum DuoButtonColor {
  green,
  blue,
  yellow,
  purple,
  red,
  white,
}

typedef DuoButtonVariant = DuoButtonColor;

class DuoButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DuoButtonColor color;
  final bool isFullWidth;
  final double height;
  final double? fontSize;
  final bool isLoading;

  const DuoButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    DuoButtonColor? color,
    DuoButtonColor? variant,
    this.isFullWidth = true,
    this.height = 52.0,
    this.fontSize,
    this.isLoading = false,
  }) : color = variant ?? color ?? DuoButtonColor.green;

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  (Color bg, Color borderBottom, Color textColor) _getColors() {
    switch (widget.color) {
      case DuoButtonColor.green:
        return (AppColors.green, AppColors.greenDark, Colors.white);
      case DuoButtonColor.blue:
        return (AppColors.blue, AppColors.blueDark, Colors.white);
      case DuoButtonColor.yellow:
        return (AppColors.yellow, AppColors.yellowDark, const Color(0xFF4A3800));
      case DuoButtonColor.purple:
        return (AppColors.purple, AppColors.purpleDark, Colors.white);
      case DuoButtonColor.red:
        return (AppColors.red, AppColors.redDark, Colors.white);
      case DuoButtonColor.white:
        return (Colors.white, const Color(0xFFE0E0E0), AppColors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, borderBottom, textColor) = _getColors();
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final bgColor = isEnabled ? bg : const Color(0xFFE5E5E5);
    final shadowColor = isEnabled ? borderBottom : const Color(0xFFCCCCCC);
    final effectiveTextColor = isEnabled ? textColor : const Color(0xFFAFAFAF);

    final double bottomOffset = _isPressed ? 1.0 : 4.0;
    final double topMargin = _isPressed ? 3.0 : 0.0;

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: () {
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: topMargin, bottom: 4.0 - bottomOffset),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.color == DuoButtonColor.white
                ? const Color(0xFFE5E5E5)
                : Colors.white.withValues(alpha: 0.20),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, bottomOffset),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: effectiveTextColor,
                      size: (widget.fontSize ?? 15) + 4,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: widget.fontSize ?? 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
