import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/manga_step_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadComicPackForStep returns a pack for a bundled asset', () async {
    final pack = await loadComicPackForStep('assets/comic/ja_l0.json');
    expect(pack, isNotNull);
    expect(pack!.languageCode, 'ja');
  });

  test('loadComicPackForStep returns null for a missing asset', () async {
    expect(await loadComicPackForStep('assets/comic/does_not_exist.json'), isNull);
  });

  testWidgets(
      'openMangaStep returns false when there is no mining DB (cannot advance)',
      (tester) async {
    bool? result;

    await tester.pumpWidget(ProviderScope(
      // miningDbProvider defaults to null — no override needed.
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await openMangaStep(
                  context,
                  ref,
                  const MangaStep(
                    id: 'm',
                    chapterRef: 'K',
                    comicAsset: 'assets/comic/ja_l0.json',
                  ),
                );
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));

    // openMangaStep awaits a real rootBundle asset load; run the
    // tap+settle in the real async zone so that Future actually resolves
    // (fake-async pumpAndSettle alone never completes it — same reason
    // reading_tab_test.dart avoids rootBundle loads inside testWidgets).
    await tester.runAsync(() async {
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
    });

    expect(result, isFalse);
  });
}
