import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('StoryRoute wires the pilot reader from the on-ramp providers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(() async => db.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(db)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();

    // The reader mounted (its tap-to-advance panel is present).
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });
}
