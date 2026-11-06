import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
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
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Greeting Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $userName 👋',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Siap melatih kemampuan pitching hari ini?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Icon(
                        Icons.mic_none_rounded,
                        color: AppColors.secondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Hero Call to Action
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🎯 Mode Tantangan Spontan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.secondaryLight,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Asah Spontanitas & Kelogisan Pitching',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih kata wajib acak, tema spontan, atau sesuaikan gaya bicara dengan profil audiens.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const PracticeSetupScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Mulai Latihan'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              // Quick Challenge: pick random challenge directly
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
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Text('Tantangan Cepat'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Grid from Real SQLite
                const Text(
                  'Ringkasan Latihan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                statsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (err, stack) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
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
                                icon: Icons.folder_open_rounded,
                                title: 'Total Sesi',
                                value: '${stats.totalSessions}',
                                accentColor: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                icon: Icons.speed_rounded,
                                title: 'Rata-Rata Skor',
                                value: avgDisplay,
                                accentColor: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.timer_outlined,
                                title: 'Total Waktu Latihan',
                                value: durationDisplay,
                                accentColor: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Last Session Card
                        if (stats.lastSession != null) ...[
                          const Text(
                            'Sesi Terakhir',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AnalysisResultScreen(
                                    session: stats.lastSession!,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.surfaceBorder,
                                ),
                              ),
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${Formatters.formatSecondsToMinutesSeconds(stats.lastSession!.actualDuration)} • ${Formatters.formatDate(stats.lastSession!.createdAt)}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
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
                          ),
                        ] else ...[
                          // Empty state
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.surfaceBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.record_voice_over_outlined,
                                    color: AppColors.secondary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    'Belum ada rekaman latihan. Tekan "Mulai Latihan" untuk memulai pitch pertamamu!',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.4,
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
}
