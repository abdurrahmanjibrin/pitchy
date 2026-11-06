import 'dart:convert';
import 'body_language_evaluation.dart';
import 'challenge_evaluation.dart';
import 'filler_stat.dart';

class PracticeSession {
  final String id;
  final String userId;
  final String title;
  final String? topic;
  final String mode; // 'free', 'timed', 'challenge'
  final String? challengeType; // 'random_words', 'random_theme', 'audience_scenario'
  final String? challengeId;
  final String? challengePrompt;
  final List<String> requiredWords;
  final Map<String, dynamic>? audienceProfile;
  final int preparationSeconds;
  final int? targetDuration;
  final int actualDuration;
  final String recordingType; // 'audio', 'video'
  final String? recordingPath;
  final String? transcript;
  final int? totalWords;
  final double? speakingPace; // WPM
  final int? fillerCount;
  final int? pauseCount;
  final double? averagePause;
  final double? deliveryScore;
  final double? bodyLanguageScore; // Visual / Pose & Gesture Score
  final double? contentScore;
  final double? overallScore;
  final String? aiFeedback;
  final String status; // 'draft', 'recorded', 'processing', 'completed', 'failed'
  final DateTime createdAt;

  // Associated details (lazy or eager loaded)
  final ChallengeEvaluation? evaluation;
  final BodyLanguageEvaluation? bodyLanguageEvaluation;
  final List<FillerStat> fillerStats;

  PracticeSession({
    required this.id,
    required this.userId,
    required this.title,
    this.topic,
    required this.mode,
    this.challengeType,
    this.challengeId,
    this.challengePrompt,
    this.requiredWords = const [],
    this.audienceProfile,
    this.preparationSeconds = 0,
    this.targetDuration,
    required this.actualDuration,
    this.recordingType = 'audio',
    this.recordingPath,
    this.transcript,
    this.totalWords,
    this.speakingPace,
    this.fillerCount,
    this.pauseCount,
    this.averagePause,
    this.deliveryScore,
    this.bodyLanguageScore,
    this.contentScore,
    this.overallScore,
    this.aiFeedback,
    this.status = 'completed',
    required this.createdAt,
    this.evaluation,
    this.bodyLanguageEvaluation,
    this.fillerStats = const [],
  });

  double get durationMinutes =>
      actualDuration > 0 ? (actualDuration / 60.0) : 0.0;

  double? get fillerRate {
    if (totalWords == null || totalWords == 0 || fillerCount == null) {
      return null;
    }
    return (fillerCount! / totalWords!) * 100.0;
  }

  double? get fillerPerMinute {
    if (durationMinutes <= 0 || fillerCount == null) return null;
    return fillerCount! / durationMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'topic': topic,
      'mode': mode,
      'challenge_type': challengeType,
      'challenge_id': challengeId,
      'challenge_prompt': challengePrompt,
      'required_words_json': jsonEncode(requiredWords),
      'audience_profile_json':
          audienceProfile != null ? jsonEncode(audienceProfile) : null,
      'preparation_seconds': preparationSeconds,
      'target_duration': targetDuration,
      'actual_duration': actualDuration,
      'recording_type': recordingType,
      'recording_path': recordingPath,
      'transcript': transcript,
      'total_words': totalWords,
      'speaking_pace': speakingPace,
      'filler_count': fillerCount,
      'pause_count': pauseCount,
      'average_pause': averagePause,
      'delivery_score': deliveryScore,
      'body_language_score': bodyLanguageScore,
      'body_language_eval_json': bodyLanguageEvaluation != null
          ? jsonEncode(bodyLanguageEvaluation!.toMap())
          : null,
      'content_score': contentScore,
      'overall_score': overallScore,
      'ai_feedback': aiFeedback,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PracticeSession.fromMap(
    Map<String, dynamic> map, {
    ChallengeEvaluation? evaluation,
    List<FillerStat> fillerStats = const [],
  }) {
    List<String> parsedWords = [];
    if (map['required_words_json'] != null &&
        map['required_words_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['required_words_json']);
        if (decoded is List) {
          parsedWords = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    Map<String, dynamic>? parsedAudience;
    if (map['audience_profile_json'] != null &&
        map['audience_profile_json'].toString().isNotEmpty) {
      try {
        parsedAudience = jsonDecode(map['audience_profile_json']);
      } catch (_) {}
    }

    BodyLanguageEvaluation? parsedBodyLanguage;
    if (map['body_language_eval_json'] != null &&
        map['body_language_eval_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['body_language_eval_json']);
        if (decoded is Map<String, dynamic>) {
          parsedBodyLanguage = BodyLanguageEvaluation.fromMap(decoded);
        }
      } catch (_) {}
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(map['created_at']);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return PracticeSession(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? 'local_user',
      title: map['title']?.toString() ?? 'Latihan',
      topic: map['topic']?.toString(),
      mode: map['mode']?.toString() ?? 'free',
      challengeType: map['challenge_type']?.toString(),
      challengeId: map['challenge_id']?.toString(),
      challengePrompt: map['challenge_prompt']?.toString(),
      requiredWords: parsedWords,
      audienceProfile: parsedAudience,
      preparationSeconds: (map['preparation_seconds'] as num?)?.toInt() ?? 0,
      targetDuration: (map['target_duration'] as num?)?.toInt(),
      actualDuration: (map['actual_duration'] as num?)?.toInt() ?? 0,
      recordingType: map['recording_type']?.toString() ?? 'audio',
      recordingPath: map['recording_path']?.toString(),
      transcript: map['transcript']?.toString(),
      totalWords: (map['total_words'] as num?)?.toInt(),
      speakingPace: (map['speaking_pace'] as num?)?.toDouble(),
      fillerCount: (map['filler_count'] as num?)?.toInt(),
      pauseCount: (map['pause_count'] as num?)?.toInt(),
      averagePause: (map['average_pause'] as num?)?.toDouble(),
      deliveryScore: (map['delivery_score'] as num?)?.toDouble(),
      bodyLanguageScore: (map['body_language_score'] as num?)?.toDouble(),
      bodyLanguageEvaluation: parsedBodyLanguage,
      contentScore: (map['content_score'] as num?)?.toDouble(),
      overallScore: (map['overall_score'] as num?)?.toDouble(),
      aiFeedback: map['ai_feedback']?.toString(),
      status: map['status']?.toString() ?? 'completed',
      createdAt: parsedDate,
      evaluation: evaluation,
      fillerStats: fillerStats,
    );
  }

  PracticeSession copyWith({
    String? title,
    String? topic,
    String? status,
    String? transcript,
    int? totalWords,
    double? speakingPace,
    int? fillerCount,
    int? pauseCount,
    double? averagePause,
    double? deliveryScore,
    double? bodyLanguageScore,
    BodyLanguageEvaluation? bodyLanguageEvaluation,
    double? contentScore,
    double? overallScore,
    String? aiFeedback,
    ChallengeEvaluation? evaluation,
    List<FillerStat>? fillerStats,
  }) {
    return PracticeSession(
      id: id,
      userId: userId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      mode: mode,
      challengeType: challengeType,
      challengeId: challengeId,
      challengePrompt: challengePrompt,
      requiredWords: requiredWords,
      audienceProfile: audienceProfile,
      preparationSeconds: preparationSeconds,
      targetDuration: targetDuration,
      actualDuration: actualDuration,
      recordingType: recordingType,
      recordingPath: recordingPath,
      transcript: transcript ?? this.transcript,
      totalWords: totalWords ?? this.totalWords,
      speakingPace: speakingPace ?? this.speakingPace,
      fillerCount: fillerCount ?? this.fillerCount,
      pauseCount: pauseCount ?? this.pauseCount,
      averagePause: averagePause ?? this.averagePause,
      deliveryScore: deliveryScore ?? this.deliveryScore,
      bodyLanguageScore: bodyLanguageScore ?? this.bodyLanguageScore,
      bodyLanguageEvaluation:
          bodyLanguageEvaluation ?? this.bodyLanguageEvaluation,
      contentScore: contentScore ?? this.contentScore,
      overallScore: overallScore ?? this.overallScore,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      status: status ?? this.status,
      createdAt: createdAt,
      evaluation: evaluation ?? this.evaluation,
      fillerStats: fillerStats ?? this.fillerStats,
    );
  }
}

