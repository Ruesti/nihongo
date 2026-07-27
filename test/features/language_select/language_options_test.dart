import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/seed_all.dart';
import 'package:nihongo_app/features/language_select/language_options.dart';
import 'package:nihongo_app/packs/ar/ar_seed.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

void main() {
  late LearningDb db;

  setUp(() {
    db = LearningDb.forTesting();
  });

  tearDown(() async => db.close());

  test('empty DB yields no options', () async {
    final options = await loadAvailableLanguages(db);
    expect(options, isEmpty);
  });

  test('one seeded pack yields one option with resolved script profile', () async {
    await seedJaPack(db);
    final options = await loadAvailableLanguages(db);
    expect(options, hasLength(1));
    final ja = options.single;
    expect(ja.code, 'ja');
    expect(ja.nameNative, 'Japanese');
    expect(ja.scriptType, 'syllabary');
    expect(ja.needsScriptTrack, isTrue);
    expect(ja.isRtl, isFalse);
    expect(ja.ttsVoice, 'ja-JP');
  });

  test('RTL script profile is reported correctly', () async {
    await seedArPack(db);
    final ar = (await loadAvailableLanguages(db)).single;
    expect(ar.isRtl, isTrue);
    expect(ar.toneSystem, 'vowelPoints');
  });

  test('all six packs are returned sorted by code', () async {
    await seedAllPacks(db);
    final options = await loadAvailableLanguages(db);
    expect(options.map((o) => o.code).toList(), ['ar', 'es', 'hi', 'ja', 'ko', 'zh']);
  });
}
