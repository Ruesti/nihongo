import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';

void main() {
  test('CharacterEncounter carries glyph + reading, optional stroke/mnemonic',
      () {
    const e = CharacterEncounter(
      glyph: 'あ',
      reading: 'a',
      audioText: 'あ',
      strokeOrderAssetId: 'assets/kanji_svg/3042.svg',
    );
    expect(e.glyph, 'あ');
    expect(e.strokeOrderAssetId, 'assets/kanji_svg/3042.svg');
    expect(e.mnemonic, isNull);
  });

  test('LexemeEncounter degrades without a concept image', () {
    const e = LexemeEncounter(
      writtenForm: '猫',
      reading: 'ねこ',
      audioText: '猫',
      meaning: 'cat',
    );
    expect(e.conceptImagePath, isNull);
    expect(e.exampleSentence, isNull);
  });

  test('EncounterContent is an ExerciseContent wrapping an Encounter', () {
    final c = EncounterContent(
      encounter: const CharacterEncounter(
          glyph: 'い', reading: 'i', audioText: 'い'),
    );
    expect(c, isA<ExerciseContent>());
    expect((c.encounter as CharacterEncounter).glyph, 'い');
  });
}
