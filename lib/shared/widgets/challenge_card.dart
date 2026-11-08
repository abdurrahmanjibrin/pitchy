import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';
import 'duo_card.dart';

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
        return 'Kata Wajib Acak';
      case 'random_theme':
        return 'Tema Pitch Acak';
      case 'audience_scenario':
        return 'Skenario Audiens';
      default:
        return 'Tantangan Pitching';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'random_words':
        return AppColors.purple;
      case 'random_theme':
        return AppColors.blue;
      case 'audience_scenario':
        return AppColors.orange;
      default:
        return AppColors.green;
    }
  }

  Color _getDifficultyColor(String diff) {
    switch (diff.toLowerCase()) {
      case 'easy':
        return AppColors.green;
      case 'hard':
        return AppColors.red;
      default:
        return AppColors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(challenge.type);
    final diffColor = _getDifficultyColor(challenge.difficulty);

    return DuoCard(
      padding: const EdgeInsets.all(18),
      bottomBorderColor: const Color(0xFFD6D6D6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with type & difficulty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _getTypeLabel(challenge.type),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: diffColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      challenge.difficulty.toUpperCase(),
                      style: TextStyle(
                        color: diffColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (showReroll && onReroll != null) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onReroll,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFD6D6D6)),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
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
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),

          // If Random Words
          if (challenge.requiredWords.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Kata Wajib yang Harus Kamu Sebutkan:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: challenge.requiredWords.map((word) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.yellowDark.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.yellowDark,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        word,
                        style: const TextStyle(
                          color: Color(0xFF4A3800),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E5E5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target: ${challenge.audienceProfile!['type'] ?? ''}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (challenge.audienceProfile!['focus'] != null)
                    Text(
                      '• Fokus: ${challenge.audienceProfile!['focus']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  if (challenge.audienceProfile!['convincer'] != null)
                    Text(
                      '• Hal Menarik: ${challenge.audienceProfile!['convincer']}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  if (challenge.audienceProfile!['goal'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '• Target Keberhasilan: ${challenge.audienceProfile!['goal']}',
                        style: const TextStyle(
                          color: AppColors.greenDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
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
