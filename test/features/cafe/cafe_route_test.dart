import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';

void main() {
  testWidgets('CafeRoute builds the café from the on-ramp providers',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(() async => db.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(db)],
      child: const MaterialApp(home: CafeRoute()),
    ));
    await tester.pumpAndSettle();

    // Nothing due → the café's calm empty state, proving CafeScreen was built
    // from the provider-supplied db (miningDbProvider defaults null → no
    // bridge → still fine).
    expect(find.byKey(const ValueKey('cafe-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
  });
}
