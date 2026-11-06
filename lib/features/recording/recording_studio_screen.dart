import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/recording/audio_recording_service.dart';
import '../../shared/widgets/audio_waveform_widget.dart';
import 'post_recording_preview_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _startRecordingSession();
  }

  Future<void> _startRecordingSession() async {
    final recordingService = ref.read(audioRecordingServiceProvider);

    _recordingSub = recordingService.stateStream.listen((data) {
      if (mounted) {
        setState(() {
          _stateData = data;
        });
      }
    });

    try {
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
              'Durasi rekaman terlalu singkat (minimal 3 detik untuk analisis).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (recordedPath != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PostRecordingPreviewScreen(
            audioPath: recordedPath,
            actualDurationSeconds: actualSeconds,
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
          'Rekaman audio saat ini akan dihapus dan sesi latihan tidak akan disimpan.',
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(activePracticeSetupProvider);
    final challenge = setup.selectedChallenge;
    final targetSeconds = setup.targetDuration ?? 120;

    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Menyiapkan mikrofon...',
                style: TextStyle(color: AppColors.textSecondary),
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
              const Icon(Icons.mic_off_rounded,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 20),
              Text(
                'Tidak Dapat Mengakses Mikrofon',
                style: const TextStyle(
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

    return WillPopScope(
      onWillPop: () async {
        await _cancelRecording();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Collapsible Floating Brief Reminder
                if (_showBriefSheet && challenge != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.5)),
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
                              child: const Icon(Icons.close,
                                  size: 16, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          challenge.prompt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
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
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.secondary.withOpacity(0.4)),
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
                  const SizedBox(height: 12),
                ],

                // Timer & Target Duration Row
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
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
                        'Target: ${Formatters.formatSecondsToMinutesSeconds(targetSeconds)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Big Digital Timer
                Text(
                  Formatters.formatSecondsToMinutesSeconds(
                      _stateData.durationSeconds),
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

                // Audio Waveform
                AudioWaveformWidget(
                  amplitude: _stateData.currentAmplitude,
                  isRecording: _stateData.isRecording,
                  isPaused: _stateData.isPaused,
                ),

                const Spacer(),

                // Control Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Pause / Resume
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _stateData.isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                        onPressed: _togglePauseResume,
                      ),
                    ),
                    const SizedBox(width: 28),

                    // Big Stop Recording Button
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.error, Color(0xFFDC2626)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.stop_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),

                    // Quick Brief Toggle
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                        tooltip: 'Buka Brief',
                        onPressed: () {
                          setState(() {
                            _showBriefSheet = !_showBriefSheet;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Tekan tombol kotak merah setelah kamu selesai berpidato',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

