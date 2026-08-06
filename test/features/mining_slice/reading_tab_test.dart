import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/mining_slice/reading_tab.dart';
import 'package:nihongo_app/features/mining_slice/slice_pack.dart';
import 'package:nihongo_app/features/mining_slice/slice_repository.dart';

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
}
