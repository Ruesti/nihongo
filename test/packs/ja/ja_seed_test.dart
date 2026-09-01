import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

/// The 8 Folge 01 "Regen" words, keyed by the lexeme id the story fixtures
/// (P1 episode budget, P4a dictionary) already use, with the hiragana form
/// the pilot renders.
const _folge01 = <String, String>{
  'lex_ja_sumimasen': 'すみません',
  'lex_ja_ame': 'あめ',
  'lex_ja_kasa': 'かさ',
  'lex_ja_kore': 'これ',
  'lex_ja_kowareta': 'こわれた',
  'lex_ja_hai': 'はい',
  'lex_ja_douzo': 'どうぞ',
  'lex_ja_arigatou': 'ありがとう',
};

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
  });

  tearDown(() => db.close());

  group('JA seed — Folge 01 vocabulary', () {
    test('every Folge 01 word is a lexeme under lang_ja with its hiragana form',
        () async {
      final lexemes = await db.select(db.lexemes).get();
      final byId = {for (final l in lexemes) l.id: l};
      for (final entry in _folge01.entries) {
        final lex = byId[entry.key];
        expect(lex, isNotNull, reason: '${entry.key} missing from JA pack');
        expect(lex!.languageId, 'lang_ja');
        expect(lex.writtenForm, entry.value);
        expect(lex.reading, entry.value);
      }
    });

    test('every Folge 01 word has a concept with a neutral English glossKey',
        () async {
      final lexemes = await db.select(db.lexemes).get();
      final concepts = await db.select(db.concepts).get();
      final conceptById = {for (final c in concepts) c.id: c};
      for (final id in _folge01.keys) {
        final lex = lexemes.firstWhere((l) => l.id == id);
        final concept = conceptById[lex.conceptId];
        expect(concept, isNotNull,
            reason: '$id points at a concept that was not seeded');
        expect(concept!.glossKey, isNotEmpty);
        // glossKey is a lookup key, never a German display string — the
        // reader-facing meanings live in the P4a dictionary fixture.
        expect(RegExp(r'^[a-z_]+$').hasMatch(concept.glossKey), isTrue,
            reason: '${concept.glossKey} is not a lowercase English key');
      }
    });
  });

  group('JA seed — Folge 01 idempotency', () {
    test('re-seeding does not duplicate the Folge 01 words', () async {
      await seedJaPack(db);
      final lexemes = await db.select(db.lexemes).get();
      for (final id in _folge01.keys) {
        expect(lexemes.where((l) => l.id == id), hasLength(1),
            reason: '$id was duplicated on re-seed');
      }
    });
  });
}
