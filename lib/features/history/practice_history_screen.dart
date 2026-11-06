import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/practice_session.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/score_badge.dart';
import '../practice/practice_setup_screen.dart';
import '../result/analysis_result_screen.dart';

class PracticeHistoryScreen extends ConsumerWidget {
  const PracticeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(practiceHistoryProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Latihan'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    isSelected: filter.challengeType == 'all' && filter.mode == 'all',
                    onTap: () {
                      ref.read(historyFilterProvider.notifier).setFilter(
                          const HistoryFilterState(mode: 'all', challengeType: 'all'));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Random Words',
                    isSelected: filter.challengeType == 'random_words',
                    onTap: () {
                      ref.read(historyFilterProvider.notifier).setFilter(
                          const HistoryFilterState(
                              mode: 'challenge', challengeType: 'random_words'));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Random Theme',
                    isSelected: filter.challengeType == 'random_theme',
                    onTap: () {
                      ref.read(historyFilterProvider.notifier).setFilter(
                          const HistoryFilterState(
                              mode: 'challenge', challengeType: 'random_theme'));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Audience Scenario',
                    isSelected: filter.challengeType == 'audience_scenario',
                    onTap: () {
                      ref.read(historyFilterProvider.notifier).setFilter(
                          const HistoryFilterState(
                              mode: 'challenge',
                              challengeType: 'audience_scenario'));
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Latihan Bebas',
                    isSelected: filter.mode == 'free',
                    onTap: () {
                      ref.read(historyFilterProvider.notifier).setFilter(
                          const HistoryFilterState(mode: 'free', challengeType: 'all'));
                    },
                  ),
                ],
              ),
            ),

            // Sessions List
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Gagal memuat riwayat: $err',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.history_rounded,
                      title: 'Belum Ada Riwayat',
                      message:
                          'Sesi latihan yang kamu simpan akan tampil di sini untuk memantau peningkatan berbicara.',
                      buttonText: 'Mulai Latihan',
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PracticeSetupScreen(),
                          ),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = sessions[index];

                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: const Text('Hapus Sesi Ini?'),
                              content: Text(
                                'Sesi "${item.title}" beserta rekaman audio dan evaluasinya akan dihapus permanen.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  ),
                                  child: const Text('Hapus'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          final repo = ref.read(practiceRepositoryProvider);
                          await repo.deleteSession(item.id);
                          ref.invalidate(practiceHistoryProvider);
                          ref.invalidate(dashboardStatsProvider);
                          ref.invalidate(progressDataProvider);
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnalysisResultScreen(session: item),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                ScoreBadge(
                                  score: item.overallScore,
                                  size: 52,
                                  showLabel: false,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
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
                                        '${_getModeLabel(item)} • ${Formatters.formatSecondsToMinutesSeconds(item.actualDuration)}',
                                        style: const TextStyle(
                                          color: AppColors.secondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.formatDate(item.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11,
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getModeLabel(PracticeSession s) {
    if (s.mode == 'challenge') {
      switch (s.challengeType) {
        case 'random_words':
          return 'Random Words';
        case 'random_theme':
          return 'Random Theme';
        case 'audience_scenario':
          return 'Audience Scenario';
        default:
          return 'Challenge';
      }
    }
    return s.mode == 'timed' ? 'Target Waktu' : 'Latihan Bebas';
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
