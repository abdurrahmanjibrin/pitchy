import 'package:flutter_test/flutter_test.dart';
import 'package:pitchy/services/analysis/audio_metric_analyzer.dart';

void main() {
  group('AudioMetricAnalyzer Unit Tests', () {
    test('Tokenization and word count calculation', () {
      const transcript =
          'Halo semuanya! Hari ini saya ingin menjelaskan ide penting, yang sangat bermanfaat.';
      final result = AudioMetricAnalyzer.analyze(
        transcript: transcript,
        actualDurationSeconds: 60,
      );

      expect(result.totalWords, equals(12));
      expect(result.speakingPace, equals(12.0)); // 12 words / 1 min = 12 WPM
    });

    test('WPM calculation for realistic 2-minute speech', () {
      final wordsList = List.generate(240, (i) => 'kata$i');
      final transcript = wordsList.join(' ');

      final result = AudioMetricAnalyzer.analyze(
        transcript: transcript,
        actualDurationSeconds: 120, // 2 minutes
      );

      expect(result.totalWords, equals(240));
      expect(result.speakingPace, equals(120.0)); // 240 / 2 = 120 WPM (optimal)
      expect(result.deliveryScore, greaterThanOrEqualTo(80.0));
    });

    test('Vocal, lexical, and discourse filler detection', () {
      const transcript =
          'Halo eee selamat pagi emm kami ingin presentasi anu apa namanya tentang robot nah jadi solusinya adalah ini.';
      final result = AudioMetricAnalyzer.analyze(
        transcript: transcript,
        actualDurationSeconds: 60,
      );

      expect(result.fillerCount, greaterThanOrEqualTo(5));

      final detectedWords = result.fillerStats.map((f) => f.fillerWord).toList();
      expect(detectedWords, contains('eee'));
      expect(detectedWords, contains('emm'));
      expect(detectedWords, contains('anu'));
      expect(detectedWords, contains('apa namanya'));
      expect(detectedWords, contains('jadi'));
      expect(detectedWords, contains('nah'));

      expect(result.fillerRate, greaterThan(0));
      expect(result.fillerPerMinute, greaterThan(0));
    });

    test('Empty transcript handles safely without zero division', () {
      final result = AudioMetricAnalyzer.analyze(
        transcript: '',
        actualDurationSeconds: 0,
      );

      expect(result.totalWords, equals(0));
      expect(result.speakingPace, equals(0.0));
      expect(result.fillerCount, equals(0));
      expect(result.fillerRate, equals(0.0));
      expect(result.deliveryScore, equals(0.0));
    });
  });
}

