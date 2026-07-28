import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/seed_all.dart';

void main() {
  late LearningDb db;

  setUp(() {
    db = LearningDb.forTesting();
  });

  tearDown(() async => db.close());

  test('seeds all six language packs', () async {
    await seedAllPacks(db);
    final rows = await db.select(db.languages).get();
    final ids = rows.map((l) => l.id).toSet();
    expect(ids, {'lang_ja', 'lang_es', 'lang_ko', 'lang_ar', 'lang_hi', 'lang_zh'});
  });

  test('seeds a script profile for every language', () async {
    await seedAllPacks(db);
    final profiles = await db.select(db.scriptProfiles).get();
    expect(profiles.length, 6);
  });

  test('is idempotent when run twice', () async {
    await seedAllPacks(db);
    await seedAllPacks(db);
    final rows = await db.select(db.languages).get();
    expect(rows.length, 6);
  });
}
