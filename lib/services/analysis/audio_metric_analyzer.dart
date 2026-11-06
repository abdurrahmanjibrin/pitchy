import '../../core/constants/app_constants.dart';
import '../../data/models/filler_stat.dart';

class AudioMetricAnalysisResult {
  final int totalWords;
  final double speakingPace; // WPM
  final int fillerCount;
  final double fillerRate; // percentage
  final double fillerPerMinute;
  final List<FillerStat> fillerStats;
  final int? pauseCount;
  final double? averagePauseSeconds;
  final double deliveryScore;

  AudioMetricAnalysisResult({
    required this.totalWords,
    required this.speakingPace,
    required this.fillerCount,
    required this.fillerRate,
    required this.fillerPerMinute,
    required this.fillerStats,
    this.pauseCount,
    this.averagePauseSeconds,
    required this.deliveryScore,
  });
}

class AudioMetricAnalyzer {
  static AudioMetricAnalysisResult analyze({
    required String transcript,
    required int actualDurationSeconds,
    String sessionId = '',
  }) {
    if (transcript.trim().isEmpty || actualDurationSeconds <= 0) {
      return AudioMetricAnalysisResult(
        totalWords: 0,
        speakingPace: 0.0,
        fillerCount: 0,
        fillerRate: 0.0,
        fillerPerMinute: 0.0,
        fillerStats: [],
        deliveryScore: 0.0,
      );
    }

    final durationMinutes = actualDurationSeconds / 60.0;

    // 1. Text tokenization & word count
    final rawTokens = transcript
        .replaceAll(RegExp(r'[^\w\s\-]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.trim().isNotEmpty)
        .toList();

    final totalWords = rawTokens.length;

    // 2. WPM Calculation
    final wpm = durationMinutes > 0 ? (totalWords / durationMinutes) : 0.0;

    // 3. Filler Words Detection
    final lowerTranscript = transcript.toLowerCase();
    final lowerTokens = rawTokens.map((t) => t.toLowerCase()).toList();

    final Map<String, int> fillerOccurrences = {};

    // Check multi-word lexical fillers first
    final multiWordFillers =
        AppConstants.lexicalFillers.where((f) => f.contains(' ')).toList();

    for (final phrase in multiWordFillers) {
      final matches = RegExp('\\b${RegExp.escape(phrase)}\\b')
          .allMatches(lowerTranscript)
          .length;
      if (matches > 0) {
        fillerOccurrences[phrase] = matches;
      }
    }

    // Check single-word fillers
    final singleWordFillers = AppConstants.allTargetFillers
        .where((f) => !f.contains(' '))
        .toSet();

    for (final token in lowerTokens) {
      if (singleWordFillers.contains(token)) {
        fillerOccurrences[token] = (fillerOccurrences[token] ?? 0) + 1;
      }
    }

    int totalFillerCount = 0;
    final List<FillerStat> fillerStats = [];

    fillerOccurrences.forEach((word, count) {
      totalFillerCount += count;
      fillerStats.add(FillerStat(
        sessionId: sessionId,
        fillerWord: word,
        count: count,
      ));
    });

    // Sort fillers descending by count
    fillerStats.sort((a, b) => b.count.compareTo(a.count));

    final fillerRate =
        totalWords > 0 ? (totalFillerCount / totalWords) * 100.0 : 0.0;
    final fillerPerMinute =
        durationMinutes > 0 ? (totalFillerCount / durationMinutes) : 0.0;

    // 4. Delivery Score Calculation
    // Fluency score
    double fluencyScore;
    if (wpm >= 110 && wpm <= 155) {
      fluencyScore = 100.0;
    } else if (wpm >= 95 && wpm < 110) {
      fluencyScore = 85.0 + (wpm - 95) * 1.0;
    } else if (wpm > 155 && wpm <= 175) {
      fluencyScore = 100.0 - (wpm - 155) * 1.0;
    } else if (wpm >= 75 && wpm < 95) {
      fluencyScore = 65.0 + (wpm - 75) * 1.0;
    } else if (wpm > 175 && wpm <= 195) {
      fluencyScore = 80.0 - (wpm - 175) * 1.5;
    } else {
      fluencyScore = 50.0;
    }

    // Filler score
    double fillerScore;
    if (fillerRate <= 1.5) {
      fillerScore = 100.0;
    } else if (fillerRate <= 3.5) {
      fillerScore = 90.0 - (fillerRate - 1.5) * 5.0;
    } else if (fillerRate <= 6.0) {
      fillerScore = 80.0 - (fillerRate - 3.5) * 6.0;
    } else if (fillerRate <= 10.0) {
      fillerScore = 65.0 - (fillerRate - 6.0) * 5.0;
    } else {
      fillerScore = (45.0 - (fillerRate - 10.0) * 2.0).clamp(25.0, 45.0);
    }

    final deliveryScore =
        ((fluencyScore * 0.55) + (fillerScore * 0.45)).clamp(0.0, 100.0);

    return AudioMetricAnalysisResult(
      totalWords: totalWords,
      speakingPace: double.parse(wpm.toStringAsFixed(1)),
      fillerCount: totalFillerCount,
      fillerRate: double.parse(fillerRate.toStringAsFixed(1)),
      fillerPerMinute: double.parse(fillerPerMinute.toStringAsFixed(1)),
      fillerStats: fillerStats,
      deliveryScore: double.parse(deliveryScore.toStringAsFixed(1)),
    );
  }
}

