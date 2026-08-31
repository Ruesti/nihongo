import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/journey_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('root shows JourneyHome (not the lesson grid) when onboarded',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        onboardingCompleteProvider.overrideWith((ref) => true),
        learningDbProvider.overrideWith((ref) => db),
      ],
      child: const NihongoApp(),
    ));
    // JourneyHome has no infinite animation, so settling is safe.
    await tester.pumpAndSettle();

    expect(find.byType(JourneyHome), findsOneWidget);
    expect(find.text('Lektionen'), findsNothing);
  });
}
