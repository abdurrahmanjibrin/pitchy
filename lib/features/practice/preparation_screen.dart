import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../recording/recording_studio_screen.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  const PreparationScreen({super.key});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen> {
  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;

  @override
  void initState() {
    super.initState();
    final setup = ref.read(activePracticeSetupProvider);
    _totalSeconds = setup.preparationSeconds > 0
        ? setup.preparationSeconds
        : 30;
    _remainingSeconds = _totalSeconds;

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _goToRecording();
      }
    });
  }

  void _goToRecording() {
    _timer?.cancel();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RecordingStudioScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(activePracticeSetupProvider);
    final challenge = setup.selectedChallenge;
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Persiapan Pitching')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Circular Countdown Visual
              Expanded(
                flex: 4,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 170,
                        height: 170,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: AppColors.surfaceBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _remainingSeconds <= 5
                                ? AppColors.warning
                                : AppColors.primaryLight,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_remainingSeconds',
                            style: TextStyle(
                              color: _remainingSeconds <= 5
                                  ? AppColors.warning
                                  : AppColors.textPrimary,
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'detik tersisa',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Challenge Peek & Tips Card
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: AppColors.secondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tips Menyusun Alur Kilat',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Hook: Mulai dengan fakta atau pertanyaan menarik.\n'
                          '2. Masalah: Gambarkan kendala nyata yang dihadapi.\n'
                          '3. Solusi: Jelaskan idemu dan bagaimana cara kerjanya.\n'
                          '4. Manfaat: Berikan alasan kenapa solusi ini berdampak.\n'
                          '5. Call to action: Tutup dengan ajakan konkret.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        if (challenge != null &&
                            challenge.requiredWords.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Ingat Kata Wajib Kamu:',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: challenge.requiredWords.map((w) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  w,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Skip & Start Recording Now Button
              ElevatedButton.icon(
                onPressed: _goToRecording,
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Mulai Rekam Sekarang'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
