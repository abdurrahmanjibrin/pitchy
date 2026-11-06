class AppConstants {
  static const String appName = 'PITCHY';
  static const String appTagline = 'AI Presentation Coach';

  // Storage Keys
  static const String prefUserName = 'pitchy_user_name';
  static const String prefOnboardingCompleted = 'pitchy_onboarding_completed';
  static const String prefApiKey = 'pitchy_custom_api_key';
  static const String prefUseLocalSttFallback = 'pitchy_use_local_stt_fallback';

  // Default Filler Words (Indonesian)
  static const List<String> vocalFillers = [
    'eee',
    'ee',
    'e',
    'emm',
    'em',
    'hmm',
    'hm',
    'aa',
    'ah',
    'uh',
    'umm',
    'um',
  ];

  static const List<String> lexicalFillers = [
    'anu',
    'apa namanya',
    'apa itu',
    'kayak',
    'gimana ya',
    'gitu ya',
  ];

  static const List<String> discourseMarkers = [
    'jadi',
    'nah',
    'sebenarnya',
    'terus',
    'mungkin',
  ];

  // All target fillers for detection
  static List<String> get allTargetFillers => [
        ...vocalFillers,
        ...lexicalFillers,
        ...discourseMarkers,
      ];

  // WPM Reference
  static const double wpmSlowThreshold = 100.0;
  static const double wpmRecommendedMin = 100.0;
  static const double wpmRecommendedMax = 160.0;
  static const double wpmFastThreshold = 180.0;

  // Duration Options (in seconds)
  static const List<int> prepDurations = [15, 30, 60];
  static const List<int> practiceDurations = [60, 120, 180, 300]; // 1, 2, 3, 5 min

  // Default Weights for Scoring (PRD Section 6.9)
  static const double weightFiller = 0.15;
  static const double weightFluency = 0.20;
  static const double weightSentenceStructure = 0.25;
  static const double weightChallengeRelevance = 0.20;
  static const double weightAudienceAdaptation = 0.20;
}

