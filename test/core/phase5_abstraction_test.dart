/// Phase 5 Abstraction Proof — I5 + I8 Invarianten
///
/// Beweist: Derselbe Core-Code läuft identisch für JA/ES/KO.
/// Nur Daten (ScriptProfile + Pack-Inhalt) steuern das Verhalten.
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/conversation/conversation_service.dart';
import 'package:nihongo_app/core/conversation/error_span.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/games/game_availability.dart';
import 'package:nihongo_app/core/games/game_queue.dart';
import 'package:nihongo_app/core/ladder/exercise_content.dart';
import 'package:nihongo_app/core/ladder/exercise_loader.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/script_profile.dart';
import 'package:nihongo_app/packs/es/es_seed.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:nihongo_app/packs/ko/ko_seed.dart';

const _jaProfile = ScriptProfile(
  id: 'sp_ja_kana',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.pitchAccent,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

const _esProfile = ScriptProfile(
  id: 'sp_es',
  scriptType: ScriptType.alphabet,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: false,
  transliteration: 'none',
  inputMethods: [InputMethod.keyboard],
);

const _koProfile = ScriptProfile(
  id: 'sp_ko',
  scriptType: ScriptType.hangul,
  direction: Direction.ltr,
  decomposability: Decomposability.jamo,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: true,
  transliteration: 'romanization',
  inputMethods: [InputMethod.keyboard],
);

void main() {
  group('I5 — game availability driven purely by ScriptProfile flags', () {
    test('JA kana: 3 games (readingBlitz, writeTrace, wordBuild)', () {
      final specs = gameAvailability(_jaProfile);
      expect(specs, hasLength(3));
      expect(specs.any((s) => s.type == GameType.readingBlitz), isTrue);
      expect(specs.any((s) => s.type == GameType.writeTrace), isTrue);
      expect(specs.any((s) => s.type == GameType.wordBuild), isTrue);
      expect(specs.any((s) => s.type == GameType.mnemonicMatch), isFalse);
    });

    test('ES alphabet: 4 games (readingBlitz, wordBuild×2, writeTrace)', () {
      final specs = gameAvailability(_esProfile);
      expect(specs, hasLength(4));
      expect(specs.where((s) => s.type == GameType.wordBuild).length, 2);
      expect(specs.any((s) => s.type == GameType.mnemonicMatch), isFalse);
      expect(specs.any((s) => s.type == GameType.componentBuild), isFalse);
    });

    test('KO hangul: 5 games (mnemonicMatch, readingBlitz, componentBuild, writeTrace, wordBuild)', () {
      final specs = gameAvailability(_koProfile);
      expect(specs, hasLength(5));
      expect(specs.any((s) => s.type == GameType.mnemonicMatch && s.rung == 1), isTrue);
      expect(specs.any((s) => s.type == GameType.componentBuild && s.rung == 3), isTrue);
      expect(specs.any((s) => s.type == GameType.wordBuild && s.rung == 5), isTrue);
      expect(specs.any((s) => s.type == GameType.kanjiCompound), isFalse);
    });

    test('all 3 profiles differ in game count (I5: no language-specific code)', () {
      final ja = gameAvailability(_jaProfile).length;
      final es = gameAvailability(_esProfile).length;
      final ko = gameAvailability(_koProfile).length;
      // JA=3, ES=4, KO=5 — all different, driven by profile flags alone
      expect({ja, es, ko}.length, 3);
    });
  });

  group('I8 — ExerciseLoader is language-blind (same code, different data)', () {
    late LearningDb db;
    late ExerciseLoader loader;

    setUp(() async {
      db = LearningDb.forTesting();
      await seedJaPack(db);
      await seedEsPack(db);
      await seedKoPack(db);
      loader = ExerciseLoader(db);
    });

    tearDown(() => db.close());

    test('ES rung1 → RecognitionContent with Spanish form and English gloss', () async {
      await db.addLearnItem('lang_es', RefType.lexeme, 'lex_es_dog');
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _esProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, 'perro');
      expect(rec.answer, 'dog');
    });

    test('ES rung2 → ReadingInputContent (reading = writtenForm for alphabet)', () async {
      await db.addLearnItemAtRung('lang_es', RefType.lexeme, 'lex_es_dog', rung: 2);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _esProfile);

      expect(content, isA<ReadingInputContent>());
      final read = content as ReadingInputContent;
      expect(read.displayForm, 'perro');
      expect(read.expectedReading, 'perro');
    });

    test('ES rung3 → ProductionInputContent', () async {
      await db.addLearnItemAtRung('lang_es', RefType.lexeme, 'lex_es_dog', rung: 3);
      final item = (await db.select(db.learnItems).get()).first;

      final content = await loader.load(item, _esProfile);

      expect(content, isA<ProductionInputContent>());
      final prod = content as ProductionInputContent;
      expect(prod.prompt, 'dog');
      expect(prod.expectedForm, 'perro');
    });

    test('KO rung1 → RecognitionContent with hangul glyph', () async {
      await db.addLearnItemAtRung('lang_ko', RefType.character, 'char_ko_ga', rung: 1);
      final item = (await (db.select(db.learnItems)
                ..where((t) => t.languageId.equals('lang_ko')))
              .get())
          .first;

      final content = await loader.load(item, _koProfile);

      expect(content, isA<RecognitionContent>());
      final rec = content as RecognitionContent;
      expect(rec.displayForm, '가');
    });

    test('KO rung4 → WriteTraceContent with hangul glyph', () async {
      await db.addLearnItemAtRung('lang_ko', RefType.character, 'char_ko_ga', rung: 4);
      final item = (await (db.select(db.learnItems)
                ..where((t) => t.languageId.equals('lang_ko')))
              .get())
          .first;

      final content = await loader.load(item, _koProfile);

      expect(content, isA<WriteTraceContent>());
      final trace = content as WriteTraceContent;
      expect(trace.glyph, '가');
    });
  });

  group('I8 — ConversationService.onError is language-blind', () {
    late LearningDb db;
    late ConversationService service;

    setUp(() async {
      db = LearningDb.forTesting();
      await seedEsPack(db);
      await seedKoPack(db);
      service = ConversationService(db);
    });

    tearDown(() => db.close());

    test('onError creates ES lexeme item (alphabet pack)', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_es',
        refType: RefType.lexeme,
        refId: 'lex_es_dog',
      ));

      final items = await db.select(db.learnItems).get();
      expect(items, hasLength(1));
      expect(items.first.languageId, 'lang_es');
    });

    test('onError creates KO character item (hangul pack)', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_ko',
        refType: RefType.character,
        refId: 'char_ko_ga',
      ));

      final items = await db.select(db.learnItems).get();
      expect(items, hasLength(1));
      expect(items.first.languageId, 'lang_ko');
      expect(items.first.refType, 'character');
    });

    test('errors for different languages create independent items', () async {
      await service.onError(const ErrorSpan(
        languageId: 'lang_es',
        refType: RefType.lexeme,
        refId: 'lex_es_dog',
      ));
      await service.onError(const ErrorSpan(
        languageId: 'lang_ko',
        refType: RefType.lexeme,
        refId: 'lex_ko_dog',
      ));

      final items = await db.select(db.learnItems).get();
      expect(items, hasLength(2));
      expect(items.map((i) => i.languageId).toSet(), {'lang_es', 'lang_ko'});
    });
  });

  group('I8 — GameQueue is language-blind', () {
    late LearningDb db;
    late GameQueue queue;

    setUp(() async {
      db = LearningDb.forTesting();
      await seedJaPack(db);
      await seedEsPack(db);
      await seedKoPack(db);
      queue = GameQueue(db);
    });

    tearDown(() => db.close());

    test('getDue isolates items by languageId', () async {
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog', rung: 2);
      await db.addLearnItemAtRung('lang_es', RefType.lexeme, 'lex_es_dog', rung: 2);
      await db.addLearnItemAtRung('lang_ko', RefType.lexeme, 'lex_ko_dog', rung: 2);

      const spec = (type: GameType.readingBlitz, rung: 2);
      final jaItems = await queue.getDue(spec, 'lang_ja');
      final esItems = await queue.getDue(spec, 'lang_es');
      final koItems = await queue.getDue(spec, 'lang_ko');

      expect(jaItems, hasLength(1));
      expect(esItems, hasLength(1));
      expect(koItems, hasLength(1));
      expect(jaItems.first.languageId, 'lang_ja');
      expect(esItems.first.languageId, 'lang_es');
      expect(koItems.first.languageId, 'lang_ko');
    });
  });
}
