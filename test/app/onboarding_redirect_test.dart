import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
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
}
