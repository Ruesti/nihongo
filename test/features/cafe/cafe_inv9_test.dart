import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    // A lexeme + concept EXIST in the pack, but the learner has NEVER been
    // introduced to it — there is no learn_item for it. INV-9: it must never
    // surface in the café.
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_secret', glossKey: 'secret', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_himitsu', languageId: 'lang_ja',
        conceptId: 'concept_secret', writtenForm: 'ひみつ', reading: 'ひみつ'));
  });
  tearDown(() async => db.close());

  test('an un-introduced item (no learn_item) is not due — the café has no '
      'source for it', () async {
    // The café's ONLY item source is getDueItems, which selects learn_items.
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isEmpty);
    // Occupancy is empty: no guest is present for an item that was never read.
    expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
  });

  testWidgets('with only an un-introduced item in the pack, the café is empty '
      'and no guest turn can reach it (INV-9)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CafeScreen(db: db)));
    await tester.pumpAndSettle();
    // No guest tiles at all — the un-introduced word never becomes a guest.
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);

    // And even opening any guest's turn directly surfaces nothing to review.
    for (final guest in CafeGuest.values) {
      await tester.pumpWidget(MaterialApp(
        home: CafeTurnScreen(db: db, guest: guest),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget,
          reason: '$guest surfaced a turn for an un-introduced item');
      expect(find.text('ひみつ'), findsNothing);
    }
  });

  test('once introduced (a learn_item exists), the SAME word becomes due — '
      'the café gate is exactly introduction, nothing else', () async {
    // Positive control: introduce it → now it is due → now it can appear.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_himitsu',
        rung: 1);
    final due = await db.getDueItems('lang_ja', limit: 500);
    expect(due.where((i) => i.refId == 'lex_ja_himitsu'), isNotEmpty);
    expect(CafeOccupancy.fromDueItems(due).present, contains(CafeGuest.wirtin));
  });
}
