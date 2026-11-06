import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/main_navigation_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PitchyApp(),
    ),
  );
}

class PitchyApp extends ConsumerWidget {
  const PitchyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRepo = ref.watch(userRepositoryProvider);
    final isOnboarded = userRepo.isOnboardingCompleted();

    return MaterialApp(
      title: 'PITCHY — AI Presentation Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isOnboarded
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    );
  }
}
