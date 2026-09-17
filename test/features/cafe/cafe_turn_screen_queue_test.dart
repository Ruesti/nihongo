import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));
  });
  tearDown(() async => db.close());

  /// Ein Sprosse-1-Item, dessen erster Termin erst morgen ist — heute NICHT
  /// fällig.
  Future<LearnItem> notDueItem() async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 1);
    await (db.update(db.learnItems)
          ..where((t) => t.refId.equals('lex_ja_ame')))
        .write(LearnItemsCompanion(
            dueAt: Value(DateTime.now().add(const Duration(days: 1)))));
    return (await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!;
  }

  testWidgets('ohne initialQueue: ein nicht fälliges Item ergibt keinen Turn '
      '(wie bisher)', (tester) async {
    await notDueItem();
    await tester.pumpWidget(
        MaterialApp(home: CafeTurnScreen(db: db, guest: CafeGuest.wirtin)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsNothing);
  });

  testWidgets('mit initialQueue wird dasselbe Item sofort abgefragt; am Ende '
      'steht die Schlusszeile', (tester) async {
    final item = await notDueItem();
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
        db: db,
        guest: CafeGuest.wirtin,
        initialQueue: [item],
        doneLine: 'So, das war die Folge.',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(find.text('あめ'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.text('So, das war die Folge.'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(1));
  });
}
