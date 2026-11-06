import 'dart:convert';

class ChallengeItem {
  final String id;
  final String type; // 'random_words', 'random_theme', 'audience_scenario'
  final String prompt;
  final List<String> requiredWords;
  final Map<String, dynamic>? audienceProfile;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String category;
  final int suggestedDuration;
  final bool isActive;

  ChallengeItem({
    required this.id,
    required this.type,
    required this.prompt,
    this.requiredWords = const [],
    this.audienceProfile,
    this.difficulty = 'Medium',
    this.category = 'Umum',
    this.suggestedDuration = 120,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'prompt': prompt,
      'required_words_json': jsonEncode(requiredWords),
      'audience_profile_json':
          audienceProfile != null ? jsonEncode(audienceProfile) : null,
      'difficulty': difficulty,
      'category': category,
      'suggested_duration': suggestedDuration,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ChallengeItem.fromMap(Map<String, dynamic> map) {
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

    return ChallengeItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'random_words',
      prompt: map['prompt']?.toString() ?? '',
      requiredWords: parsedWords,
      audienceProfile: parsedAudience,
      difficulty: map['difficulty']?.toString() ?? 'Medium',
      category: map['category']?.toString() ?? 'Umum',
      suggestedDuration: map['suggested_duration'] is int
          ? map['suggested_duration']
          : int.tryParse(map['suggested_duration']?.toString() ?? '120') ?? 120,
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
    );
  }
}

