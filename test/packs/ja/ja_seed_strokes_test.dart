import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  test('seeded kana carry their KanjiVG strokeOrderAssetId', () async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await seedJaPack(db);

    final a = await (db.select(db.characters)
          ..where((t) => t.id.equals('char_ja_a')))
        .getSingle();
    expect(a.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
  });
}
