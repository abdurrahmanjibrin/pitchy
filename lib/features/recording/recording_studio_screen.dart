import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/body_language_evaluation.dart';
import '../../services/recording/audio_recording_service.dart';
import '../../services/vision/body_language_analyzer.dart';
import '../../shared/widgets/audio_waveform_widget.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import 'post_recording_preview_screen.dart';
import 'widgets/body_language_hud_overlay.dart';

class RecordingStudioScreen extends ConsumerStatefulWidget {
  const RecordingStudioScreen({super.key});

  @override
  ConsumerState<RecordingStudioScreen> createState() =>
      _RecordingStudioScreenState();
}

class _RecordingStudioScreenState extends ConsumerState<RecordingStudioScreen> {
  bool _isInitializing = true;
  String? _initError;
  bool _showBriefSheet = false;

  StreamSubscription<RecordingStateData>? _recordingSub;
  RecordingStateData _stateData = RecordingStateData(
    isRecording: false,
    isPaused: false,
    durationSeconds: 0,
    currentAmplitude: 0.0,
  );

  // Video & AI Vision State
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  BodyLanguageAnalyzer? _bodyLanguageAnalyzer;
  BodyLanguageLiveFeedback _liveFeedback = const BodyLanguageLiveFeedback();
  StreamSubscription<BodyLanguageLiveFeedback>? _feedbackSub;
  bool _isProcessingFrame = false;
  int _frameCounter = 0;

  @override
  void initState() {
    super.initState();
    _startRecordingSession();
  }

  Future<void> _startRecordingSession() async {
    final setup = ref.read(activePracticeSetupProvider);
    final recordingService = ref.read(audioRecordingServiceProvider);

    _recordingSub = recordingService.stateStream.listen((data) {
      if (mounted) {
        setState(() {
          _stateData = data;
        });
      }
    });

    try {
      // 1. If Video mode is chosen, initialize Camera and BodyLanguageAnalyzer
      if (setup.recordingType == 'video') {
        try {
          final cameras = await availableCameras();
          if (cameras.isNotEmpty) {
            final frontCamera = cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => cameras.first,
            );
            _cameraDescription = frontCamera;
            final controller = CameraController(
              frontCamera,
              ResolutionPreset.medium,
              enableAudio: false,
              imageFormatGroup: ImageFormatGroup.nv21,
            );
            _cameraController = controller;
            await controller.initialize();

            _bodyLanguageAnalyzer = BodyLanguageAnalyzer();
            _feedbackSub =
                _bodyLanguageAnalyzer!.feedbackStream.listen((feedback) {
              if (mounted) {
                setState(() {
                  _liveFeedback = feedback;
                });
              }
            });
            _bodyLanguageAnalyzer!.startSession();

            await controller.startImageStream((CameraImage image) {
              _frameCounter++;
              if (_frameCounter % 3 != 0) return; // Process ~10 FPS for optimal performance
              if (_isProcessingFrame) return;

              final inputImage = _buildInputImage(image, frontCamera);
              if (inputImage != null) {
                _isProcessingFrame = true;
                _bodyLanguageAnalyzer?.processImage(inputImage).whenComplete(() {
                  _isProcessingFrame = false;
                });
              }
            });
          }
        } catch (camErr) {
          debugPrint('Camera/Vision init fallback: $camErr');
          // Fallback to high quality audio
        }
      }

      // 2. Start high-quality local Audio recording
      await recordingService.startRecording();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    try {
      final rotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      Uint8List bytes;
      if (image.planes.length == 1) {
        bytes = image.planes.first.bytes;
      } else {
        final builder = BytesBuilder(copy: false);
        for (final plane in image.planes) {
          builder.add(plane.bytes);
        }
        bytes = builder.takeBytes();
      }

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _togglePauseResume() async {
    final recordingService = ref.read(audioRecordingServiceProvider);
    if (_stateData.isPaused) {
      await recordingService.resumeRecording();
      _bodyLanguageAnalyzer?.resumeSession();
    } else {
      await recordingService.pauseRecording();
      _bodyLanguageAnalyzer?.pauseSession();
    }
  }

  Future<void> _stopRecording() async {
    final recordingService = ref.read(audioRecordingServiceProvider);
    final actualSeconds = _stateData.durationSeconds;

    // Stop and finalize body language analysis
    BodyLanguageEvaluation? bodyEval;
    if (_bodyLanguageAnalyzer != null) {
      bodyEval = _bodyLanguageAnalyzer!.finalizeSession(
        actualDurationSeconds: actualSeconds,
      );
    }

    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
    }

    final recordedPath = await recordingService.stopRecording();

    if (!mounted) return;

    if (recordedPath != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PostRecordingPreviewScreen(
            audioPath: recordedPath,
            actualDurationSeconds: actualSeconds,
            bodyLanguageEvaluation: bodyEval,
          ),
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        title: Row(
          children: const [
            DuoMascotAvatar(size: 32),
            SizedBox(width: 10),
            Text(
              'Batalkan Latihan?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Rekaman saat ini akan dibatalkan dan tidak akan tersimpan di riwayat latihanmu.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Lanjutkan Rekam',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DuoButton(
            text: 'BATALKAN',
            variant: DuoButtonVariant.red,
            height: 42,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final recordingService = ref.read(audioRecordingServiceProvider);
      await recordingService.cancelRecording();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _recordingSub?.cancel();
    _feedbackSub?.cancel();
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream().catchError((_) {});
    }
    _cameraController?.dispose();
    _bodyLanguageAnalyzer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(activePracticeSetupProvider);
    final challenge = setup.selectedChallenge;
    final targetSeconds = setup.targetDuration ?? 120;
    final isVideo = setup.recordingType == 'video' &&
        _cameraController != null &&
        _cameraController!.value.isInitialized;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DuoMascotAvatar(size: 72),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                strokeWidth: 3,
              ),
              const SizedBox(height: 18),
              Text(
                setup.recordingType == 'video'
                    ? 'Menyiapkan kamera & AI gerakan tubuh...'
                    : 'Menyiapkan mikrofon studio...',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Perekaman Gagal')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_off_rounded,
                size: 64,
                color: AppColors.red,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tidak Dapat Mengakses Perangkat Rekam',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 28),
              DuoButton(
                text: 'COBA LAGI',
                variant: DuoButtonVariant.green,
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _initError = null;
                  });
                  _startRecordingSession();
                },
              ),
              const SizedBox(height: 12),
              DuoButton(
                text: 'KEMBALI',
                variant: DuoButtonVariant.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final isOverTarget = _stateData.durationSeconds > targetSeconds;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelRecording();
      },
      child: Scaffold(
        backgroundColor: isVideo ? Colors.black : AppColors.background,
        appBar: AppBar(
          backgroundColor: isVideo ? Colors.black54 : Colors.white,
          elevation: 0,
          title: Text(
            setup.title,
            style: TextStyle(
              color: isVideo ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isVideo ? Colors.white : AppColors.textPrimary,
            ),
            tooltip: 'Batalkan sesi',
            onPressed: _cancelRecording,
          ),
          actions: [
            if (challenge != null)
              IconButton(
                icon: Icon(
                  _showBriefSheet
                      ? Icons.menu_book_rounded
                      : Icons.menu_book_outlined,
                  color: isVideo ? AppColors.yellow : AppColors.blue,
                ),
                tooltip: 'Lihat brief tantangan',
                onPressed: () {
                  setState(() {
                    _showBriefSheet = !_showBriefSheet;
                  });
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background: Camera Preview or Duolingo Light Canvas
              if (isVideo) ...[
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                Positioned.fill(
                  child: BodyLanguageHudOverlay(
                    feedback: _liveFeedback,
                    isFrontCamera: _cameraDescription?.lensDirection ==
                        CameraLensDirection.front,
                  ),
                ),
              ],

              // 2. Foreground Overlays & Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Collapsible Brief Reminder
                    if (_showBriefSheet && challenge != null) ...[
                      DuoCard(
                        borderWidth: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.lightbulb_rounded,
                                      color: AppColors.yellow,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pengingat Brief Tantangan',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () =>
                                      setState(() => _showBriefSheet = false),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              challenge.prompt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            if (challenge.requiredWords.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: challenge.requiredWords.map((w) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.blue,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      w,
                                      style: const TextStyle(
                                        color: AppColors.blueDark,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Timer & Target Duration Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isVideo
                            ? Colors.black.withValues(alpha: 0.65)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVideo
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.border,
                          width: 2,
                        ),
                        boxShadow: isVideo
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _stateData.isPaused
                                      ? AppColors.yellow
                                      : AppColors.red,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _stateData.isPaused ? 'JEDA' : 'MEREKAM',
                                style: TextStyle(
                                  color: _stateData.isPaused
                                      ? (isVideo
                                          ? AppColors.yellow
                                          : AppColors.orangeDark)
                                      : AppColors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            Formatters.formatSecondsToMinutesSeconds(
                              _stateData.durationSeconds,
                            ),
                            style: TextStyle(
                              color: isOverTarget
                                  ? AppColors.orange
                                  : (isVideo
                                      ? Colors.white
                                      : AppColors.textPrimary),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Target: ${Formatters.formatSecondsToMinutesSeconds(targetSeconds)}',
                            style: TextStyle(
                              color: isVideo
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // If Audio-only mode: Duolingo Coach Atmosphere
                    if (!isVideo) ...[
                      DuoMascotAvatar(
                        size: 96,
                        speechText: _stateData.isPaused
                            ? 'Latihan dijeda! Tekan tombol play untuk lanjut.'
                            : isOverTarget
                                ? 'Target durasi tercapai! Boleh rangkum poinmu.'
                                : 'Pitchy mendengarkanmu, bicaralah dengan santai!',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        Formatters.formatSecondsToMinutesSeconds(
                          _stateData.durationSeconds,
                        ),
                        style: TextStyle(
                          color: isOverTarget
                              ? AppColors.orange
                              : AppColors.textPrimary,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                        ),
                      ),
                      if (isOverTarget)
                        const Text(
                          'Melebihi target durasi',
                          style: TextStyle(
                            color: AppColors.orangeDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 20),
                      AudioWaveformWidget(
                        amplitude: _stateData.currentAmplitude,
                        isRecording: _stateData.isRecording,
                        isPaused: _stateData.isPaused,
                      ),
                      const Spacer(),
                    ],

                    // Bottom Duolingo Tactile Control Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isVideo
                            ? Colors.black.withValues(alpha: 0.75)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isVideo
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppColors.border,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Pause / Resume Tactile Button
                          InkWell(
                            onTap: _togglePauseResume,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isVideo
                                    ? Colors.white12
                                    : AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isVideo
                                      ? Colors.white24
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _stateData.isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                color: isVideo
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                size: 28,
                              ),
                            ),
                          ),

                          // Signature Duolingo 3D Red Stop Button
                          GestureDetector(
                            onTap: _stopRecording,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white38, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.redDark,
                                    offset: Offset(0, 5),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.stop_rounded,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Brief Sheet Toggle
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showBriefSheet = !_showBriefSheet;
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isVideo
                                    ? Colors.white12
                                    : AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isVideo
                                      ? Colors.white24
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: isVideo
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tekan tombol merah jika sudah selesai pitching',
                      style: TextStyle(
                        color: isVideo ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
