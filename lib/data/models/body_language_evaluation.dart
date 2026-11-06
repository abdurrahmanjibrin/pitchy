import 'dart:convert';

class BodyLanguageAlert {
  final int timestampSeconds;
  final String message;
  final String type; // 'positive', 'warning', 'neutral'

  BodyLanguageAlert({
    required this.timestampSeconds,
    required this.message,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestampSeconds,
        'message': message,
        'type': type,
      };

  factory BodyLanguageAlert.fromMap(Map<String, dynamic> map) =>
      BodyLanguageAlert(
        timestampSeconds: (map['timestamp'] as num?)?.toInt() ?? 0,
        message: map['message']?.toString() ?? '',
        type: map['type']?.toString() ?? 'neutral',
      );
}

class BodyLanguageEvaluation {
  final double overallScore; // 0 - 100
  final double postureScore; // 0 - 100
  final String postureFeedback;
  final double gestureScore; // 0 - 100
  final double strikeZonePercentage; // 0 - 100%
  final String gestureFeedback;
  final double stabilityScore; // 0 - 100
  final String stabilityFeedback;
  final double eyeContactScore; // 0 - 100
  final String eyeContactFeedback;
  final List<BodyLanguageAlert> alerts;
  final List<String> actionableTips;

  BodyLanguageEvaluation({
    required this.overallScore,
    required this.postureScore,
    required this.postureFeedback,
    required this.gestureScore,
    required this.strikeZonePercentage,
    required this.gestureFeedback,
    required this.stabilityScore,
    required this.stabilityFeedback,
    required this.eyeContactScore,
    required this.eyeContactFeedback,
    this.alerts = const [],
    this.actionableTips = const [],
  });

  Map<String, dynamic> toMap() => {
        'overall_score': overallScore,
        'posture_score': postureScore,
        'posture_feedback': postureFeedback,
        'gesture_score': gestureScore,
        'strike_zone_percentage': strikeZonePercentage,
        'gesture_feedback': gestureFeedback,
        'stability_score': stabilityScore,
        'stability_feedback': stabilityFeedback,
        'eye_contact_score': eyeContactScore,
        'eye_contact_feedback': eyeContactFeedback,
        'alerts_json': jsonEncode(alerts.map((a) => a.toMap()).toList()),
        'actionable_tips_json': jsonEncode(actionableTips),
      };

  factory BodyLanguageEvaluation.fromMap(Map<String, dynamic> map) {
    List<BodyLanguageAlert> parsedAlerts = [];
    if (map['alerts_json'] != null &&
        map['alerts_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['alerts_json']);
        if (decoded is List) {
          parsedAlerts = decoded
              .map((e) => BodyLanguageAlert.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }

    List<String> parsedTips = [];
    if (map['actionable_tips_json'] != null &&
        map['actionable_tips_json'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['actionable_tips_json']);
        if (decoded is List) {
          parsedTips = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return BodyLanguageEvaluation(
      overallScore: (map['overall_score'] as num?)?.toDouble() ?? 80.0,
      postureScore: (map['posture_score'] as num?)?.toDouble() ?? 80.0,
      postureFeedback: map['posture_feedback']?.toString() ?? '',
      gestureScore: (map['gesture_score'] as num?)?.toDouble() ?? 80.0,
      strikeZonePercentage:
          (map['strike_zone_percentage'] as num?)?.toDouble() ?? 75.0,
      gestureFeedback: map['gesture_feedback']?.toString() ?? '',
      stabilityScore: (map['stability_score'] as num?)?.toDouble() ?? 80.0,
      stabilityFeedback: map['stability_feedback']?.toString() ?? '',
      eyeContactScore: (map['eye_contact_score'] as num?)?.toDouble() ?? 80.0,
      eyeContactFeedback: map['eye_contact_feedback']?.toString() ?? '',
      alerts: parsedAlerts,
      actionableTips: parsedTips,
    );
  }
}

