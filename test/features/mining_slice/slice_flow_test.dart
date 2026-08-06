import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' show Rating;
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/mining_slice/slice_app.dart';
import 'package:nihongo_app/features/mining_slice/slice_pack.dart';
import 'package:nihongo_app/features/mining_slice/slice_repository.dart';
import 'package:nihongo_app/features/opening/opening_state.dart';

/// A tiny hand-built pack (no prebake asset needed): one passage whose
/// first word is a known lemma, seeded as a due demo card so the review
/// surfaces from the text.
SlicePack _tinyPack() => SlicePack(
      workTitle: 'テスト',
      languageCode: 'ja',
      demoKnownLemmas: const ['猫'],
      dictionary: const PrebakedDictionary({
        '猫': [Sense(pos: 'n', glosses: ['cat', 'feline'])],
      }),
      passages: const [
        SlicePassage(
          passageRef: 'Absatz 1',
          content: '猫が',
          furiganaByCharStart: {0: 'ねこ'},
          tokens: [
            Token(
                surface: '猫',
                lemma: '猫',
                reading: 'ねこ',
                pos: 'noun',
                charStart: 0,
                charEnd: 1),
            Token(
                surface: 'が',
                lemma: 'が',
                reading: 'が',
                pos: 'particle',
                charStart: 1,
                charEnd: 2),
          ],
        ),
      ],
    );

void main() {
  final now = DateTime.utc(2026, 8, 5, 12);

  group('SliceRepository — the whole reading loop on the real engine', () {
    late MiningDb db;
    late SliceRepository repo;

    setUp(() async {
      db = MiningDb.forTesting();
      repo = SliceRepository(db: db, pack: _tinyPack());
      await repo.seed(now: now);
    });

    tearDown(() async => db.close());

    test('seeds content (work + spans) idempotently', () async {
      await repo.seed(now: now); // second call must not duplicate
      expect(await db.select(db.works).get(), hasLength(1));
      expect(await db.select(db.textSpans).get(), hasLength(1));
    });

    test('a due review surfaces from the passage text (§7)', () async {
      final due = await repo.dueInView(repo.pack.passages.first, now: now);
      expect(due, isNotEmpty);
      expect(due.first.lemma, '猫');
    });

    test('a word tap resolves to a real gloss (§5)', () {
      final result = repo.tap(repo.pack.passages.first.tokens.first);
      expect(result.isKnownWord, isTrue);
      expect(result.senses.first.glosses, contains('cat'));
    });

    test('grading a surfaced card removes it from the due set', () async {
      final due = await repo.dueInView(repo.pack.passages.first, now: now);
      await repo.grade(due.first.cardId, Rating.good, now: now);
      final after = await repo.dueInView(repo.pack.passages.first, now: now);
      expect(after, isEmpty);
    });

    test('opening: blank slate → first reading → re-presentation (§8)',
        () async {
      // Nothing read yet: blank slate, Datum silent.
      expect(await repo.openingState(), isA<BlankSlateState>());
      expect(repo.openingDatumLine(const BlankSlateState()), isNull);

      // Read the passage once → first-reading proof, Datum speaks it.
      await repo.finishReading(repo.pack.passages.first,
          lookupCount: 1, now: now);
      final s1 = await repo.openingState();
      expect(s1, isA<FirstReadingState>());
      final line1 = repo.openingDatumLine(s1);
      expect(line1, isNotNull);
      expect(line1, contains('Absatz 1'));

      // Read the same passage again later → a real Then/Now delta.
      await repo.finishReading(repo.pack.passages.first,
          lookupCount: 0, now: now.add(const Duration(days: 3)));
      expect(await repo.openingState(), isA<RePresentationState>());
    });
  });

  testWidgets('SliceApp boots to the honest blank-slate opening', (tester) async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());
    final repo = SliceRepository(db: db, pack: _tinyPack());
    await repo.seed(now: now);

    await tester.pumpWidget(SliceApp(repo: repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('blank-slate')), findsOneWidget);
    expect(find.byKey(const ValueKey('continue-reading')), findsOneWidget);
    // No fabricated proof, no gamification numbers on the opening (I3/§8).
    expect(find.byKey(const ValueKey('re-presentation')), findsNothing);
  });

  // Regression: opening → reader → back drives OpeningGate._openReader,
  // whose post-navigation setState must not return a Future (a device run
  // surfaced that assertion). Reading once must leave the opening on the
  // first-reading proof without throwing.
  testWidgets('reading a passage and returning refreshes the opening cleanly',
      (tester) async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());
    final repo = SliceRepository(db: db, pack: _tinyPack());
    await repo.seed(now: now);

    await tester.pumpWidget(SliceApp(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('continue-reading')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('finish-passage')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish-passage')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull); // the setState-Future bug
    expect(find.byKey(const ValueKey('first-reading-proof')), findsOneWidget);
  });
}
