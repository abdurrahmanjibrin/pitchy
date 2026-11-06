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
          // If camera fails, continue with high-quality audio recording fallback
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
    } else {
      await recordingService.pauseRecording();
    }
  }

  Future<void> _stopRecording() async {
    final recordingService = ref.read(audioRecordingServiceProvider);
    final recordedPath = await recordingService.stopRecording();
    final actualSeconds = _stateData.durationSeconds;

    if (!mounted) return;

    if (actualSeconds < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Durasi rekaman terlalu singkat (minimal 3 detik untuk analisis).',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    BodyLanguageEvaluation? bodyEval;
    if (_bodyLanguageAnalyzer != null) {
      bodyEval = _bodyLanguageAnalyzer!.finishEvaluation();
    }

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
        backgroundColor: AppColors.surface,
        title: const Text('Batalkan Latihan?'),
        content: const Text(
          'Rekaman saat ini akan dihapus dan sesi latihan tidak akan disimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lanjutkan Rekam'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Batalkan'),
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
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                setup.recordingType == 'video'
                    ? 'Menyiapkan kamera & model AI postur...'
                    : 'Menyiapkan mikrofon...',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perekaman Gagal')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mic_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tidak Dapat Mengakses Perangkat Rekam',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _initError = null;
                  });
                  _startRecordingSession();
                },
                child: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali'),
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: isVideo ? Colors.black54 : AppColors.surface,
          elevation: 0,
          title: Text(setup.title),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Batalkan sesi',
            onPressed: _cancelRecording,
          ),
          actions: [
            if (challenge != null)
              IconButton(
                icon: Icon(
                  _showBriefSheet
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.secondary,
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
              // 1. Background: Camera Preview or Audio Atmosphere
              if (isVideo) ...[
                Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
                // Live AI Body Language HUD Overlay
                Positioned.fill(
                  child: BodyLanguageHudOverlay(
                    feedback: _liveFeedback,
                    isFrontCamera: _cameraDescription?.lensDirection ==
                        CameraLensDirection.front,
                  ),
                ),
              ] else ...[
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, AppColors.surface],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],

              // 2. Foreground Overlays & Controls
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Collapsible Floating Brief Reminder
                    if (_showBriefSheet && challenge != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Pengingat Brief Tantangan',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                            if (challenge.requiredWords.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: challenge.requiredWords.map((w) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      borderRadius: BorderRadius.circular(8),
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
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
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
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
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
                                      ? AppColors.warning
                                      : AppColors.error,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _stateData.isPaused ? 'JEDA' : 'MEREKAM',
                                style: TextStyle(
                                  color: _stateData.isPaused
                                      ? AppColors.warning
                                      : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                                  ? AppColors.warning
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Target: ${Formatters.formatSecondsToMinutesSeconds(targetSeconds)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // If Audio-only mode: render big timer & waveform centered
                    if (!isVideo) ...[
                      Text(
                        Formatters.formatSecondsToMinutesSeconds(
                          _stateData.durationSeconds,
                        ),
                        style: TextStyle(
                          color: isOverTarget
                              ? AppColors.warning
                              : AppColors.textPrimary,
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.5,
                        ),
                      ),
                      if (isOverTarget)
                        const Text(
                          'Melebihi target durasi',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 28),
                      AudioWaveformWidget(
                        amplitude: _stateData.currentAmplitude,
                        isRecording: _stateData.isRecording,
                        isPaused: _stateData.isPaused,
                      ),
                      const Spacer(),
                    ],

                    // Bottom Floating Control Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Pause / Resume
                          IconButton(
                            icon: Icon(
                              _stateData.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            onPressed: _togglePauseResume,
                          ),

                          // Big Stop Recording Button
                          GestureDetector(
                            onTap: _stopRecording,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.error, Color(0xFFDC2626)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.error.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.stop_rounded,
                                  size: 34,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          // Brief Sheet Toggle
                          IconButton(
                            icon: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            tooltip: 'Buka Brief',
                            onPressed: () {
                              setState(() {
                                _showBriefSheet = !_showBriefSheet;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tekan tombol kotak merah setelah kamu selesai berpidato',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
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
