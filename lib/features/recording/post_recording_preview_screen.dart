import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/body_language_evaluation.dart';
import '../../services/playback/audio_playback_service.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../processing/processing_screen.dart';
import 'recording_studio_screen.dart';

class PostRecordingPreviewScreen extends ConsumerStatefulWidget {
  final String audioPath;
  final int actualDurationSeconds;
  final BodyLanguageEvaluation? bodyLanguageEvaluation;

  const PostRecordingPreviewScreen({
    super.key,
    required this.audioPath,
    required this.actualDurationSeconds,
    this.bodyLanguageEvaluation,
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
        MaterialPageRoute(builder: (_) => const RecordingStudioScreen()),
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
            bodyLanguageEvaluation: widget.bodyLanguageEvaluation,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pratinjau Rekaman'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const Spacer(),

              // Celebratory Mascot with Speech Bubble
              const DuoMascotAvatar(
                size: 90,
                speechText: 'Keren! Rekamanmu sudah siap untuk dinilai AI Coach.',
              ),
              const SizedBox(height: 24),

              Text(
                'Rekaman Selesai!',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${Formatters.formatSecondsToMinutesSeconds(widget.actualDurationSeconds)} • $fileSizeKb KB • Format M4A',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (widget.bodyLanguageEvaluation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.purple,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.purple,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Pose: ${widget.bodyLanguageEvaluation!.overallScore.toInt()}/100 • Strike Zone ${widget.bodyLanguageEvaluation!.strikeZonePercentage.toInt()}%',
                        style: const TextStyle(
                          color: AppColors.purpleDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Audio Player DuoCard
              DuoCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatSecondsToMinutesSeconds(
                            currentPositionSec,
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          Formatters.formatSecondsToMinutesSeconds(
                            totalDurationSec,
                          ),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        trackHeight: 6,
                        activeTrackColor: AppColors.blue,
                        inactiveTrackColor: AppColors.border,
                        thumbColor: AppColors.blueDark,
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
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.blueDark,
                              offset: Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _playbackData.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Primary CTA
              DuoButton(
                text: 'ANALISIS DENGAN AI COACH',
                icon: Icons.psychology_rounded,
                variant: DuoButtonVariant.green,
                onPressed: _proceedToProcessing,
              ),
              const SizedBox(height: 12),

              // Re-record
              DuoButton(
                text: 'REKAM ULANG',
                icon: Icons.refresh_rounded,
                variant: DuoButtonVariant.white,
                onPressed: _reRecord,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
