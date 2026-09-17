import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief.dart';
import 'package:nihongo_app/features/story/episode.dart';

/// Drei Panels: かさ zuerst (P0), あめ ab P1; はい nur über targetItemIds.
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_debrief',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_hai', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
          ],
        },
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'かさ',
                  'tokens': [
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ、かさ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true, 'targetItemIds': ['lex_ja_hai']},
              ],
            },
            {
              'index': 2,
              'asset': 'assets/story/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true, 'targetItemIds': ['lex_ja_hai']},
              ],
            },
          ],
        },
      ],
    };

Future<void> _seedLexeme(LearningDb db, String id, String concept,
    String form, String gloss) async {
  await db.into(db.concepts).insert(ConceptsCompanion.insert(
      id: concept,
      glossKey: gloss,
      partOfSpeech: 'noun',
      defaultAssetType: const Value('image')));
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
      id: id,
      languageId: 'lang_ja',
      conceptId: concept,
      writtenForm: form,
      reading: form));
}

void main() {
  late LearningDb db;
  late Episode episode;

  setUp(() async {
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    await _seedLexeme(db, 'lex_ja_ame', 'concept_rain', 'あめ', 'rain');
    await _seedLexeme(db, 'lex_ja_kasa', 'concept_umbrella', 'かさ', 'umbrella');
    await _seedLexeme(db, 'lex_ja_hai', 'concept_yes', 'はい', 'yes');
  });
  tearDown(() async => db.close());

  test('debriefOrder: Reihenfolge des ersten Token-Auftritts, Rest in '
      'Budget-Reihenfolge', () {
    expect(debriefOrder(episode), ['lex_ja_kasa', 'lex_ja_ame', 'lex_ja_hai']);
  });

  test('firstAppearancePanel liefert das erste Panel mit dem Token, sonst null',
      () {
    expect(firstAppearancePanel(episode, 'lex_ja_ame')!.index, 1);
    expect(firstAppearancePanel(episode, 'lex_ja_kasa')!.index, 0);
    expect(firstAppearancePanel(episode, 'lex_ja_hai'), isNull);
  });

  test('episodeIntroducing findet die Folge, deren Budget das Item führt', () {
    expect(episodeIntroducing([episode], 'lex_ja_ame'), same(episode));
    expect(episodeIntroducing([episode], 'lex_ja_ghost'), isNull);
    expect(episodeIntroducing(const [], 'lex_ja_ame'), isNull);
  });

  test('debriefItemsFor = Manifest ∩ Karteikasten: nur eingeführte Items, in '
      'Auftrittsreihenfolge (INV-11)', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    // lex_ja_hai steht im Budget, wurde aber nie übergeben → erscheint nicht.
    final items = await debriefItemsFor(db, episode, 'lang_ja');
    expect(items.map((i) => i.refId), ['lex_ja_kasa', 'lex_ja_ame']);
  });

  test('debriefItemsFor ignoriert Nicht-Lexem-Items (Zeichen/Grammatik folgen '
      'in eigenen Schritten)', () async {
    final ep = Episode.fromJson({
      ..._episodeJson(),
      'budget': {
        'items': [
          {'id': 'char_ja_a', 'refType': 'character'},
        ],
        'glyphs': [],
      },
      'pages': [],
    });
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 0);
    expect(await debriefItemsFor(db, ep, 'lang_ja'), isEmpty);
  });

  test('loadDebriefCard: Begegnung + Stelle in der Folge + Erklärungsblock',
      () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    final item = (await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!;
    final card = (await loadDebriefCard(db, item, episode: episode))!;
    expect(card.encounter.writtenForm, 'あめ');
    expect(card.encounter.meaning, 'Regen'); // deutsch via meaningForConcept
    expect(card.firstPanel!.index, 1);
    expect(card.note!.usage, 'Regen. Das Wort vom Zettel.');
    expect(card.note!.variants.single.form, 'おおあめ');
  });

  test('loadDebriefCard ohne Folge: nur die Begegnung; unbekanntes Lexem → null',
      () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ghost', rung: 1);
    final kasa = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    final card = (await loadDebriefCard(db, kasa))!;
    expect(card.firstPanel, isNull);
    expect(card.note, isNull);
    expect(card.encounter.meaning, 'Schirm');
    final ghost = (await db.getLearnItem('lang_ja:lexeme:lex_ja_ghost'))!;
    expect(await loadDebriefCard(db, ghost), isNull);
  });
}
