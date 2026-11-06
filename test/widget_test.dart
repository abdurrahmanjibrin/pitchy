import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pitchy/core/providers.dart';
import 'package:pitchy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PitchyApp smoke test renders onboarding or dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'pitchy_onboarding_completed': false,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const PitchyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PITCHY'), findsOneWidget);
    expect(find.text('Latih Pitching Spontan'), findsOneWidget);
  });
}
