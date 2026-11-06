import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/playback/audio_playback_service.dart';
import '../processing/processing_screen.dart';
import 'recording_studio_screen.dart';

class PostRecordingPreviewScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final int actualDurationSeconds;

  const PostRecordingPreviewScreen({
    super.key,
    required this.audioPath,
    required this.actualDurationSeconds,
  });

  @override
  ConsumerState<PostRecordingPreviewScreen> createState() =>
      _PostRecordingPreviewScreenState();
}

class _PostRecordingPreviewScreenState
    extends ConsumerState<PostRecordingPreviewScreen> {
  StreamSubscription<PlaybackStateData>? _playbackSub;
  PlaybackStateData _playbackData = PlaybackStateData(
    state: PlayerState.stopped,
    position: Duration.zero,
    duration: Duration.zero,
  );

  int _fileSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _initFileInfo();
    final playbackService = ref.read(audioPlaybackServiceProvider);
    _playbackSub = playbackService.playbackStream.listen((data) {
      if (mounted) {
        setState(() {
          _playbackData = data;
        });
      }
    });
  }

  Future<void> _initFileInfo() async {
    final file = File(widget.audioPath);
    if (await file.exists()) {
      final size = await file.length();
      if (mounted) {
        setState(() {
          _fileSizeBytes = size;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    final playbackService = ref.read(audioPlaybackServiceProvider);
    if (_playbackData.isPlaying) {
      await playbackService.pause();
    } else {
      await playbackService.play(widget.audioPath);
    }
  }

  Future<void> _reRecord() async {
    final playbackService = ref.read(audioPlaybackServiceProvider);
    await playbackService.stop();

    // Delete temp file
    try {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const RecordingStudioScreen(),
        ),
      );
    }
  }

  void _proceedToProcessing() async {
    final playbackService = ref.read(audioPlaybackServiceProvider);
    await playbackService.stop();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProcessingScreen(
            audioPath: widget.audioPath,
            actualDurationSeconds: widget.actualDurationSeconds,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileSizeKb = (_fileSizeBytes / 1024).toStringAsFixed(1);

    final currentPositionSec = _playbackData.position.inSeconds;
    final totalDurationSec = _playbackData.duration.inSeconds > 0
        ? _playbackData.duration.inSeconds
        : widget.actualDurationSeconds;

    final sliderValue = totalDurationSec > 0
        ? (currentPositionSec / totalDurationSec).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Rekaman'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Microphone Icon Circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Rekaman Selesai Diambil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${Formatters.formatSecondsToMinutesSeconds(widget.actualDurationSeconds)} • $fileSizeKb KB • Format M4A Audio',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 36),

              // Audio Player Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatSecondsToMinutesSeconds(
                              currentPositionSec),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          Formatters.formatSecondsToMinutesSeconds(
                              totalDurationSec),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 4,
                        activeTrackColor: AppColors.primaryLight,
                        inactiveTrackColor: AppColors.surfaceBorder,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: sliderValue,
                        onChanged: (val) {
                          final seekToSec = (val * totalDurationSec).round();
                          ref
                              .read(audioPlaybackServiceProvider)
                              .seek(Duration(seconds: seekToSec));
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _playbackData.isPlaying
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_fill_rounded,
                        color: AppColors.primaryLight,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary CTA
              ElevatedButton.icon(
                onPressed: _proceedToProcessing,
                icon: const Icon(Icons.psychology_rounded),
                label: const Text('Proses & Analisis dengan AI Coach'),
              ),
              const SizedBox(height: 12),

              // Re-record
              OutlinedButton.icon(
                onPressed: _reRecord,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Rekam Ulang'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
