import '../dictionary.dart';
import '../episode.dart';
import '../episode_validator.dart';

/// Folge 01 „Regen" (ep_ja_shotengai_01) als gebündelter Produktions-
/// Inhalt. Panel-Assets zeigen noch auf den Platzhalter; der Tausch gegen
/// die finalen Panels ist ein reiner Asset-Austausch in dieser Datei.
Episode loadFolge01() {
  final episode = Episode.fromJson(pilot01RegenJson);
  validateEpisode(episode);
  return episode;
}

/// Folge 01 — "Regen", encoded per docs/story/PILOT_01_REGEN.md.
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
      'Der Schirm ist geliehen, der Regen hört nicht auf. '
      'Und der Name über dem Café … den hat sie doch schon einmal gelesen?',
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
    // Seite 1 — Ankunft
    {
      'index': 1,
      'panels': [
        {
          'index': 1,
          'asset': 'assets/story/p01.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Weitwinkel. Kleiner Bahnsteig, keine Menschen. Regen fällt '
              'schräg durch Neonlicht. Sie steht mit Tasche, Kopf noch '
              'nicht gehoben. Kein Wort in den ersten sechs Panels.',
        },
        {
          'index': 2,
          'asset': 'assets/story/p02.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Detail: ihre Hand hält einen handgeschriebenen Zettel, '
              'Tinte läuft im Regen. Zettel zeigt verlaufene, unleserliche '
              'Kanji — kein Antippen, keine Übersetzung.',
        },
        {
          'index': 3,
          'asset': 'assets/story/p03.jpg',
          'bubbles': [],
          'thoughts': [
            {'text': 'Ich hätte anrufen sollen.'},
          ],
          'interactions': [],
          'notes':
              'Gedankenpanel, enger Ausschnitt, ihr Gesicht, Regen im Haar. '
              'Einziger Hinweis auf ein Davor. Nicht ausbauen.',
        },
        {
          'index': 4,
          'asset': 'assets/story/p04.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie geht los. Rücken zur Kamera, leere Straße, Wasser auf '
              'Asphalt, Kabelmasten gegen grauen Himmel.',
        },
      ],
    },
    // Seite 2 — Die Straße
    {
      'index': 2,
      'panels': [
        {
          'index': 5,
          'asset': 'assets/story/p05.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'anchorShot': 'A1',
          'notes':
              'Eingang der Shotengai. Überdachtes Dach, Regen prasselt '
              'darauf. Innen trocken, warmes Licht, halb tot: drei von '
              'sieben Rollläden geschlossen. Etablierungs-Panel.',
        },
        {
          'index': 6,
          'asset': 'assets/story/p06.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie tritt ein, schüttelt sich. Erleichterung. Erstes '
              'trockenes Bild der Folge.',
        },
      ],
    },
    // Seite 3 — Das Wörterbuch versagt
    {
      'index': 3,
      'panels': [
        {
          'index': 7,
          'asset': 'assets/story/p07.jpg',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'すみません',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.19},
                {'x': 0.52, 'y': 0.19},
              ],
              'tokens': [
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true,
             'reactionAsset': 'assets/story/p07_reaction.jpg',
             'reactionCaption': 'Sie hat dich gehört.'},
          ],
          'notes':
              'Eine ältere Frau kommt ihr entgegen, Einkaufstüte, zügig. '
              'Die Figur hebt die Hand. Ihr erstes Wort der Serie, im Zug '
              'auswendig gelernt. Sprechmoment 1.',
        },
        {
          'index': 8,
          'asset': 'assets/story/p08.jpg',
          'bubbles': [
            {
              'speakerId': 'passantin',
              'text': 'はい？',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.42, 'y': 0.05},
                {'x': 0.42, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': null},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Die Frau bleibt stehen, freundlich, wartend. はい ist hier '
              'noch nicht im Bestand — wird erst P19 als Item eingeführt, '
              'hier ist es Klang.',
        },
        {
          'index': 9,
          'asset': 'assets/story/p09.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [
            {'type': 'dictionary', 'diegetic': true},
          ],
          'notes':
              'Die Figur blättert hektisch im Wörterbuch. Nasse Finger, '
              'Seiten kleben. Es gibt nichts zu finden, weil sie nicht '
              'weiß, wonach sie sucht. Kernszene: das Werkzeug wird zuerst '
              'als nutzlos vorgeführt.',
        },
        {
          'index': 10,
          'asset': 'assets/story/p10.jpg',
          'bubbles': [],
          'thoughts': [
            {'text': 'Weg.'},
          ],
          'interactions': [],
          'notes':
              'Aufblick. Die Frau ist weg, nur noch ihr Rücken am Ende der '
              'Straße. Wörterbuch schließt automatisch. Erste Demütigung, '
              'nicht kommentiert.',
        },
      ],
    },
    // Seite 4 — Der Laden
    {
      'index': 4,
      'panels': [
        {
          'index': 11,
          'asset': 'assets/story/p11.jpg',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'あめ',
              'hitArea': [
                {'x': 0.32, 'y': 0.36},
                {'x': 0.62, 'y': 0.36},
                {'x': 0.62, 'y': 0.50},
                {'x': 0.32, 'y': 0.50},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
          ],
          'thoughts': [
            {'text': 'Regen.'},
          ],
          'interactions': [],
          'notes':
              'Sie steht allein, Blick nach oben aufs Dach, Regen trommelt. '
              'Ein Wetterbericht-Aushang an einer Litfaßsäule zeigt あめ — '
              'geschrieben, nicht gesprochen. Sie kann es hier noch nicht '
              'lesen, der Leser auch nicht. Erste Verknüpfung Klang↔Zeichen.',
        },
        {
          'index': 12,
          'asset': 'assets/story/p12.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Ein einzelnes warmes Licht weiter hinten. Offene Schiebetür. '
              'Ladenschild: Kanji, reine Bildtextur.',
        },
        {
          'index': 13,
          'asset': 'assets/story/p13.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie tritt unter das Vordach. Nicht hinein — sie will sich '
              'nur unterstellen.',
        },
        {
          'index': 14,
          'asset': 'assets/story/p14.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Innen, aus ihrer Perspektive: Werkbank, Werkzeug an der '
              'Wand, CRT-Fernseher läuft ohne Ton, ein alter Mann sitzt mit '
              'dem Rücken zu ihr und arbeitet. Er dreht sich nicht um — er '
              'registriert sie, sagt aber nichts. Das ist die Figur.',
        },
      ],
    },
    // Seite 5 — Der Moment
    {
      'index': 5,
      'panels': [
        {
          'index': 15,
          'asset': 'assets/story/p15.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Detail neben der Tür: ein Schirmständer mit drei Schirmen, '
              'einer mit gebrochener Speiche, halb geöffnet, verkantet. '
              'Erstauftritt kasa als Objekt, nicht als Wort — das Wort '
              'kommt erst P21. Prinzip: Ding vor Wort.',
        },
        {
          'index': 16,
          'asset': 'assets/story/p16.jpg',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Ihre Hände. Sie hat den Schirm aus dem Ständer genommen, '
              'dreht ihn, findet die Bruchstelle. Reines Handwerks-Panel, '
              'kein Gesicht. Der Kompetenz-Umschlag der Serie: sie tut, '
              'was sie nicht sagen kann.',
        },
        {
          'index': 17,
          'asset': 'assets/story/p17.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ、こわれた',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.52, 'y': 0.05},
                {'x': 0.52, 'y': 0.19},
                {'x': 0.06, 'y': 0.19},
              ],
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Er hat sich umgedreht, steht jetzt, zeigt auf den Schirm. '
              'Seine ersten Worte: drei Wörter, kein Satzbau, keine '
              'Höflichkeitsform — weil er so redet, nicht weil es '
              'didaktisch bequem ist.',
        },
        {
          'index': 18,
          'asset': 'assets/story/p18.jpg',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'これ… こわれた…？',
              'hitArea': [
                {'x': 0.48, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.19},
                {'x': 0.48, 'y': 0.19},
              ],
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie schaut ihn an, hat kein Wort verstanden außer dem '
              'Zeigen, spricht die Wörter probeweise nach — lautes '
              'Einprägen, keine Kommunikation. Die eigentliche Frage '
              'bleibt die Geste: sie nickt Richtung Werkbank.',
        },
        {
          'index': 19,
          'asset': 'assets/story/p19.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.36, 'y': 0.05},
                {'x': 0.36, 'y': 0.17},
                {'x': 0.06, 'y': 0.17},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Er, minimal — ein Nicken. はい wird hier als Item '
              'aufgenommen. Die erste gelungene Kommunikation der Folge — '
              'und es ist eine gestische, keine sprachliche.',
        },
      ],
    },
    // Seite 6 — Der Schirm
    {
      'index': 6,
      'panels': [
        {
          'index': 20,
          'asset': 'assets/story/p20.jpg',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Zeitraffer-Panel, breit. Sie an der Werkbank, er im '
              'Hintergrund am Fernseher, blickt nicht auf. Ein leiser Dank '
              'zwischendurch, ohne Antwort — passt zu seiner '
              'Zurückhaltung. Draußen dunkler geworden, Regen unverändert.',
        },
        {
          'index': 21,
          'asset': 'assets/story/p21.jpg',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい。かさ。どうぞ',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.56, 'y': 0.05},
                {'x': 0.56, 'y': 0.19},
                {'x': 0.06, 'y': 0.19},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie hält den reparierten Schirm hoch, geöffnet. Er steht in '
              'der Tür. Emotionaler Höhepunkt: er gibt ihr den Schirm, den '
              'sie selbst repariert hat — die Geste ist größer als das '
              'Objekt. Kein Panel darf das erklären.',
        },
        {
          'index': 22,
          'asset': 'assets/story/p22.jpg',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう… すみません',
              'hitArea': [
                {'x': 0.44, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.19},
                {'x': 0.44, 'y': 0.19},
              ],
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true,
             'reactionAsset': 'assets/story/p22_reaction.jpg',
             'reactionCaption': 'Der Ladenbesitzer nickt dir zu.'},
          ],
          'notes':
              'Sie, Schirm in beiden Händen, Verbeugung angedeutet. Hängt '
              'sumimasen an, weil es das einzige andere Wort ist, das sie '
              'hat — falsch verwendet, und dadurch richtig. Er zieht eine '
              'Augenbraue hoch statt sie zu korrigieren. Sprechmoment 2.',
        },
        {
          'index': 23,
          'asset': 'assets/story/p23.jpg',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'かさ…',
              'hitArea': [
                {'x': 0.56, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.17},
                {'x': 0.56, 'y': 0.17},
              ],
              'tokens': [
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Draußen, unter dem Schirm. Erste Einstellung mit ihr im '
              'Regen und trocken, Licht des Ladens hinter ihr noch an. Sie '
              'murmelt das neue Wort nach — erste unaufgeforderte '
              'japanische Äußerung der Folge.',
        },
        {
          'index': 24,
          'asset': 'assets/story/p24.jpg',
          'bubbles': [
            {
              'speakerId': 'buch',
              'text': 'あめ',
              'hitArea': [
                {'x': 0.30, 'y': 0.34},
                {'x': 0.62, 'y': 0.34},
                {'x': 0.62, 'y': 0.48},
                {'x': 0.30, 'y': 0.48},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'vorbesitzer_notiz',
              'text': '(unleserliche Randnotiz, Kanji und Datum)',
              'tokens': [],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'trace', 'diegetic': true,
             'reactionAsset': 'assets/story/p24_reaction.jpg',
             'reactionCaption': 'あめ — Regen. Dein erstes geschriebenes Zeichen.'},
          ],
          'notes':
              'Sie hat unter dem Vordach angehalten, das Wörterbuch '
              'aufgeschlagen, sucht あめ. Die Seite ist bereits '
              'angestrichen. Am Rand fremde Handschrift: ein kurzer '
              'Vermerk in Kanji und ein Datum — nicht antippbar, nicht '
              'auflösbar. Schlussbild: sie liest あめ zum ersten Mal '
              'selbst und zeichnet あ め nach — der eine diegetische '
              'Schreibmoment der Folge, Übergang in den Übungsmodus.',
        },
      ],
    },
  ],
};

/// The 8 budgeted words from Folge 01 "Regen" (docs/story/PILOT_01_REGEN.md),
/// with German meanings from the episode's own vocabulary table. あめ carries
/// the previous owner's margin note first alluded to at P24 ("ein kurzer
/// Vermerk in Kanji und ein Datum") — the only entry with one, matching the
/// brief's dosage rule of at most one note per episode (§3.5).
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
