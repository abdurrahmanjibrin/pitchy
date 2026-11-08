import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';
import '../../shared/widgets/challenge_card.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('BRIEF TANTANGAN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header note with friendly Duolingo style
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: AppColors.blueDark,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pelajari tantangan di bawah! Brief ini tetap bisa kamu buka saat rekaman berlangsung.',
                        style: TextStyle(
                          color: AppColors.blueDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Challenge Card & Summary
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (_isRerolling)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: AppColors.green,
                            ),
                          ),
                        )
                      else
                        ChallengeCard(
                          challenge: _currentChallenge,
                          onReroll: _reroll,
                          showReroll: true,
                        ),
                      const SizedBox(height: 16),

                      // Session parameters summary
                      DuoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              icon: Icons.hourglass_top_rounded,
                              label: 'Waktu Persiapan',
                              value: '${setup.preparationSeconds} detik',
                              color: AppColors.blue,
                            ),
                            const Divider(height: 22),
                            _buildSummaryRow(
                              icon: Icons.timer_rounded,
                              label: 'Target Durasi Pitch',
                              value:
                                  '${(setup.targetDuration ?? 120) ~/ 60} menit',
                              color: AppColors.green,
                            ),
                            const Divider(height: 22),
                            _buildSummaryRow(
                              icon: setup.recordingType == 'video'
                                  ? Icons.videocam_rounded
                                  : Icons.mic_rounded,
                              label: 'Format Rekaman',
                              value: setup.recordingType == 'video'
                                  ? 'Video + AI Kamera'
                                  : 'Audio Suara',
                              color: AppColors.purple,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CTA Button (Duolingo 3D Tactile Button)
              DuoButton(
                text: 'MULAI HITUNG MUNDUR',
                icon: Icons.timer_rounded,
                color: DuoButtonColor.green,
                onPressed: _startPreparation,
              ),
              const SizedBox(height: 8),
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
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
