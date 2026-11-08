import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/duo_button.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../../shared/widgets/score_badge.dart';
import '../../shared/widgets/stat_card.dart';
import '../practice/challenge_brief_screen.dart';
import '../practice/practice_setup_screen.dart';
import '../result/analysis_result_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepo = ref.watch(userRepositoryProvider);
    final userName = userRepo.getUserName();
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          backgroundColor: Colors.white,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Duolingo Header: Greeting + Streak & Gems
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $userName! 👋',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ayo asah pitch-mu hari ini!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Streak & Energy Chips
                    Row(
                      children: [
                        _buildStreakBadge(count: 3),
                        const SizedBox(width: 8),
                        _buildGemBadge(gems: 120),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Pitchy Mascot Motivation Bubble
                const DuoMascotAvatar(
                  speechText:
                      'Tegakkan bahu, atur tempo, dan sampaikan ide brilianmu dengan percaya diri!',
                  size: 64,
                ),
                const SizedBox(height: 20),

                // Main Hero Call to Action (Duolingo Chunky Style)
                DuoCard(
                  backgroundColor: AppColors.green,
                  borderColor: AppColors.greenDark,
                  bottomBorderColor: AppColors.greenDark,
                  borderRadius: 22,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🎯 LATIHAN HARIAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.yellow,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Asah Spontanitas & Kelogisan Pitching',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Latih vokal, WPM, dan bahasa tubuh langsung di depan kamera AI.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: DuoButton(
                              text: 'MULAI LATIHAN',
                              icon: Icons.play_arrow_rounded,
                              color: DuoButtonColor.white,
                              height: 48,
                              fontSize: 13,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PracticeSetupScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DuoButton(
                              text: 'TANTANGAN CEPAT',
                              icon: Icons.bolt_rounded,
                              color: DuoButtonColor.yellow,
                              height: 48,
                              fontSize: 12,
                              onPressed: () async {
                                final challengeService = ref.read(
                                  challengeServiceProvider,
                                );
                                final item = await challengeService
                                    .getRandomChallenge(type: 'random_words');

                                ref
                                    .read(activePracticeSetupProvider.notifier)
                                    .setSetup(
                                      ActivePracticeSetup(
                                        title: 'Tantangan Kata Cepat',
                                        mode: 'challenge',
                                        challengeType: 'random_words',
                                        selectedChallenge: item,
                                        preparationSeconds: 30,
                                        targetDuration: item.suggestedDuration,
                                        recordingType: 'video',
                                      ),
                                    );

                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChallengeBriefScreen(challenge: item),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3 Mode Tantangan Cards
                const Text(
                  'PILIH MODE TANTANGAN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        ref: ref,
                        type: 'random_words',
                        title: 'Kata Wajib',
                        icon: Icons.spellcheck_rounded,
                        color: AppColors.purple,
                        darkColor: AppColors.purpleDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        ref: ref,
                        type: 'random_theme',
                        title: 'Tema Acak',
                        icon: Icons.lightbulb_rounded,
                        color: AppColors.blue,
                        darkColor: AppColors.blueDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildModeCard(
                        context: context,
                        ref: ref,
                        type: 'audience_scenario',
                        title: 'Audiens',
                        icon: Icons.groups_rounded,
                        color: AppColors.orange,
                        darkColor: AppColors.orangeDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Statistics Grid from Real SQLite
                const Text(
                  'STATISTIK KAMU',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                statsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E5E5)),
                    ),
                    child: Text(
                      'Gagal memuat statistik: $err',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (stats) {
                    final avgDisplay = stats.totalSessions > 0
                        ? stats.averageScore.toStringAsFixed(0)
                        : '-';
                    final durationDisplay = Formatters.formatDurationHuman(
                      stats.totalPracticeSeconds,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.sports_score_rounded,
                                title: 'Total Latihan',
                                value: '${stats.totalSessions}',
                                accentColor: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatCard(
                                icon: Icons.stars_rounded,
                                title: 'Rata-Rata Skor',
                                value: avgDisplay,
                                accentColor: AppColors.yellow,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.timer_rounded,
                                title: 'Waktu Pitching',
                                value: durationDisplay,
                                accentColor: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Last Session Card
                        if (stats.lastSession != null) ...[
                          const Text(
                            'SESI TERAKHIR',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          DuoCard(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AnalysisResultScreen(
                                    session: stats.lastSession!,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                ScoreBadge(
                                  score: stats.lastSession!.overallScore,
                                  size: 54,
                                  showLabel: false,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stats.lastSession!.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${Formatters.formatSecondsToMinutesSeconds(stats.lastSession!.actualDuration)} • ${Formatters.formatDate(stats.lastSession!.createdAt)}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Empty state
                          DuoCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSoft,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: AppColors.greenDark,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    'Belum ada rekaman latihan. Tekan "Mulai Latihan" untuk pitch pertamamu!',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakBadge({required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE5E5E5),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.orange,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.orangeDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemBadge({required int gems}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE5E5E5),
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.diamond_rounded,
            color: AppColors.blue,
            size: 17,
          ),
          const SizedBox(width: 4),
          Text(
            '$gems',
            style: const TextStyle(
              color: AppColors.blueDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required WidgetRef ref,
    required String type,
    required String title,
    required IconData icon,
    required Color color,
    required Color darkColor,
  }) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      bottomBorderColor: darkColor.withValues(alpha: 0.4),
      onTap: () async {
        final challengeService = ref.read(challengeServiceProvider);
        final item = await challengeService.getRandomChallenge(type: type);

        ref.read(activePracticeSetupProvider.notifier).setSetup(
              ActivePracticeSetup(
                title: 'Tantangan $title',
                mode: 'challenge',
                challengeType: type,
                selectedChallenge: item,
                preparationSeconds: 30,
                targetDuration: item.suggestedDuration,
                recordingType: 'video',
              ),
            );

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChallengeBriefScreen(challenge: item),
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
