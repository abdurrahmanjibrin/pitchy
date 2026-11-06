import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';
import '../../shared/widgets/challenge_card.dart';
import 'preparation_screen.dart';

class ChallengeBriefScreen extends ConsumerStatefulWidget {
  final ChallengeItem challenge;

  const ChallengeBriefScreen({super.key, required this.challenge});

  @override
  ConsumerState<ChallengeBriefScreen> createState() =>
      _ChallengeBriefScreenState();
}

class _ChallengeBriefScreenState extends ConsumerState<ChallengeBriefScreen> {
  late ChallengeItem _currentChallenge;
  bool _isRerolling = false;

  @override
  void initState() {
    super.initState();
    _currentChallenge = widget.challenge;
  }

  Future<void> _reroll() async {
    setState(() => _isRerolling = true);
    final service = ref.read(challengeServiceProvider);
    final newItem = await service.getRandomChallenge(
      type: _currentChallenge.type,
      excludeId: _currentChallenge.id,
    );

    // Update active practice state
    final currentSetup = ref.read(activePracticeSetupProvider);
    ref
        .read(activePracticeSetupProvider.notifier)
        .setSetup(currentSetup.copyWith(selectedChallenge: newItem));

    setState(() {
      _currentChallenge = newItem;
      _isRerolling = false;
    });
  }

  void _startPreparation() {
    final currentSetup = ref.read(activePracticeSetupProvider);
    ref
        .read(activePracticeSetupProvider.notifier)
        .setSetup(currentSetup.copyWith(selectedChallenge: _currentChallenge));

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PreparationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(activePracticeSetupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Brief Tantangan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tantangan akan dikunci setelah perekaman dimulai. Kamu dapat melihat brief ini kembali saat rekaman berlangsung.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Challenge Card
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isRerolling)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      else
                        ChallengeCard(
                          challenge: _currentChallenge,
                          onReroll: _reroll,
                          showReroll: true,
                        ),
                      const SizedBox(height: 20),

                      // Session parameters summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              icon: Icons.hourglass_top_rounded,
                              label: 'Waktu Persiapan',
                              value: '${setup.preparationSeconds} detik',
                            ),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              icon: Icons.timer_outlined,
                              label: 'Target Durasi Pitch',
                              value:
                                  '${(setup.targetDuration ?? 120) ~/ 60} menit',
                            ),
                            const Divider(height: 20),
                            _buildSummaryRow(
                              icon: Icons.mic_none_rounded,
                              label: 'Format Rekaman',
                              value: 'Audio Suara',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CTA Button
              ElevatedButton.icon(
                onPressed: _startPreparation,
                icon: const Icon(Icons.timer_rounded),
                label: const Text('Mulai Hitung Mundur Persiapan'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
