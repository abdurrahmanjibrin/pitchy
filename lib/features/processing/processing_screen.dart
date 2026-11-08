import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/body_language_evaluation.dart';
import '../../data/models/practice_session.dart';
import '../../services/analysis/audio_metric_analyzer.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../../shared/widgets/duo_progress_bar.dart';
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
        _currentStatusMessage =
            'AI mengevaluasi kejelasan struktur, relevansi, dan bukti transkrip...';
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

      // Calculate Content Score & Overall Score according to PRD
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

      double? finalOverallScore;
      if (contentScore != null) {
        if (widget.bodyLanguageEvaluation != null) {
          finalOverallScore =
              (metrics.deliveryScore * 0.40 +
                      contentScore * 0.35 +
                      widget.bodyLanguageEvaluation!.overallScore * 0.25)
                  .clamp(0, 100);
        } else {
          finalOverallScore =
              (metrics.deliveryScore * 0.50 + contentScore * 0.50)
                  .clamp(0, 100);
        }
      } else {
        finalOverallScore = metrics.deliveryScore;
      }

      final completeSession = partialSession.copyWith(
        contentScore: contentScore,
        overallScore: finalOverallScore,
        bodyLanguageScore: widget.bodyLanguageEvaluation?.overallScore,
        bodyLanguageEvaluation: widget.bodyLanguageEvaluation,
        evaluation: evaluation,
      );

      // Step 5: Save to SQLite
      setState(() {
        _currentStep = 4;
        _currentStatusMessage = 'Menyimpan laporan ke riwayat lokal...';
      });

      final practiceRepo = ref.read(practiceRepositoryProvider);
      await practiceRepo.saveSession(completeSession);

      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(practiceHistoryProvider);
      ref.invalidate(progressDataProvider);

      await Future.delayed(const Duration(milliseconds: 600));

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
    final progress = (_currentStep + 1) / _stepTitles.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Duolingo Progress Bar
              DuoProgressBar(
                progress: _errorMessage != null ? 0.2 : progress,
                progressColor: _errorMessage != null ? AppColors.red : AppColors.green,
                height: 12,
              ),
              const Spacer(),

              // Animated Mascot
              DuoMascotAvatar(
                size: 96,
                speechText: _errorMessage != null
                    ? 'Oops! Ada sedikit kendala saat memproses.'
                    : 'Pitchy sedang mendengarkan dan menganalisis bicaramu!',
              ),
              const SizedBox(height: 24),

              Text(
                _errorMessage != null
                    ? 'Pemrosesan Terkendala'
                    : 'Menganalisis Pitching...',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? _currentStatusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _errorMessage != null
                      ? AppColors.red
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Step Progress List inside a DuoCard
              DuoCard(
                child: Column(
                  children: List.generate(_stepTitles.length, (index) {
                    final isDone = _currentStep > index;
                    final isCurrent =
                        _currentStep == index && _errorMessage == null;

                    Color circleColor;
                    Widget iconWidget;

                    if (isDone) {
                      circleColor = AppColors.green;
                      iconWidget = const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      );
                    } else if (isCurrent) {
                      circleColor = AppColors.blue;
                      iconWidget = const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    } else {
                      circleColor = AppColors.border;
                      iconWidget = const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: circleColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(child: iconWidget),
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
                                    ? FontWeight.w900
                                    : (isDone
                                        ? FontWeight.bold
                                        : FontWeight.normal),
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
                DuoButton(
                  text: 'COBA LAGI',
                  icon: Icons.refresh_rounded,
                  variant: DuoButtonVariant.green,
                  onPressed: _executePipeline,
                ),
                const SizedBox(height: 10),
                DuoButton(
                  text: 'KEMBALI KE PRATINJAU',
                  variant: DuoButtonVariant.white,
                  onPressed: () => Navigator.of(context).pop(),
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
