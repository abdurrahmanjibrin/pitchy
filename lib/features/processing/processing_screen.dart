import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/body_language_evaluation.dart';
import '../../data/models/practice_session.dart';
import '../../services/analysis/audio_metric_analyzer.dart';
import '../result/analysis_result_screen.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final int actualDurationSeconds;
  final BodyLanguageEvaluation? bodyLanguageEvaluation;

  const ProcessingScreen({
    super.key,
    required this.audioPath,
    required this.actualDurationSeconds,
    this.bodyLanguageEvaluation,
  });

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  int _currentStep = 0;
  String _currentStatusMessage = 'Menyiapkan berkas rekaman...';
  String? _errorMessage;
  bool _canRetry = false;

  final List<String> _stepTitles = [
    'Validasi Audio Rekaman',
    'Transkripsi Ucapan (Speech-to-Text)',
    'Analisis Metrik Penyampaian (WPM & Filler)',
    'Evaluasi Semantik & AI Coach',
    'Menyimpan Laporan Latihan',
  ];

  @override
  void initState() {
    super.initState();
    _executePipeline();
  }

  Future<void> _executePipeline() async {
    setState(() {
      _currentStep = 0;
      _currentStatusMessage = 'Membaca dan memverifikasi berkas suara...';
      _errorMessage = null;
      _canRetry = false;
    });

    final setup = ref.read(activePracticeSetupProvider);
    final sessionId = const Uuid().v4();

    try {
      // Step 1: File check
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() {
        _currentStep = 1;
        _currentStatusMessage =
            'Mengubah suara ke teks dalam Bahasa Indonesia...';
      });

      // Step 2: Speech-to-Text
      final sttService = ref.read(sttServiceProvider);
      String transcript = '';
      try {
        transcript = await sttService.transcribeAudio(
          audioFilePath: widget.audioPath,
          language: 'id',
          challengePrompt: setup.selectedChallenge?.prompt,
          requiredWords: setup.selectedChallenge?.requiredWords ?? [],
        );
      } catch (e) {
        // Check if user wants offline mock fallback or report error
        final userRepo = ref.read(userRepositoryProvider);
        if (userRepo.useLocalSttFallback()) {
          transcript = await ref
              .read(sttServiceProvider)
              .transcribeAudio(audioFilePath: widget.audioPath);
        } else {
          setState(() {
            _errorMessage =
                'Gagal melakukan transkripsi: ${e.toString().replaceAll("Exception: ", "")}\n\nPastikan koneksi internet stabil atau aktifkan Mode Offline di Profil & Pengaturan.';
            _canRetry = true;
          });
          return;
        }
      }

      // Step 3: Audio Metric Analysis (Pure Local Calculation)
      setState(() {
        _currentStep = 2;
        _currentStatusMessage =
            'Menghitung Words Per Minute (WPM) dan mendeteksi kata pengisi...';
      });
      await Future.delayed(const Duration(milliseconds: 700));

      final metrics = AudioMetricAnalyzer.analyze(
        transcript: transcript,
        actualDurationSeconds: widget.actualDurationSeconds,
        sessionId: sessionId,
      );

      // Step 4: AI Content Evaluation
      setState(() {
        _currentStep = 3;
        _currentStatusMessage = 'AI mengevaluasi kejelasan struktur, relevansi, dan bukti transkrip...';
      });

      PracticeSession partialSession = PracticeSession(
        id: sessionId,
        userId: ref.read(userRepositoryProvider).getUserName(),
        title: setup.title,
        topic: setup.topic,
        mode: setup.mode,
        challengeType: setup.challengeType,
        challengeId: setup.selectedChallenge?.id,
        challengePrompt: setup.selectedChallenge?.prompt,
        requiredWords: setup.selectedChallenge?.requiredWords ?? [],
        audienceProfile: setup.selectedChallenge?.audienceProfile,
        preparationSeconds: setup.preparationSeconds,
        targetDuration: setup.targetDuration,
        actualDuration: widget.actualDurationSeconds,
        recordingType: setup.recordingType,
        recordingPath: widget.audioPath,
        transcript: transcript,
        totalWords: metrics.totalWords,
        speakingPace: metrics.speakingPace,
        fillerCount: metrics.fillerCount,
        deliveryScore: metrics.deliveryScore,
        createdAt: DateTime.now(),
      );

      final aiEvaluator = ref.read(aiContentEvaluatorProvider);
      final evaluation = await aiEvaluator.evaluatePitch(
        session: partialSession,
        transcript: transcript,
      );

      // Calculate Content Score & Overall Score according to PRD Section 6.9 & 8.3
      double? contentScore;
      if (evaluation.sentenceClarityScore != null &&
          evaluation.coherenceScore != null &&
          evaluation.relevanceScore != null) {
        if (evaluation.audienceFitScore != null) {
          contentScore =
              (evaluation.sentenceClarityScore! * 0.35 +
                      evaluation.coherenceScore! * 0.35 +
                      evaluation.audienceFitScore! * 0.30)
                  .clamp(0, 100);
        } else {
          contentScore =
              (evaluation.sentenceClarityScore! * 0.50 +
                      evaluation.coherenceScore! * 0.50)
                  .clamp(0, 100);
        }
      }

      // Overall Score: 3-Pillar Scoring Architecture
      // Delivery (Vocal/WPM/Filler) + Body Language (Visual/Pose/Gesture) + Content (AI Semantics)
      double overallScore;
      final bodyScore = widget.bodyLanguageEvaluation?.overallScore;
      if (bodyScore != null && contentScore != null) {
        overallScore = ((metrics.deliveryScore * 0.35) +
                (bodyScore * 0.35) +
                (contentScore * 0.30))
            .clamp(0, 100);
      } else if (contentScore != null) {
        overallScore = ((metrics.deliveryScore * 0.40) + (contentScore * 0.60))
            .clamp(0, 100);
      } else if (bodyScore != null) {
        overallScore =
            ((metrics.deliveryScore * 0.50) + (bodyScore * 0.50)).clamp(0, 100);
      } else {
        overallScore = metrics.deliveryScore;
      }

      final summaryFeedback = evaluation.strengths.isNotEmpty
          ? evaluation.strengths.first
          : '';

      final completeSession = partialSession.copyWith(
        deliveryScore: double.parse(metrics.deliveryScore.toStringAsFixed(1)),
        bodyLanguageScore: bodyScore != null
            ? double.parse(bodyScore.toStringAsFixed(1))
            : null,
        bodyLanguageEvaluation: widget.bodyLanguageEvaluation,
        contentScore: contentScore != null
            ? double.parse(contentScore.toStringAsFixed(1))
            : null,
        overallScore: double.parse(overallScore.toStringAsFixed(1)),
        aiFeedback: summaryFeedback,
        evaluation: evaluation,
        fillerStats: metrics.fillerStats,
      );

      // Step 5: Save to SQLite
      setState(() {
        _currentStep = 4;
        _currentStatusMessage = 'Menyimpan laporan ke riwayat lokal...';
      });

      final practiceRepo = ref.read(practiceRepositoryProvider);
      await practiceRepo.saveSession(completeSession);

      // Invalidate dashboard and history providers so they refresh immediately
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(practiceHistoryProvider);
      ref.invalidate(progressDataProvider);

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              session: completeSession,
              isNewlyCreated: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan pemrosesan: $e';
          _canRetry = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Pulsing Core
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 28,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: _errorMessage != null
                      ? const Icon(
                          Icons.error_outline_rounded,
                          size: 44,
                          color: AppColors.error,
                        )
                      : const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: AppColors.secondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                _errorMessage != null
                    ? 'Pemrosesan Terkendala'
                    : 'Menganalisis Sesi Pitching',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? _currentStatusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _errorMessage != null
                      ? AppColors.error
                      : AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 36),

              // Step Progress List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: List.generate(_stepTitles.length, (index) {
                    final isDone = _currentStep > index;
                    final isCurrent =
                        _currentStep == index && _errorMessage == null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : (isCurrent
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded),
                            size: 18,
                            color: isDone
                                ? AppColors.success
                                : (isCurrent
                                      ? AppColors.secondary
                                      : AppColors.textMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _stepTitles[index],
                              style: TextStyle(
                                color: isDone || isCurrent
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(),

              if (_canRetry) ...[
                ElevatedButton.icon(
                  onPressed: _executePipeline,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Pratinjau'),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
