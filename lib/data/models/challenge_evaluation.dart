import 'dart:convert';

class RequiredWordResult {
  final String word;
  final bool found;
  final bool usedMeaningfully;
  final String evidence;
  final String note;

  RequiredWordResult({
    required this.word,
    required this.found,
    required this.usedMeaningfully,
    required this.evidence,
    this.note = '',
  });

  Map<String, dynamic> toMap() => {
        'word': word,
        'found': found,
        'used_meaningfully': usedMeaningfully,
        'evidence': evidence,
        'note': note,
      };

  factory RequiredWordResult.fromMap(Map<String, dynamic> map) =>
      RequiredWordResult(
        word: map['word']?.toString() ?? '',
        found: map['found'] == true || map['found'] == 1,
        usedMeaningfully:
            map['used_meaningfully'] == true || map['used_meaningfully'] == 1,
        evidence: map['evidence']?.toString() ?? '',
        note: map['note']?.toString() ?? '',
      );
}

class TranscriptEvidenceSnippet {
  final String category;
  final String snippet;
  final String explanation;

  TranscriptEvidenceSnippet({
    required this.category,
    required this.snippet,
    required this.explanation,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'snippet': snippet,
        'explanation': explanation,
      };

  factory TranscriptEvidenceSnippet.fromMap(Map<String, dynamic> map) =>
      TranscriptEvidenceSnippet(
        category: map['category']?.toString() ?? '',
        snippet: map['snippet']?.toString() ?? '',
        explanation: map['explanation']?.toString() ?? '',
      );
}

class ChallengeEvaluation {
  final String id;
  final String sessionId;
  final double? sentenceClarityScore;
  final String? sentenceClarityReason;
  final double? coherenceScore;
  final String? coherenceReason;
  final double? relevanceScore;
  final String? relevanceReason;
  final double? audienceFitScore;
  final String? audienceFitReason;
  final List<RequiredWordResult> requiredWordsResult;
  final List<String> strengths;
  final List<String> improvements;
  final List<TranscriptEvidenceSnippet> evidence;
  final String? suggestedRevision;
  final String status; // 'completed', 'unavailable', 'failed'

  ChallengeEvaluation({
    required this.id,
    required this.sessionId,
    this.sentenceClarityScore,
    this.sentenceClarityReason,
    this.coherenceScore,
    this.coherenceReason,
    this.relevanceScore,
    this.relevanceReason,
    this.audienceFitScore,
    this.audienceFitReason,
    this.requiredWordsResult = const [],
    this.strengths = const [],
    this.improvements = const [],
    this.evidence = const [],
    this.suggestedRevision,
    this.status = 'completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'clarity_score': sentenceClarityScore,
      'clarity_reason': sentenceClarityReason,
      'coherence_score': coherenceScore,
      'coherence_reason': coherenceReason,
      'relevance_score': relevanceScore,
      'relevance_reason': relevanceReason,
      'audience_fit_score': audienceFitScore,
      'audience_fit_reason': audienceFitReason,
      'required_words_result_json': jsonEncode(
        requiredWordsResult.map((e) => e.toMap()).toList(),
      ),
      'strengths_json': jsonEncode(strengths),
      'improvements_json': jsonEncode(improvements),
      'evidence_json': jsonEncode(evidence.map((e) => e.toMap()).toList()),
      'suggested_revision': suggestedRevision,
      'status': status,
    };
  }

  factory ChallengeEvaluation.fromMap(Map<String, dynamic> map) {
    List<RequiredWordResult> parsedWords = [];
    if (map['required_words_result_json'] != null &&
        map['required_words_result_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['required_words_result_json']);
        if (decoded is List) {
          parsedWords = decoded
              .map((e) => RequiredWordResult.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }

    List<String> parsedStrengths = [];
    if (map['strengths_json'] != null &&
        map['strengths_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['strengths_json']);
        if (decoded is List) {
          parsedStrengths = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<String> parsedImprovements = [];
    if (map['improvements_json'] != null &&
        map['improvements_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['improvements_json']);
        if (decoded is List) {
          parsedImprovements = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<TranscriptEvidenceSnippet> parsedEvidence = [];
    if (map['evidence_json'] != null &&
        map['evidence_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['evidence_json']);
        if (decoded is List) {
          parsedEvidence = decoded
              .map((e) =>
                  TranscriptEvidenceSnippet.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }

    return ChallengeEvaluation(
      id: map['id']?.toString() ?? '',
      sessionId: map['session_id']?.toString() ?? '',
      sentenceClarityScore: (map['clarity_score'] as num?)?.toDouble(),
      sentenceClarityReason: map['clarity_reason']?.toString(),
      coherenceScore: (map['coherence_score'] as num?)?.toDouble(),
      coherenceReason: map['coherence_reason']?.toString(),
      relevanceScore: (map['relevance_score'] as num?)?.toDouble(),
      relevanceReason: map['relevance_reason']?.toString(),
      audienceFitScore: (map['audience_fit_score'] as num?)?.toDouble(),
      audienceFitReason: map['audience_fit_reason']?.toString(),
      requiredWordsResult: parsedWords,
      strengths: parsedStrengths,
      improvements: parsedImprovements,
      evidence: parsedEvidence,
      suggestedRevision: map['suggested_revision']?.toString(),
      status: map['status']?.toString() ?? 'completed',
    );
  }
}

