import 'package:flutter_test/flutter_test.dart';
import 'package:pitchy/data/models/body_language_evaluation.dart';
import 'package:pitchy/data/models/challenge_evaluation.dart';
import 'package:pitchy/data/models/challenge_item.dart';
import 'package:pitchy/data/models/practice_session.dart';

void main() {
  group('Models & Serialization Unit Tests', () {
    test('BodyLanguageEvaluation serialization and deserialization', () {
      final bodyEval = BodyLanguageEvaluation(
        overallScore: 86.5,
        postureScore: 90.0,
        postureFeedback: 'Postur ekspansif sangat baik',
        gestureScore: 85.0,
        strikeZonePercentage: 82.0,
        gestureFeedback: 'Gestur tangan konsisten di Strike Zone',
        stabilityScore: 88.0,
        stabilityFeedback: 'Kuda-kuda stabil',
        eyeContactScore: 83.0,
        eyeContactFeedback: 'Kontak mata terfokus',
        alerts: [
          BodyLanguageAlert(
            timestampSeconds: 12,
            message: 'Bahu condong ke depan',
            type: 'warning',
          ),
        ],
        actionableTips: [
          'Pertahankan posisi tangan di depan dada',
        ],
      );

      final map = bodyEval.toMap();
      final restored = BodyLanguageEvaluation.fromMap(map);

      expect(restored.overallScore, equals(86.5));
      expect(restored.postureScore, equals(90.0));
      expect(restored.strikeZonePercentage, equals(82.0));
      expect(restored.alerts.length, equals(1));
      expect(restored.alerts.first.timestampSeconds, equals(12));
      expect(restored.actionableTips.first,
          equals('Pertahankan posisi tangan di depan dada'));
    });

    test('PracticeSession serialization with body language', () {
      final bodyEval = BodyLanguageEvaluation(
        overallScore: 85.0,
        postureScore: 88.0,
        postureFeedback: 'Bagus',
        gestureScore: 82.0,
        strikeZonePercentage: 80.0,
        gestureFeedback: 'Stabil',
        stabilityScore: 84.0,
        stabilityFeedback: 'Anchored',
        eyeContactScore: 86.0,
        eyeContactFeedback: 'Fokus',
      );

      final session = PracticeSession(
        id: 'sess_body',
        userId: 'Mahasiswa',
        title: 'Pitching Kamera',
        mode: 'challenge',
        actualDuration: 90,
        recordingType: 'video',
        deliveryScore: 82.0,
        bodyLanguageScore: 85.0,
        bodyLanguageEvaluation: bodyEval,
        contentScore: 88.0,
        overallScore: 85.0,
        createdAt: DateTime.now(),
      );

      final map = session.toMap();
      final restored = PracticeSession.fromMap(map);

      expect(restored.id, equals('sess_body'));
      expect(restored.recordingType, equals('video'));
      expect(restored.bodyLanguageScore, equals(85.0));
      expect(restored.bodyLanguageEvaluation, isNotNull);
      expect(restored.bodyLanguageEvaluation!.overallScore, equals(85.0));
    });
    test('ChallengeItem serialization and deserialization', () {
      final item = ChallengeItem(
        id: 'test_rw',
        type: 'random_words',
        prompt: 'Gunakan kata berikut',
        requiredWords: ['kopi', 'robot', 'kampus'],
        difficulty: 'Medium',
      );

      final map = item.toMap();
      final restored = ChallengeItem.fromMap(map);

      expect(restored.id, equals('test_rw'));
      expect(restored.type, equals('random_words'));
      expect(restored.requiredWords, equals(['kopi', 'robot', 'kampus']));
    });

    test('ChallengeEvaluation serialization and deserialization', () {
      final eval = ChallengeEvaluation(
        id: 'eval_01',
        sessionId: 'session_01',
        sentenceClarityScore: 88.0,
        sentenceClarityReason: 'Struktur lugas',
        coherenceScore: 85.0,
        coherenceReason: 'Alur runtut',
        relevanceScore: 90.0,
        relevanceReason: 'Topik tepat',
        requiredWordsResult: [
          RequiredWordResult(
            word: 'kopi',
            found: true,
            usedMeaningfully: true,
            evidence: 'sambil minum kopi',
            note: 'digunakan secara alami',
          ),
        ],
        strengths: ['Pembuka persuasif'],
        improvements: ['Pertegas penutup'],
      );

      final map = eval.toMap();
      final restored = ChallengeEvaluation.fromMap(map);

      expect(restored.sessionId, equals('session_01'));
      expect(restored.sentenceClarityScore, equals(88.0));
      expect(restored.requiredWordsResult.first.word, equals('kopi'));
      expect(restored.requiredWordsResult.first.found, isTrue);
      expect(restored.strengths.first, equals('Pembuka persuasif'));
    });

    test('PracticeSession metrics getters', () {
      final session = PracticeSession(
        id: 'sess_1',
        userId: 'Mahasiswa',
        title: 'Pitching 1',
        mode: 'challenge',
        actualDuration: 120, // 2 minutes
        totalWords: 240,
        fillerCount: 6,
        createdAt: DateTime.now(),
      );

      expect(session.durationMinutes, equals(2.0));
      expect(session.fillerRate, equals(2.5)); // 6 / 240 * 100% = 2.5%
      expect(session.fillerPerMinute, equals(3.0)); // 6 / 2 mins = 3 / min
    });
  });
}
