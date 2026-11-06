import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/body_language_evaluation.dart';
import '../../data/models/challenge_evaluation.dart';
import '../../data/models/practice_session.dart';
import '../../services/playback/audio_playback_service.dart';
import '../../shared/widgets/score_badge.dart';
import '../dashboard/main_navigation_screen.dart';
import '../practice/practice_setup_screen.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final PracticeSession session;
  final bool isNewlyCreated;

  const AnalysisResultScreen({
    super.key,
    required this.session,
    this.isNewlyCreated = false,
  });

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<PlaybackStateData>? _playbackSub;
  PlaybackStateData _playbackData = PlaybackStateData(
    state: PlayerState.stopped,
    position: Duration.zero,
    duration: Duration.zero,
  );

  @override
  void initState() {
    super.initState();
    final hasWordsCheck = widget.session.requiredWords.isNotEmpty;
    final hasBodyLanguage = widget.session.bodyLanguageEvaluation != null;
    int tabCount = 3;
    if (hasWordsCheck) tabCount++;
    if (hasBodyLanguage) tabCount++;
    _tabController = TabController(length: tabCount, vsync: this);

    final playbackService = ref.read(audioPlaybackServiceProvider);
    _playbackSub = playbackService.playbackStream.listen((data) {
      if (mounted) {
        setState(() {
          _playbackData = data;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    final path = widget.session.recordingPath;
    if (path == null || path.isEmpty) return;

    final playbackService = ref.read(audioPlaybackServiceProvider);
    if (_playbackData.isPlaying) {
      await playbackService.pause();
    } else {
      await playbackService.play(path);
    }
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final eval = s.evaluation;
    final hasWordsCheck = s.requiredWords.isNotEmpty;
    final hasBodyLanguage = s.bodyLanguageEvaluation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Evaluasi Pitching'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(audioPlaybackServiceProvider).stop();
            if (widget.isNewlyCreated) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainNavigationScreen(initialIndex: 0),
                ),
                (route) => false,
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Score Header Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ScoreBadge(
                        score: s.overallScore,
                        label: 'Skor Total',
                        size: hasBodyLanguage ? 58 : 68,
                      ),
                      Container(height: 44, width: 1, color: AppColors.divider),
                      ScoreBadge(
                        score: s.deliveryScore,
                        label: 'Vokal',
                        size: hasBodyLanguage ? 52 : 58,
                      ),
                      if (hasBodyLanguage) ...[
                        Container(
                            height: 44, width: 1, color: AppColors.divider),
                        ScoreBadge(
                          score: s.bodyLanguageScore,
                          label: 'Bahasa Tubuh',
                          size: 52,
                        ),
                      ],
                      Container(height: 44, width: 1, color: AppColors.divider),
                      ScoreBadge(
                        score: s.contentScore,
                        label: 'Konten AI',
                        size: hasBodyLanguage ? 52 : 58,
                      ),
                    ],
                  ),
                  if (s.recordingPath != null &&
                      s.recordingPath!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    // Embedded Playback Bar
                    Row(
                      children: [
                        IconButton(
                          iconSize: 30,
                          icon: Icon(
                            _playbackData.isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_fill_rounded,
                            color: AppColors.primaryLight,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dengarkan Rekaman Latihan (${Formatters.formatSecondsToMinutesSeconds(s.actualDuration)})',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${Formatters.formatSecondsToMinutesSeconds(_playbackData.position.inSeconds)} / ${Formatters.formatSecondsToMinutesSeconds(s.actualDuration)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: (hasWordsCheck || hasBodyLanguage),
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                const Tab(text: 'Penyampaian'),
                if (hasBodyLanguage) const Tab(text: 'Bahasa Tubuh'),
                const Tab(text: 'Evaluasi AI'),
                if (hasWordsCheck) const Tab(text: 'Kata Wajib'),
                const Tab(text: 'Transkrip'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDeliveryTab(s),
                  if (hasBodyLanguage)
                    _buildBodyLanguageTab(s.bodyLanguageEvaluation!),
                  _buildAiContentTab(eval),
                  if (hasWordsCheck) _buildRequiredWordsTab(eval, s),
                  _buildTranscriptTab(s),
                ],
              ),
            ),

            // Bottom CTA Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(audioPlaybackServiceProvider).stop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MainNavigationScreen(initialIndex: 0),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Beranda'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(audioPlaybackServiceProvider).stop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const PracticeSetupScreen(),
                          ),
                        );
                      },
                      child: const Text('Latihan Baru'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTab(PracticeSession s) {
    final wpm = s.speakingPace ?? 0.0;
    final paceLabel = Formatters.getPaceLabel(wpm);
    final paceColor = Formatters.getPaceColor(wpm);
    final fillerCount = s.fillerCount ?? 0;
    final fillerRate = s.fillerRate ?? 0.0;
    final fillerPerMin = s.fillerPerMinute ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Speaking Pace (WPM) Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kecepatan Berbicara (WPM)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: paceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      paceLabel,
                      style: TextStyle(
                        color: paceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    wpm.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Kata Per Menit',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '• Standar latihan yang disarankan: 100 – 160 WPM.\n'
                '• Tempo stabil membantu audiens memahami poin penting tanpa terasa terburu-buru.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filler Words Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kata Pengisi (Filler Words)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$fillerCount kata ($fillerRate% dari total)',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Total Pengisi',
                      value: '$fillerCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Pengisi / Menit',
                      value: fillerPerMin.toStringAsFixed(1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      title: 'Total Kata',
                      value: '${s.totalWords ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (s.fillerStats.isNotEmpty) ...[
                const Text(
                  'Rincian Frekuensi Kata Pengisi Terdeteksi:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: s.fillerStats.map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Text(
                        '"${f.fillerWord}": ${f.count}x',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                const Text(
                  'Bagus sekali! Tidak ada kata pengisi yang terdeteksi secara dominan pada rekaman ini.',
                  style: TextStyle(color: AppColors.success, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiContentTab(ChallengeEvaluation? eval) {
    if (eval == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Evaluasi konten belum tersedia untuk sesi ini.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Sentence Clarity Card
        _buildRubricCard(
          title: 'Kejelasan Susunan Kalimat (Clarity)',
          score: eval.sentenceClarityScore,
          reason: eval.sentenceClarityReason,
          icon: Icons.auto_stories_rounded,
        ),
        const SizedBox(height: 12),

        // Coherence Card
        _buildRubricCard(
          title: 'Kelogisan Alur & Transisi (Coherence)',
          score: eval.coherenceScore,
          reason: eval.coherenceReason,
          icon: Icons.timeline_rounded,
        ),
        const SizedBox(height: 12),

        // Relevance Card
        _buildRubricCard(
          title: 'Relevansi Topik & Tantangan',
          score: eval.relevanceScore,
          reason: eval.relevanceReason,
          icon: Icons.center_focus_strong_rounded,
        ),
        const SizedBox(height: 12),

        // Audience Fit (if present)
        if (eval.audienceFitScore != null) ...[
          _buildRubricCard(
            title: 'Penyesuaian terhadap Target Audiens',
            score: eval.audienceFitScore,
            reason: eval.audienceFitReason,
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 12),
        ],

        // Strengths & Improvements
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    color: AppColors.success,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Kekuatan Utama Pitching',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...eval.strengths.map(
                (str) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: AppColors.success),
                      ),
                      Expanded(
                        child: Text(
                          str,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Area Perbaikan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...eval.improvements.map(
                (imp) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(color: AppColors.warning),
                      ),
                      Expanded(
                        child: Text(
                          imp,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Suggested Revision
        if (eval.suggestedRevision != null &&
            eval.suggestedRevision!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Saran Perbaikan Kalimat Lebih Persuasif',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  eval.suggestedRevision!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequiredWordsTab(ChallengeEvaluation? eval, PracticeSession s) {
    final wordsResult = eval?.requiredWordsResult ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Pemeriksaan Kata Wajib Tantangan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'AI memeriksa apakah setiap kata wajib digunakan secara alami dalam konteks pitching, bukan sekadar diulang tanpa makna.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        if (wordsResult.isNotEmpty)
          ...wordsResult.map((w) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: w.found
                      ? AppColors.success.withValues(alpha: 0.5)
                      : AppColors.error.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kata: "${w.word}"',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (w.found ? AppColors.success : AppColors.error)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          w.found ? 'Terintegrasi' : 'Tidak Ditemukan',
                          style: TextStyle(
                            color: w.found
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (w.evidence.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Bukti ucapan: "${w.evidence}"',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  if (w.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      w.note,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            );
          })
        else
          ...s.requiredWords.map((word) {
            final found =
                s.transcript?.toLowerCase().contains(word.toLowerCase()) ??
                false;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kata: "$word"',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    found ? 'Ditemukan' : 'Belum Ditemukan',
                    style: TextStyle(
                      color: found ? AppColors.success : AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTranscriptTab(PracticeSession s) {
    final transcript = s.transcript ?? '';

    if (transcript.isEmpty) {
      return const Center(
        child: Text(
          'Transkrip tidak tersedia.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notes_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Transkrip Ucapan Asli',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(
                transcript,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildRubricCard({
    required String title,
    required double? score,
    required String? reason,
    required IconData icon,
  }) {
    final scoreDisplay = score != null ? score.toStringAsFixed(0) : '-';
    final scoreColor = Formatters.getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scoreDisplay,
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyLanguageTab(BodyLanguageEvaluation eval) {
    final overallScore = eval.overallScore;
    final scoreColor = Formatters.getScoreColor(overallScore);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Header Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Performa Bahasa Tubuh',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${overallScore.toInt()}/100',
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildMetricProgressBar(
                label: 'Postur Ekspansif',
                score: eval.postureScore,
              ),
              const SizedBox(height: 10),
              _buildMetricProgressBar(
                label: 'Gestur Strike Zone',
                score: eval.gestureScore,
                extraInfo: '${eval.strikeZonePercentage.toInt()}% waktu',
              ),
              const SizedBox(height: 10),
              _buildMetricProgressBar(
                label: 'Kestabilan Kuda-kuda',
                score: eval.stabilityScore,
              ),
              const SizedBox(height: 10),
              _buildMetricProgressBar(
                label: 'Kontak Mata & Tatapan',
                score: eval.eyeContactScore,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 1. Postur Ekspansif
        _buildBodyDimensionCard(
          title: 'Postur Tubuh (Ekspansif vs Tertutup)',
          score: eval.postureScore,
          icon: Icons.accessibility_new_rounded,
          feedback: eval.postureFeedback,
          researchQuote:
              'Riset: Postur dada terbuka dan bahu tegap menurunkan hormon kortisol dan memancarkan wibawa kepemimpinan.',
        ),
        const SizedBox(height: 12),

        // 2. Strike Zone
        _buildBodyDimensionCard(
          title: 'Gestur Tangan di "Strike Zone"',
          score: eval.gestureScore,
          icon: Icons.pan_tool_alt_rounded,
          feedback:
              '${eval.gestureFeedback} (Tangan berada di zona dada-pinggang selama ${eval.strikeZonePercentage.toInt()}% durasi presentasi).',
          researchQuote:
              'Riset: Audiens lebih mempercayai pembicara yang tangannya terlihat dan bergerak alami di area antara dada dan pinggang.',
        ),
        const SizedBox(height: 12),

        // 3. Kestabilan Kuda-kuda
        _buildBodyDimensionCard(
          title: 'Kestabilan Kuda-kuda (Anchoring)',
          score: eval.stabilityScore,
          icon: Icons.anchor_rounded,
          feedback: eval.stabilityFeedback,
          researchQuote:
              'Riset: Mengakar (spatial anchoring) saat menyampaikan poin penting menunjukkan ketegasan dibanding pacing gelisah bolak-balik.',
        ),
        const SizedBox(height: 12),

        // 4. Kontak Mata
        _buildBodyDimensionCard(
          title: 'Kontak Mata & Orientasi Kepala',
          score: eval.eyeContactScore,
          icon: Icons.visibility_rounded,
          feedback: eval.eyeContactFeedback,
          researchQuote:
              'Riset: Mempertahankan kontak mata pada audiens secara stabil mencerminkan ketenangan dan membangun koneksi emosional.',
        ),
        const SizedBox(height: 16),

        // Alerts Timeline
        if (eval.alerts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.history_rounded,
                        size: 18, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text(
                      'Log Deteksi Bahasa Tubuh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...eval.alerts.map((alert) {
                  final isWarning = alert.type == 'warning';
                  final iconColor = isWarning
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981);
                  final timeStr = Formatters.formatSecondsToMinutesSeconds(
                    alert.timestampSeconds,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                            ),
                          ),
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isWarning
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            alert.message,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Actionable Tips
        if (eval.actionableTips.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.lightbulb_rounded,
                        size: 18, color: AppColors.accent),
                    SizedBox(width: 8),
                    Text(
                      'Rekomendasi Latihan Gerak Tubuh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...eval.actionableTips.map((tip) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tip,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildMetricProgressBar({
    required String label,
    required double score,
    String? extraInfo,
  }) {
    final color = Formatters.getScoreColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                if (extraInfo != null) ...[
                  Text(
                    extraInfo,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '${score.toInt()}/100',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (score / 100.0).clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceCard,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyDimensionCard({
    required String title,
    required double score,
    required IconData icon,
    required String feedback,
    required String researchQuote,
  }) {
    final scoreColor = Formatters.getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${score.toInt()}/100',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            feedback,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              researchQuote,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
