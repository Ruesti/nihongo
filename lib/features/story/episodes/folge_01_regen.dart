import '../dictionary.dart';
import '../episode.dart';
import '../episode_validator.dart';

/// Folge 01 „Regen" (ep_ja_shotengai_01) als gebündelter Produktions-
/// Inhalt. Panel-Assets zeigen noch auf die V1-Renders; der Tausch gegen
/// die finalen ckpt-6-Panels ist ein reiner Asset-Austausch in dieser Datei
/// (Task 3).
Episode loadFolge01() {
  final episode = Episode.fromJson(pilot01RegenJson);
  validateEpisode(episode);
  return episode;
}

/// Folge 01 — "Regen", V2 nach docs/story/DREHBUCH_FOLGE_01_V2.md (BINDENDE
/// Textquelle für alle deutschen Kästen/Gedanken und japanischen Dialoge)
/// und dem Panel-Bauplan in
/// docs/superpowers/plans/2026-09-13-folge01-v2.md. 10 dichte Panels statt
/// V1s 24 — jedes Panel trägt Sprache oder treibt die Handlung. Mira, die
/// Protagonistin, sucht anhand eines vom Regen fast unleserlich gemachten
/// Zettels ihrer verstorbenen Großmutter eine Adresse in dieser Shotengai.
const Map<String, dynamic> pilot01RegenJson = {
  'id': 'ep_ja_shotengai_01',
  'seasonId': 'season_ja_shotengai',
  'orderIndex': 1,
  'title': 'Regen',
  'locale': 'ja',
  'era': '1996',
  'intro':
      'Eine junge Frau steigt allein aus dem Zug — es regnet. '
      'In ihrer Hand: ein Zettel, dessen Tinte verläuft.',
  'outro':
      'Auf dem Zettel standen einmal drei Zeilen. Mira kennt jetzt: ein '
      'Zeichen und vier Wörter. Hinter dieser Tür fängt der Rest an.',
  'budget': {
    'items': [
      {'id': 'lex_ja_sumimasen', 'refType': 'lexeme'},
      {'id': 'lex_ja_ame', 'refType': 'lexeme'},
      {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
      {'id': 'lex_ja_kore', 'refType': 'lexeme'},
      {'id': 'lex_ja_kowareta', 'refType': 'lexeme'},
      {'id': 'lex_ja_hai', 'refType': 'lexeme'},
      {'id': 'lex_ja_douzo', 'refType': 'lexeme', 'singleton': true},
      {'id': 'lex_ja_arigatou', 'refType': 'lexeme'},
    ],
    'glyphs': [
      {'glyph': 'あ'},
      {'glyph': 'め'},
      {'glyph': 'か'},
    ],
  },
  'pages': [
    // Seite 0 — Ankunft (P1-Bahnsteig bis P4-Shotengai-Eingang)
    {
      'index': 0,
      'panels': [
        {
          'index': 0,
          'asset': 'assets/story/p01.jpg',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'みなみまち',
              'hitArea': [
                {'x': 0.30, 'y': 0.36},
                {'x': 0.70, 'y': 0.36},
                {'x': 0.70, 'y': 0.49},
                {'x': 0.30, 'y': 0.49},
              ],
              'tokens': [
                {'surface': 'みなみまち', 'itemId': null},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  'Das ist Mira. Vor drei Wochen fand sie im Nachlass ihrer '
                  'Großmutter einen Zettel: eine Adresse, irgendwo hier.',
            },
            {
              'text':
                  'Ihre Großmutter hat nie über Japan gesprochen. Kein Wort '
                  '— auch nicht in ihrer eigenen Sprache. Mira hat nie '
                  'erfahren, warum.',
            },
            {
              'text':
                  'Sie kann nichts lesen. Nicht einmal den Namen dieser '
                  'Station.',
            },
            {'text': '„Ich hätte anrufen sollen. Aber wen?"'},
          ],
          'interactions': [],
          'notes':
              'Bestehendes Motiv (kleiner Bahnsteig, Regen schräg durch '
              'Neonlicht, Mira mit Tasche, Kopf gesenkt). Neu: das '
              'Stationsschild 「みなみまち」 sichtbar im Hintergrund.',
        },
        {
          'index': 1,
          'asset': 'assets/story/p02.jpg',
          'bubbles': [],
          'thoughts': [
            {'text': 'Der Regen war schneller als sie.'},
            {'text': '„Nein — nein, nicht jetzt. Nicht auch das noch."'},
          ],
          'interactions': [
            {
              'type': 'trace',
              'diegetic': true,
              'promptText':
                  'Rette das Zeichen: Zeichne め nach, bevor der Regen es '
                  'holt.',
              'target': 'め',
              'targetItemIds': <dynamic>[],
              'reactionAsset': 'assets/story/p02_reaction.jpg',
              'reactionCaption':
                  'め. Was immer es heißt — jetzt gehört es ihr.',
            },
          ],
          'notes':
              'Nahaufnahme ihrer Hand mit dem Zettel. Die Tinte läuft. '
              'Genau EIN Zeichen ist noch klar: 「め」. Das letzte lesbare '
              'Zeichen verschwindet vor ihren Augen. Mira zeichnet es nach '
              '— auf ihren Handrücken, mit dem Finger, bevor es weg ist. '
              'Reaktion bei Erfolg: ihr Handrücken mit dem Zeichen.',
        },
        {
          'index': 2,
          'asset': 'assets/story/p03.jpg',
          'bubbles': [
            {
              'speakerId': 'passant_a',
              'text': 'あめ！',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'passant_b',
              'text': 'あめ、あめ…',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
          ],
          'thoughts': [
            {'text': 'Ein Wort fliegt an ihr vorbei. Alle sagen es heute.'},
            {'text': '„Ame. …Der Regen?"'},
          ],
          'interactions': [],
          'notes':
              'Leere Straße, sie geht; zwei Passanten flüchten unter ein '
              'Vordach. Passant A: 「あめ！」 Passantin B: 「あめ、あめ…」 '
              '(lachend, schulterzuckend).',
        },
        {
          'index': 3,
          'asset': 'assets/story/p04.jpg',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'かさ',
              'hitArea': [
                {'x': 0.30, 'y': 0.36},
                {'x': 0.70, 'y': 0.36},
                {'x': 0.70, 'y': 0.49},
                {'x': 0.30, 'y': 0.49},
              ],
              'tokens': [
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  'Drinnen: trocken. Und zum ersten Mal ein Schild, das '
                  'sich selbst erklärt.',
            },
            {'text': '„Kasa. Schirme. Das ist ja fast fair."'},
          ],
          'interactions': [],
          'notes':
              'Eingang der Shotengai (Einkaufsstraße), innen warm und '
              'trocken, halb tot: drei von zehn Läden offen. Vor einem '
              'Laden ein Korb voller Schirme, darüber ein Schild: 「かさ」.',
        },
      ],
    },
    // Seite 1 — Der Laden (P5-Kaputt bis P8-Danke)
    {
      'index': 1,
      'panels': [
        {
          'index': 4,
          'asset': 'assets/story/p05.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'あめ、あめ！',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ？',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.42, 'y': 0.20},
                {'x': 0.42, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
              ],
            },
          ],
          'thoughts': [
            {'text': 'Sie versteht kein Wort. Aber sie versteht alles.'},
            {
              'text':
                  '„Sag irgendwas. Das eine Wort, das die Frau im Zug zum '
                  'Schaffner gesagt hat — sag es."',
            },
          ],
          'interactions': [
            {
              'type': 'speak',
              'diegetic': true,
              'promptText':
                  'Mira braucht Hilfe. Hör das Wort an und sprich es: '
                  'すみません.',
              'target': 'すみません',
              'targetItemIds': ['lex_ja_sumimasen'],
              'reactionAsset': 'assets/story/p05_reaction.jpg',
              'reactionCaption':
                  'Er hat sie verstanden. Ihr erstes Wort in diesem Land — '
                  'und es funktioniert.',
            },
          ],
          'notes':
              'Miras eigener Schirm — aufgespannt ein Gerippe, zwei Streben '
              'gebrochen. Der alte Ladenbesitzer tritt heraus, sieht den '
              'Schirm, lacht nicht unfreundlich. Er: 「あめ、あめ！」 '
              '(deutet zum Himmel) — dann auf ihren Schirm: 「これ？」',
        },
        {
          'index': 5,
          'asset': 'assets/story/p06.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ、こわれた',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'こわれた、こわれた',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.42, 'y': 0.20},
                {'x': 0.42, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': '…こわれた…？',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  '„Kowareta. Kaputt. Wie ich das erste Wort meiner '
                  'Großmutter lerne: über einen kaputten Schirm."',
            },
          ],
          'interactions': [],
          'notes':
              'Der Ladenbesitzer nimmt ihren Schirm, begutachtet ihn '
              'fachmännisch. Er: 「これ、こわれた」 (zeigt auf die Streben) '
              '— 「こわれた、こわれた」 (kopfschüttelnd, fast zärtlich). '
              'Mira (leise): 「…こわれた…？」',
        },
        {
          'index': 6,
          'asset': 'assets/story/p07.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい。かさ。どうぞ',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': 'え？',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'え', 'itemId': null},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'どうぞ、どうぞ。かさ！',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.42, 'y': 0.20},
                {'x': 0.42, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  'Sie hat nichts bestellt. Sie hat nichts bezahlt. Er gibt '
                  'ihr den Schirm einfach so.',
            },
          ],
          'interactions': [],
          'notes':
              'Er greift in den Korb, hält ihr einen Schirm hin — den '
              'schlichtesten, aber heilen. Er: 「はい。かさ。どうぞ」 — '
              'Mira: 「え？」 — Er (nachdrücklich, lächelnd): 「どうぞ、'
              'どうぞ！」',
        },
        {
          'index': 7,
          'asset': 'assets/story/p08.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はいはい',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう… すみません… あめ… かさ…',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  'Es gibt genau ein Wort, das jetzt reicht. Sie kennt es '
                  'aus jedem Film. Jetzt zählt es zum ersten Mal.',
            },
          ],
          'interactions': [
            {
              'type': 'speak',
              'diegetic': true,
              'promptText': 'Sag es ihm: ありがとう.',
              'target': 'ありがとう',
              'targetItemIds': ['lex_ja_arigatou'],
              'reactionAsset': 'assets/story/p08_reaction.jpg',
              'reactionCaption':
                  'Ihr zweites Wort. Es wird nicht das letzte sein.',
            },
          ],
          'notes':
              'Mira mit dem neuen Schirm, halb verlegen, halb gerührt. Er '
              'winkt ab, lacht: 「はいはい」. Mira (im Gehen, leise '
              'übend): 「ありがとう… すみません… あめ… かさ…」',
        },
      ],
    },
    // Seite 2 — Das Zeichen (P9-Café bis P10-Schluss)
    {
      'index': 2,
      'panels': [
        {
          'index': 8,
          'asset': 'assets/story/p09.jpg',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'あめやどり',
              'hitArea': [
                {'x': 0.30, 'y': 0.36},
                {'x': 0.70, 'y': 0.36},
                {'x': 0.70, 'y': 0.49},
                {'x': 0.30, 'y': 0.49},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'やどり', 'itemId': null},
              ],
            },
          ],
          'thoughts': [
            {
              'text':
                  'Das Zeichen vom Zettel. Hier, auf einem Caféschild, in '
                  'der Straße, zu der ihre Großmutter sie geschickt hat.',
            },
            {'text': '„Das ist kein Zufall. Oder?"'},
          ],
          'interactions': [],
          'notes':
              'Weiter hinten in der Shotengai: ein kleines Café. Auf dem '
              'handgemalten Schild ein Wort — und Mira erstarrt: Das zweite '
              'Zeichen darauf ist 「め」. Dasselbe Zeichen wie auf ihrem '
              'Handrücken. Sie hält die Hand neben das Schild. Caféschild '
              '「あめやどり」 (antippbar; vorgelesen — verstehen muss sie '
              'es noch nicht).',
        },
        {
          'index': 9,
          'asset': 'assets/story/p10.jpg',
          'bubbles': [],
          'thoughts': [
            {
              'text':
                  'Auf dem Zettel standen einmal drei Zeilen. Mira kennt '
                  'jetzt: ein Zeichen und vier Wörter. Hinter dieser Tür '
                  'fängt der Rest an.',
            },
          ],
          'interactions': [],
          'notes':
              'Mira vor der Cafétür, die Hand am Griff, drinnen warmes '
              'Licht, eine Silhouette hinter dem Tresen.',
        },
      ],
    },
  ],
};

/// The 8 budgeted words from Folge 01 "Regen" (docs/story/DREHBUCH_FOLGE_01_V2.md),
/// with German meanings from the episode's own vocabulary table. あめ carries
/// the previous owner's margin note — unchanged from V1 (dosage rule: at
/// most one note per episode, §3.5).
const List<DictionaryEntry> folge01DictionaryEntries = [
  DictionaryEntry(
    id: 'lex_ja_sumimasen',
    headword: 'すみません',
    meaning: 'Entschuldigung / Verzeihung',
  ),
  DictionaryEntry(
    id: 'lex_ja_ame',
    headword: 'あめ',
    meaning: 'Regen',
    marginNote: '(unleserliche Randnotiz, Kanji und Datum)',
  ),
  DictionaryEntry(
    id: 'lex_ja_kasa',
    headword: 'かさ',
    meaning: 'Schirm',
  ),
  DictionaryEntry(
    id: 'lex_ja_kore',
    headword: 'これ',
    meaning: 'das hier',
  ),
  DictionaryEntry(
    id: 'lex_ja_kowareta',
    headword: 'こわれた',
    meaning: 'kaputt',
  ),
  DictionaryEntry(
    id: 'lex_ja_hai',
    headword: 'はい',
    meaning: 'ja',
  ),
  DictionaryEntry(
    id: 'lex_ja_douzo',
    headword: 'どうぞ',
    meaning: 'bitte / hier',
  ),
  DictionaryEntry(
    id: 'lex_ja_arigatou',
    headword: 'ありがとう',
    meaning: 'danke',
  ),
];
