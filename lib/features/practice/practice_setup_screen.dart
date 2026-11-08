import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import 'challenge_brief_screen.dart';
import 'preparation_screen.dart';

class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({super.key});

  @override
  ConsumerState<PracticeSetupScreen> createState() =>
      _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController(
    text: 'Latihan Pitching Mandiri',
  );
  final _topicController = TextEditingController();

  String _mode = 'challenge'; // 'free', 'timed', 'challenge'
  String _challengeType =
      'random_words'; // 'random_words', 'random_theme', 'audience_scenario'
  int _preparationSeconds = 30;
  int _targetDurationSeconds = 120; // 2 min
  String _recordingType = 'video'; // 'video' (with body language), 'audio'

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _onProceed() async {
    if (!_formKey.currentState!.validate()) return;

    final challengeService = ref.read(challengeServiceProvider);

    ChallengeItem? selectedChallenge;
    if (_mode == 'challenge') {
      selectedChallenge = await challengeService.getRandomChallenge(
        type: _challengeType,
      );
    }

    ref.read(activePracticeSetupProvider.notifier).setSetup(
          ActivePracticeSetup(
            title: _titleController.text.trim(),
            topic: _topicController.text.trim().isNotEmpty
                ? _topicController.text.trim()
                : null,
            mode: _mode,
            challengeType: _mode == 'challenge' ? _challengeType : null,
            selectedChallenge: selectedChallenge,
            preparationSeconds: _preparationSeconds,
            targetDuration: _targetDurationSeconds,
            recordingType: _recordingType,
          ),
        );

    if (!mounted) return;

    if (_mode == 'challenge' && selectedChallenge != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeBriefScreen(challenge: selectedChallenge!),
        ),
      );
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PreparationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PENGATURAN LATIHAN')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Title Field
              const Text(
                'JUDUL SESI LATIHAN',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Misal: Latihan Pitching Startup',
                  prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.blue),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul latihan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),

              // Mode Practice Selection
              const Text(
                'PILIH MODE LATIHAN',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Tantangan',
                      isSelected: _mode == 'challenge',
                      onTap: () => setState(() => _mode = 'challenge'),
                      icon: Icons.bolt_rounded,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Bebas',
                      isSelected: _mode == 'free',
                      onTap: () => setState(() => _mode = 'free'),
                      icon: Icons.mic_none_rounded,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Target Waktu',
                      isSelected: _mode == 'timed',
                      onTap: () => setState(() => _mode = 'timed'),
                      icon: Icons.timer_outlined,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Specific Challenge Types
              if (_mode == 'challenge') ...[
                const Text(
                  'JENIS TANTANGAN SPONTAN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'random_words',
                  title: 'Kata Wajib Acak',
                  desc: 'Selipkan 3–5 kata tak terduga secara alami ke dalam argumen pitch.',
                  icon: Icons.spellcheck_rounded,
                  color: AppColors.purple,
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'random_theme',
                  title: 'Tema Pitch Acak',
                  desc: 'Dapatkan tema/masalah mendadak dan bangun solusi dalam hitungan detik.',
                  icon: Icons.lightbulb_rounded,
                  color: AppColors.blue,
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'audience_scenario',
                  title: 'Skenario Audiens Tertentu',
                  desc: 'Sesuaikan nada bicaramu dengan Investor, Dosen Penguji, atau Mahasiswa Baru.',
                  icon: Icons.groups_rounded,
                  color: AppColors.orange,
                ),
                const SizedBox(height: 22),
              ],

              // Preparation Duration
              const Text(
                'WAKTU PERSIAPAN SEBELUM BICARA',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.prepDurations.map((sec) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildChoiceChip(
                        label: '$sec dtk',
                        isSelected: _preparationSeconds == sec,
                        onTap: () => setState(() => _preparationSeconds = sec),
                        color: AppColors.blue,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Target Pitch Duration
              const Text(
                'TARGET DURASI PITCH',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.practiceDurations.map((sec) {
                  final min = sec ~/ 60;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildChoiceChip(
                        label: '$min menit',
                        isSelected: _targetDurationSeconds == sec,
                        onTap: () =>
                            setState(() => _targetDurationSeconds = sec),
                        color: AppColors.green,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // Recording Format (Audio vs Video + Body Language)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'FORMAT SESI REKAMAN',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.greenSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.green, width: 1.5),
                    ),
                    child: const Text(
                      'AI ON-DEVICE',
                      style: TextStyle(
                        color: AppColors.greenDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFormatCard(
                      type: 'video',
                      title: 'Video + AI Kamera',
                      subtitle: 'Analisis postur, gestur, kuda-kuda & tatapan',
                      icon: Icons.videocam_rounded,
                      isRecommended: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFormatCard(
                      type: 'audio',
                      title: 'Audio Saja',
                      subtitle: 'Fokus vokal, WPM & kata pengisi',
                      icon: Icons.mic_rounded,
                      isRecommended: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Next Button (Duolingo 3D Tactile Button)
              DuoButton(
                text: _mode == 'challenge'
                    ? 'BUKA BRIEF TANTANGAN'
                    : 'MULAI PERSIAPAN',
                icon: Icons.arrow_forward_rounded,
                color: DuoButtonColor.green,
                onPressed: _onProceed,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color color = AppColors.green,
  }) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      backgroundColor: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
      borderColor: isSelected ? color : const Color(0xFFE5E5E5),
      bottomBorderColor: isSelected ? color : const Color(0xFFE5E5E5),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTypeCard({
    required String type,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _challengeType == type;

    return DuoCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
      borderColor: isSelected ? color : const Color(0xFFE5E5E5),
      bottomBorderColor: isSelected ? color : const Color(0xFFE5E5E5),
      onTap: () => setState(() => _challengeType = type),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : const Color(0xFFCCCCCC),
                width: 2.5,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRecommended,
  }) {
    final isSelected = _recordingType == type;
    final color = isSelected ? AppColors.green : const Color(0xFFAFAFAF);

    return DuoCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: isSelected ? AppColors.greenSoft.withValues(alpha: 0.5) : Colors.white,
      borderColor: isSelected ? AppColors.green : const Color(0xFFE5E5E5),
      bottomBorderColor: isSelected ? AppColors.greenDark : const Color(0xFFE5E5E5),
      onTap: () => setState(() => _recordingType = type),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.greenSoft : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.yellowDark, width: 1),
                  ),
                  child: const Text(
                    'AI COACH',
                    style: TextStyle(
                      color: Color(0xFF4A3800),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? AppColors.greenDark : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
