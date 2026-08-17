import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('beginner path: welcome → method → placement → finished',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    var finished = false;

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingFlow(onFinished: () => finished = true),
      ),
    ));

    // Welcome
    expect(find.text('Willkommen.'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Method
    expect(find.textContaining('Kein Punktesammeln'), findsOneWidget);
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();

    // Placement — choose "from zero"
    expect(find.text('Wo stehst du?'), findsOneWidget);
    await tester.tap(find.text('Ich fange bei null an'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });
}
