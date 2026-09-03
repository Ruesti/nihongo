import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  testWidgets('nothing due → the café is calmly empty, with no count or '
      '"0 due" message', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-list')), findsNothing);
    // Nothing that reads like a due count leaks into the empty state.
    expect(find.textContaining('0'), findsNothing);
    expect(find.textContaining('fällig'), findsNothing);
  });

  testWidgets('due items at rung 1 and 3 → only the Wirtin and Schulkind '
      'are present', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 3);

    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-empty')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-guest-wirtin')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-guest-vielredner')), findsNothing);
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });

  testWidgets('occupancy is computed once on entry (stable for the session)',
      (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_a', rung: 3);
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-guest-schulkind')), findsOneWidget);

    // Adding more due items after entry does NOT change this session's café.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_b', rung: 5);
    // Force build() to run again on the SAME State (same widget config →
    // Element/State reused, no re-init). Occupancy is cached from initState,
    // so a rebuild must NOT surface the newly-due rung-5 item.
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('cafe-guest-gleichaltrige')), findsNothing);
  });
}
