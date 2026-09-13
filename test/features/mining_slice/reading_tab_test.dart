import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/mining_slice/reading_tab.dart';
import 'package:nihongo_app/features/mining_slice/slice_pack.dart';
import 'package:nihongo_app/features/mining_slice/slice_repository.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

SlicePack _pack() => SlicePack(
      workTitle: 'テスト',
      languageCode: 'ja',
      demoKnownLemmas: const ['猫'],
      dictionary: const PrebakedDictionary({
        '猫': [Sense(pos: 'n', glosses: ['cat'])],
      }),
      passages: const [
        SlicePassage(
          passageRef: 'Absatz 1',
          content: '猫',
          furiganaByCharStart: {},
          tokens: [
            Token(surface: '猫', lemma: '猫', pos: 'n', charStart: 0, charEnd: 1),
          ],
        ),
      ],
    );

void main() {
  test('unified seeding adds content but injects no knowledge', () async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());
    await SliceRepository(db: db, pack: _pack())
        .seed(includeDemoKnowledge: false);

    expect(await db.select(db.works).get(), hasLength(1)); // content seeded
    expect(await db.select(db.textSpans).get(), isNotEmpty);
    // The on-ramp is the knowledge source — the reader must not pollute
    // the shared state with fabricated "known" demo cards.
    expect(await db.select(db.cards).get(), isEmpty);
    expect(await db.select(db.vocabItems).get(), isEmpty);
  });

  test('standalone seeding (default) still injects the demo knowledge', () async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());
    await SliceRepository(db: db, pack: _pack()).seed(now: DateTime.utc(2026, 8, 6));
    expect(await db.select(db.cards).get(), isNotEmpty);
  });

  testWidgets('ReadingTab boots to the honest blank slate over the shared db',
      (tester) async {
    final db = MiningDb.forTesting();
    addTearDown(() async => db.close());
    final repo = SliceRepository(db: db, pack: _pack());
    await repo.seed(includeDemoKnowledge: false);

    // Override the repository provider directly so the test doesn't depend
    // on rootBundle asset loading (covered by the on-device smoke); this
    // exercises the ReadingTab → OpeningGate wiring over the shared db.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        readingRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: const MaterialApp(home: ReadingTab()),
    ));
    await tester.pumpAndSettle();

    // No reading history + no demo knowledge → the honest empty state.
    expect(find.byKey(const ValueKey('blank-slate')), findsOneWidget);
  });

  testWidgets('der Folge-Einstieg ist auch OHNE Mining-Store da und '
      'oeffnet den Story-Reader (Lesen ab Tag 1)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    await seedJaPack(learning);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Mining bewusst NICHT konfiguriert: miningDbProvider bleibt null →
        // "Mining ist nicht konfiguriert." — der Manga-Einstieg muss trotzdem da sein.
        learningDbProvider.overrideWithValue(learning),
      ],
      child: const MaterialApp(home: ReadingTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-entry-fab')), findsOneWidget);
    expect(find.byKey(const ValueKey('comic-entry-fab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-entry-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('der Folge-Einstieg ist auch im Mining-Happy-Path da',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    final db = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await db.close();
    });
    await seedJaPack(learning);
    final repo = SliceRepository(db: db, pack: _pack());
    await repo.seed(includeDemoKnowledge: false);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        learningDbProvider.overrideWithValue(learning),
        readingRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: const MaterialApp(home: ReadingTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-entry-fab')), findsOneWidget);
    expect(find.byKey(const ValueKey('blank-slate')), findsOneWidget);
  });
}
