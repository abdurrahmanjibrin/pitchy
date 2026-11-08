import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuoCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color bottomBorderColor;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool isInteractive;

  const DuoCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE5E5E5),
    this.bottomBorderColor = const Color(0xFFE5E5E5),
    this.borderRadius = 18.0,
    this.borderWidth = 2.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.isInteractive = true,
  });

  @override
  State<DuoCard> createState() => _DuoCardState();
}

class _DuoCardState extends State<DuoCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final canTap = widget.onTap != null && widget.isInteractive;
    final double bottomOffset = _isPressed ? 1.0 : 3.5;
    final double topOffset = _isPressed ? 2.5 : 0.0;

    Color effectiveBg = widget.backgroundColor;
    if (_isHovered && canTap && !_isPressed) {
      effectiveBg = Color.lerp(widget.backgroundColor, const Color(0xFFF0F0F0), 0.3) ??
          widget.backgroundColor;
    }

    return Container(
      margin: widget.margin,
      child: MouseRegion(
        cursor: canTap ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) {
          if (mounted && canTap) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted && _isHovered) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTapDown: canTap
              ? (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _isPressed = true);
                }
              : null,
          onTapUp: canTap
              ? (_) {
                  setState(() => _isPressed = false);
                  widget.onTap?.call();
                }
              : null,
          onTapCancel: () {
            if (_isPressed) setState(() => _isPressed = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(top: topOffset, bottom: 3.5 - bottomOffset),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: effectiveBg,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isHovered && canTap
                    ? Color.lerp(widget.borderColor, Colors.black, 0.15)!
                    : widget.borderColor,
                width: widget.borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.bottomBorderColor,
                  offset: Offset(0, bottomOffset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
