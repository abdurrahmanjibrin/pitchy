import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/practice_repository.dart';
import '../../shared/widgets/duo_card.dart';
import '../../shared/widgets/duo_mascot_avatar.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../practice/practice_setup_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Perkembangan Latihan'),
      ),
      body: SafeArea(
        child: progressAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Gagal memuat grafik perkembangan: $err',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          data: (dataPoints) {
            if (dataPoints.isEmpty) {
              return EmptyStateView(
                icon: Icons.insights_rounded,
                title: 'Data Belum Cukup',
                message:
                    'Lakukan setidaknya satu atau dua sesi latihan untuk melihat tren perkembangan skor dan tempo bicaramu di sini.',
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

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Note DuoCard
                DuoCard(
                  child: Row(
                    children: [
                      const DuoMascotAvatar(size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Menampilkan grafik tren dari total ${dataPoints.length} sesi latihanmu. Semakin sering berlatih, semakin tajam intonasimu!',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Chart 1: Overall Score Trend (Duolingo Green)
                _buildChartContainer(
                  title: 'Tren Skor Keseluruhan',
                  subtitle: 'Skala 0 – 100 • Evaluasi AI & Vokal',
                  child: _buildScoreLineChart(dataPoints),
                ),
                const SizedBox(height: 16),

                // Chart 2: Speaking Pace (Duolingo Blue)
                _buildChartContainer(
                  title: 'Kecepatan Berbicara (WPM)',
                  subtitle: 'Zona hijau optimal adalah 100–160 WPM',
                  child: _buildWpmChart(dataPoints),
                ),
                const SizedBox(height: 16),

                // Chart 3: Filler Rate % (Duolingo Orange)
                _buildChartContainer(
                  title: 'Persentase Kata Pengisi (% Filler)',
                  subtitle: 'Semakin rendah persentase, semakin tajam pesanmu',
                  child: _buildFillerChart(dataPoints),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return DuoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }

  Widget _buildScoreLineChart(List<ProgressDataPoint> points) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      final s = points[i].score ?? 0.0;
      spots.add(FlSpot(i.toDouble(), s));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < points.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      Formatters.formatDateShort(points[idx].date),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 30,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.green,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.green.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWpmChart(List<ProgressDataPoint> points) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      final wpm = points[i].wpm ?? 0.0;
      spots.add(FlSpot(i.toDouble(), wpm));
    }

    return LineChart(
      LineChartData(
        minY: 40,
        maxY: 200,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < points.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Sesi ${idx + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 40,
              reservedSize: 32,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.blue,
            barWidth: 4,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFillerChart(List<ProgressDataPoint> points) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      final rate = points[i].fillerRate ?? 0.0;
      spots.add(FlSpot(i.toDouble(), rate));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1.5,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < points.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Sesi ${idx + 1}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 28,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.orange,
            barWidth: 4,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
