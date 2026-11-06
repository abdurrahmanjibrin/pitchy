import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/challenge_item.dart';
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
  final _titleController =
      TextEditingController(text: 'Latihan Pitching Mandiri');
  final _topicController = TextEditingController();

  String _mode = 'challenge'; // 'free', 'timed', 'challenge'
  String _challengeType =
      'random_words'; // 'random_words', 'random_theme', 'audience_scenario'
  int _preparationSeconds = 30;
  int _targetDurationSeconds = 120; // 2 min
  String _recordingType = 'audio';

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

    ref.read(activePracticeSetupProvider.notifier).setSetup(ActivePracticeSetup(
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
    ));

    if (!mounted) return;

    if (_mode == 'challenge' && selectedChallenge != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeBriefScreen(challenge: selectedChallenge!),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PreparationScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Latihan'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Title Field
              const Text(
                'Judul Latihan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Judul minimal 3 karakter';
                  }
                  if (val.trim().length > 60) {
                    return 'Judul maksimal 60 karakter';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'Contoh: Pitching Startup Inovasi',
                  prefixIcon: Icon(Icons.title_rounded, color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: 20),

              // Topic Field (Optional)
              const Text(
                'Topik / Konteks (Opsional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Pengelolaan sampah cerdas di fakultas',
                  prefixIcon:
                      Icon(Icons.category_outlined, color: AppColors.secondary),
                ),
              ),
              const SizedBox(height: 24),

              // Practice Mode Selector
              const Text(
                'Pilih Mode Latihan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Challenge',
                      isSelected: _mode == 'challenge',
                      onTap: () => setState(() => _mode = 'challenge'),
                      icon: Icons.bolt_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Bebas',
                      isSelected: _mode == 'free',
                      onTap: () => setState(() => _mode = 'free'),
                      icon: Icons.mic_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Target Waktu',
                      isSelected: _mode == 'timed',
                      onTap: () => setState(() => _mode = 'timed'),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Challenge Subtype (if mode == challenge)
              if (_mode == 'challenge') ...[
                const Text(
                  'Tipe Tantangan Pitching',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'random_words',
                  title: 'Random Words Pitch',
                  desc: 'Selipkan 3–5 kata acak yang wajib digunakan secara alami.',
                  icon: Icons.text_fields_rounded,
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'random_theme',
                  title: 'Random Theme Pitch',
                  desc: 'Hadapi masalah/tema spontan dengan instruksi terarah.',
                  icon: Icons.lightbulb_outline_rounded,
                ),
                const SizedBox(height: 10),
                _buildChallengeTypeCard(
                  type: 'audience_scenario',
                  title: 'Audience Scenario Pitch',
                  desc: 'Sesuaikan bahasa dan penekanan ide sesuai profil audiens.',
                  icon: Icons.people_outline_rounded,
                ),
                const SizedBox(height: 24),
              ],

              // Preparation Time Selector
              const Text(
                'Waktu Persiapan Sebelum Rekam',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: AppConstants.prepDurations.map((sec) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildChoiceChip(
                        label: '$sec detik',
                        isSelected: _preparationSeconds == sec,
                        onTap: () => setState(() => _preparationSeconds = sec),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Target Pitch Duration
              const Text(
                'Target Durasi Pitch',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
                        onTap: () => setState(() => _targetDurationSeconds = sec),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Next Button
              ElevatedButton.icon(
                onPressed: _onProceed,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(_mode == 'challenge'
                    ? 'Buka Brief Tantangan'
                    : 'Mulai Persiapan'),
              ),
              const SizedBox(height: 24),
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
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.secondary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeTypeCard({
    required String type,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _challengeType == type;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _challengeType = type),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.secondary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: type,
              groupValue: _challengeType,
              activeColor: AppColors.primary,
              onChanged: (val) {
                if (val != null) setState(() => _challengeType = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
