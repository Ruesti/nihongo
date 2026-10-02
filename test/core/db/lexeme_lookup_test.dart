// drift bringt eigene isNull/isNotNull-Ausdrücke mit — hier zählen die
// Matcher aus flutter_test.
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/lexeme_lookup.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));
    // Ein Lexem, dessen Konzept fehlt — die Fremdschlüssel sind im Testmodus
    // nicht erzwungen, genau dieser Halb-Zustand soll null ergeben.
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ghost',
        languageId: 'lang_ja',
        conceptId: 'concept_missing',
        writtenForm: 'ゆき',
        reading: 'ゆき'));
  });
  tearDown(() async => db.close());

  test('Lexem + Konzept kommen zusammen zurück', () async {
    final found = await loadLexemeWithConcept(db, 'lex_ja_ame');
    expect(found, isNotNull);
    expect(found!.lexeme.writtenForm, 'あめ');
    expect(found.concept.glossKey, 'rain');
    // Ohne withImageAsset wird das Asset gar nicht erst gesucht.
    expect(found.imageAsset, isNull);
  });

  test('withImageAsset liefert das Bild des Konzepts', () async {
    await db.into(db.assets).insert(AssetsCompanion.insert(
        id: 'asset_rain',
        conceptId: 'concept_rain',
        type: 'image',
        path: 'assets/concepts/rain.png'));
    final found =
        await loadLexemeWithConcept(db, 'lex_ja_ame', withImageAsset: true);
    expect(found!.imageAsset?.path, 'assets/concepts/rain.png');
  });

  test('ohne Bild bleibt imageAsset null, der Rest steht', () async {
    final found =
        await loadLexemeWithConcept(db, 'lex_ja_ame', withImageAsset: true);
    expect(found, isNotNull);
    expect(found!.imageAsset, isNull);
  });

  test('unbekannte Lexem-ID → null', () async {
    expect(await loadLexemeWithConcept(db, 'lex_ja_nichts'), isNull);
  });

  test('fehlendes Konzept → null', () async {
    expect(await loadLexemeWithConcept(db, 'lex_ja_ghost'), isNull);
  });
}
