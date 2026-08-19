import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_reader_screen.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

class _Dict implements Dictionary {
  const _Dict();
  @override
  List<Sense> lookup(String lemma, String pos) =>
      [Sense(pos: 'n', glosses: ['cat'])];
}

ComicPack _pack() => const ComicPack(
      languageCode: 'ja',
      title: 'T',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'assets/comic/placeholder_page.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: BubbleRect(left: 0.2, top: 0.4, right: 0.8, bottom: 0.6),
              lang: BubbleLang.l2,
              text: '猫',
              reading: 'ねこ',
              tokens: [
                Token(surface: '猫', lemma: '猫', reading: 'ねこ', pos: 'n', charStart: 0, charEnd: 1)
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  testWidgets('tapping an L2 word opens a gloss sheet', (tester) async {
    final db = MiningDb.forTesting();
    addTearDown(db.close);
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _Dict());

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ComicReaderScreen(repo: repo, direction: TextDirection.ltr),
    ));
    await tester.pumpAndSettle();

    // The page is taller than the default test viewport and lives inside a
    // SingleChildScrollView — scroll the target into view before tapping.
    await tester.ensureVisible(find.text('猫'));
    await tester.tap(find.text('猫'));
    await tester.pumpAndSettle();

    expect(find.text('cat'), findsOneWidget); // gloss shown in the sheet
  });
}
