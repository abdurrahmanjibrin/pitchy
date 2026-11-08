import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../recording/recording_studio_screen.dart';

class PreparationScreen extends ConsumerStatefulWidget {
  const PreparationScreen({super.key});

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late int _remainingSeconds;
  late int _totalSeconds;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final setup = ref.read(activePracticeSetupProvider);
    _totalSeconds = setup.preparationSeconds > 0
        ? setup.preparationSeconds
        : 30;
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 3) {
          HapticFeedback.mediumImpact();
        }
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
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(activePracticeSetupProvider);
    final challenge = setup.selectedChallenge;
    final progress = _totalSeconds > 0
        ? (_totalSeconds - _remainingSeconds) / _totalSeconds
        : 1.0;

    final isUrgent = _remainingSeconds <= 5;
    final ringColor = isUrgent ? AppColors.red : AppColors.green;
    final ringDark = isUrgent ? AppColors.redDark : AppColors.greenDark;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('PERSIAPAN PITCHING')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Mascot encouragement
              DuoMascotAvatar(
                speechText: isUrgent
                    ? 'Waktu hampir habis! Tarik nafas dalam-dalam...'
                    : 'Susun alur pitch di kepalamu. Kamu pasti bisa!',
                size: 64,
              ),
              const SizedBox(height: 16),

              // Circular Countdown Visual (Duolingo 3D Chunky Ring)
              Expanded(
                flex: 4,
                child: Center(
                  child: ScaleTransition(
                    scale: isUrgent ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 12,
                            backgroundColor: const Color(0xFFE5E5E5),
                            valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                          ),
                        ),
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: ringColor, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: ringDark.withValues(alpha: 0.25),
                                offset: const Offset(0, 4),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_remainingSeconds',
                                style: TextStyle(
                                  color: ringColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                'DETIK',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tips Card
              Expanded(
                flex: 5,
                child: DuoCard(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              color: AppColors.yellow,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Struktur Pitch Kilat (5 Langkah)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. Hook: Pancing rasa penasaran audiens.\n'
                          '2. Masalah: Ceritakan kendala nyata di lapangan.\n'
                          '3. Solusi: Perkenalkan ide/produk unggulanmu.\n'
                          '4. Dampak: Bukti manfaat langsung yang dirasakan.\n'
                          '5. Call to Action: Ajak mereka bertindak sekarang!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (challenge != null &&
                            challenge.requiredWords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 6),
                          const Text(
                            'KATA WAJIB KAMU:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
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
                                  color: AppColors.yellowSoft,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.yellowDark.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  w,
                                  style: const TextStyle(
                                    color: Color(0xFF4A3800),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
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

              const SizedBox(height: 16),

              // Skip & Start Recording Now Button (Duolingo 3D Tactile Button)
              DuoButton(
                text: 'MULAI REKAM SEKARANG',
                icon: Icons.mic_rounded,
                color: DuoButtonColor.green,
                onPressed: _goToRecording,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
