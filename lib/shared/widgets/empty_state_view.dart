import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'duo_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenDark.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, size: 44, color: AppColors.greenDark),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              DuoButton(
                text: buttonText!,
                icon: Icons.add_rounded,
                onPressed: onAction,
                color: DuoButtonColor.green,
                isFullWidth: false,
                height: 48,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
