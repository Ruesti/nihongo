import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/home/home_screen.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('incomplete onboarding redirects the root to the flow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith((ref) => false),
        learningDbProvider.overrideWith((ref) => db),
      ],
      child: const NihongoApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingFlow), findsOneWidget);
  });

  testWidgets(
      'completing onboarding escapes the redirect loop and reaches Home',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith((ref) => false),
        learningDbProvider.overrideWith((ref) => db),
      ],
      child: const NihongoApp(),
    ));
    await tester.pumpAndSettle();

    // Confirms the redirect loop bug is fixed: previously the provider was
    // a static `Provider<bool>` fixed at boot, so `markComplete` writing
    // SharedPreferences had no in-memory effect and the router bounced the
    // user straight back to /onboarding after `ctx.go('/')`. Driving the
    // whole beginner path end-to-end (rather than asserting on the provider
    // value directly) proves the user actually lands on Home, not just that
    // the flag flipped.
    expect(find.byType(OnboardingFlow), findsOneWidget);

    // Welcome → Method (tap by widget type/order to stay locale-agnostic;
    // both steps expose exactly one FilledButton "Continue" CTA).
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    // Placement step: "I'm starting from zero" is the first (FilledButton)
    // of the two placement options; the second ("I already know some") is
    // an OutlinedButton.
    await tester.tap(find.byType(FilledButton).first);
    // Not pumpAndSettle: once Home is reached, its mascot runs an infinite
    // `AnimationController.repeat(reverse: true)` (see MascotWidget), which
    // never stops scheduling frames — pumpAndSettle would hang until its own
    // timeout. Instead pump in bounded steps, long enough for `_finish`'s
    // async work (DB write, SharedPreferences, provider flip, navigation)
    // and Home's data providers to resolve.
    await tester.pump();
    for (var i = 0;
        i < 20 && find.byType(OnboardingFlow).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(OnboardingFlow), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
