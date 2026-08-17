import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_prefs.dart';
import 'package:nihongo_app/features/onboarding/placement_service.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_dog', glossKey: 'dog', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_dog',
        languageId: 'lang_ja',
        conceptId: 'c_dog',
        writtenForm: '犬',
        reading: 'いぬ'));
  });

  tearDown(() async => db.close());

  test('confirmed word is inserted as a mastered (rung ≥ 3) learn item', () async {
    const profile = PlacementProfile(
      fromZero: false,
      knowsHiragana: true,
      knowsKatakana: false,
      knownWordLexemeIds: ['lex_dog'],
    );

    await PlacementService(db, null)
        .apply(profile, languageId: 'lang_ja', languageCode: 'ja');

    final item = await db.getLearnItem('lang_ja:lexeme:lex_dog');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(3));
  });

  test('PlacementProfile round-trips through JSON', () {
    const p = PlacementProfile(
      fromZero: false,
      knowsHiragana: true,
      knowsKatakana: false,
      knownWordLexemeIds: ['a', 'b'],
    );
    final back = PlacementProfile.fromJson(p.toJson());
    expect(back.knowsHiragana, isTrue);
    expect(back.knownWordLexemeIds, ['a', 'b']);
  });
}
