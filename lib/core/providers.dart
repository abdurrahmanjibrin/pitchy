import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/datasources/local_database.dart';
import '../data/models/challenge_item.dart';
import '../data/models/practice_session.dart';
import '../data/repositories/practice_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/ai/ai_content_evaluator.dart';
import '../services/challenge/challenge_service.dart';
import '../services/playback/audio_playback_service.dart';
import '../services/recording/audio_recording_service.dart';
import '../services/transcription/stt_service.dart';

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main.dart first');
});

// User Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserRepository(prefs);
});

// Database Provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase.instance;
});

// Practice Repository Provider
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return PracticeRepository(localDb: db);
});

// Challenge Service Provider
final challengeServiceProvider = Provider<ChallengeService>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return ChallengeService(localDb: db);
});

// Audio Recording Service Provider
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// Audio Playback Service Provider
final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

// STT Service Provider
final sttServiceProvider = Provider<SttService>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final userKey = userRepo.getApiKey();
  final useMock = userRepo.useLocalSttFallback();

  if (useMock) {
    return OfflineMockSttService();
  }

  // Use configured key from user settings or compile-time env
  const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  final effectiveKey = (userKey != null && userKey.isNotEmpty) ? userKey : envKey;

  return GeminiSttService(apiKey: effectiveKey);
});

// AI Content Evaluator Provider
final aiContentEvaluatorProvider = Provider<AiContentEvaluator>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final userKey = userRepo.getApiKey();
  final useMock = userRepo.useLocalSttFallback();

  if (useMock) {
    return RuleBasedContentEvaluator();
  }

  const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  final effectiveKey = (userKey != null && userKey.isNotEmpty) ? userKey : envKey;

  return GeminiContentEvaluator(apiKey: effectiveKey);
});

// Dashboard Stats Provider
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return await repo.getDashboardStats();
});

// Practice History Filter State
class HistoryFilterState {
  final String mode; // 'all', 'free', 'timed', 'challenge'
  final String challengeType; // 'all', 'random_words', 'random_theme', 'audience_scenario'

  const HistoryFilterState({
    this.mode = 'all',
    this.challengeType = 'all',
  });

  HistoryFilterState copyWith({String? mode, String? challengeType}) {
    return HistoryFilterState(
      mode: mode ?? this.mode,
      challengeType: challengeType ?? this.challengeType,
    );
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();

  void setFilter(HistoryFilterState state) => this.state = state;
}

final historyFilterProvider =
    NotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
  HistoryFilterNotifier.new,
);

// Practice History List Provider
final practiceHistoryProvider =
    FutureProvider.autoDispose<List<PracticeSession>>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  final filter = ref.watch(historyFilterProvider);

  return await repo.getAllSessions(
    modeFilter: filter.mode,
    challengeTypeFilter: filter.challengeType,
  );
});

// Progress Data Provider
final progressDataProvider =
    FutureProvider.autoDispose<List<ProgressDataPoint>>((ref) async {
  final repo = ref.watch(practiceRepositoryProvider);
  return await repo.getProgressData();
});

// Active Practice Setup State (for passing configuration along the flow)
class ActivePracticeSetup {
  final String title;
  final String? topic;
  final String mode; // 'free', 'timed', 'challenge'
  final String? challengeType; // 'random_words', 'random_theme', 'audience_scenario'
  final ChallengeItem? selectedChallenge;
  final int preparationSeconds;
  final int? targetDuration;
  final String recordingType; // 'audio', 'video'

  const ActivePracticeSetup({
    this.title = 'Sesi Latihan Pitching',
    this.topic,
    this.mode = 'challenge',
    this.challengeType = 'random_words',
    this.selectedChallenge,
    this.preparationSeconds = 30,
    this.targetDuration = 120,
    this.recordingType = 'audio',
  });

  ActivePracticeSetup copyWith({
    String? title,
    String? topic,
    String? mode,
    String? challengeType,
    ChallengeItem? selectedChallenge,
    int? preparationSeconds,
    int? targetDuration,
    String? recordingType,
  }) {
    return ActivePracticeSetup(
      title: title ?? this.title,
      topic: topic ?? this.topic,
      mode: mode ?? this.mode,
      challengeType: challengeType ?? this.challengeType,
      selectedChallenge: selectedChallenge ?? this.selectedChallenge,
      preparationSeconds: preparationSeconds ?? this.preparationSeconds,
      targetDuration: targetDuration ?? this.targetDuration,
      recordingType: recordingType ?? this.recordingType,
    );
  }
}

class ActivePracticeSetupNotifier extends Notifier<ActivePracticeSetup> {
  @override
  ActivePracticeSetup build() => const ActivePracticeSetup();

  void setSetup(ActivePracticeSetup setup) => state = setup;
  void update(ActivePracticeSetup Function(ActivePracticeSetup) fn) =>
      state = fn(state);
}

final activePracticeSetupProvider =
    NotifierProvider<ActivePracticeSetupNotifier, ActivePracticeSetup>(
  ActivePracticeSetupNotifier.new,
);
