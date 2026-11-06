import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeItem challenge;
  final VoidCallback? onReroll;
  final bool showReroll;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onReroll,
    this.showReroll = true,
  });

  String _getTypeLabel(String type) {
    switch (type) {
      case 'random_words':
        return 'Random Words Pitch';
      case 'random_theme':
        return 'Random Theme Pitch';
      case 'audience_scenario':
        return 'Audience Scenario Pitch';
      default:
        return 'Challenge Pitch';
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with type & difficulty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getTypeLabel(challenge.type),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(challenge.difficulty).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      challenge.difficulty,
                      style: TextStyle(
                        color: _getDifficultyColor(challenge.difficulty),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showReroll && onReroll != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: AppColors.secondary,
                      tooltip: 'Acak ulang tantangan',
                      onPressed: onReroll,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main prompt
          Text(
            challenge.prompt,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          // If Random Words
          if (challenge.requiredWords.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Kata Wajib yang Harus Diselipkan:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: challenge.requiredWords.map((word) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        word,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          // If Audience Scenario
          if (challenge.audienceProfile != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        'Target Audiens: ${challenge.audienceProfile!['type'] ?? ''}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (challenge.audienceProfile!['focus'] != null)
                    Text(
                      '• Fokus: ${challenge.audienceProfile!['focus']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  if (challenge.audienceProfile!['convincer'] != null)
                    Text(
                      '• Hal yang meyakinkan: ${challenge.audienceProfile!['convincer']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  if (challenge.audienceProfile!['goal'] != null)
                    Text(
                      '• Tujuan: ${challenge.audienceProfile!['goal']}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

