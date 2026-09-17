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
      {'id': 'lex_ja_eki', 'refType': 'lexeme'},
      {'id': 'lex_ja_samui', 'refType': 'lexeme'},
      {'id': 'lex_ja_mise', 'refType': 'lexeme'},
      {'id': 'lex_ja_hitori', 'refType': 'lexeme'},
      {'id': 'lex_ja_dame', 'refType': 'lexeme'},
      {'id': 'lex_ja_ikura', 'refType': 'lexeme'},
      {'id': 'lex_ja_iie', 'refType': 'lexeme'},
      {'id': 'lex_ja_hontou', 'refType': 'lexeme'},
      {'id': 'lex_ja_daijoubu', 'refType': 'lexeme'},
      {'id': 'lex_ja_koko', 'refType': 'lexeme'},
    ],
    'glyphs': [
      {'glyph': 'あ'},
      {'glyph': 'め'},
      {'glyph': 'か'},
      {'glyph': '駅'},
      {'glyph': '傘'},
    ],
  },
  // Erklärungsblock der Wirtin (Spec Café-Nachbesprechung §6): Gebrauch in
  // ein bis zwei Sätzen, höchstens zwei Varianten. Varianten sind Wissen am
  // Wort, keine Items — der Validator hält sie vom Budget fern.
  'debrief': {
    'lex_ja_eki': {
      'usage': '„Bahnhof". Auf dem Schild steht es als Kanji 駅, gesprochen '
          'えき — Miras erstes Schild in dieser Stadt.',
      'variants': [],
    },
    'lex_ja_samui': {
      'usage': '„kalt" — fürs Wetter und fürs Frösteln, nicht für kaltes '
          'Wasser.',
      'variants': [
        {
          'form': 'つめたい',
          'reading': 'つめたい',
          'meaning': 'kalt zum Anfassen',
          'note': 'Wasser, Hände, ein Getränk',
        },
        {
          'form': 'さむいですね',
          'reading': 'さむいですね',
          'meaning': 'kalt, nicht wahr?',
          'note': 'der Smalltalk-Satz',
        },
      ],
    },
    'lex_ja_ame': {
      'usage': '„Regen". Das Wort vom Zettel, das erste, das Mira selbst '
          'gelesen hat. Vorsicht: mit anderer Betonung heißt あめ auch '
          '„Bonbon" — man hört den Unterschied.',
      'variants': [],
    },
    'lex_ja_sumimasen': {
      'usage': '„Entschuldigung" — aber genauso „Hallo, darf ich mal?". Mira '
          'benutzt es, um jemanden anzusprechen, nicht nur zum Entschuldigen.',
      'variants': [
        {
          'form': 'ごめんなさい',
          'reading': 'ごめんなさい',
          'meaning': 'tut mir leid',
          'note': 'persönlicher, für eigene Fehler',
        },
        {
          'form': 'すみませんでした',
          'reading': 'すみませんでした',
          'meaning': 'Entschuldigung',
          'note': 'für etwas, das schon passiert ist',
        },
      ],
    },
    'lex_ja_koko': {
      'usage': '„hier" — der Ort bei mir.',
      'variants': [
        {'form': 'そこ', 'reading': 'そこ', 'meaning': 'da', 'note': 'bei dir'},
        {
          'form': 'あそこ',
          'reading': 'あそこ',
          'meaning': 'dort',
          'note': 'weit weg von uns beiden',
        },
      ],
    },
    'lex_ja_mise': {
      'usage': '„Laden, Geschäft" — jeder Laden in der Shotengai ist ein みせ.',
      'variants': [
        {
          'form': 'おみせ',
          'reading': 'おみせ',
          'meaning': 'Laden',
          'note': 'höflicher, mit お davor',
        },
      ],
    },
    'lex_ja_hitori': {
      'usage': '„allein" oder „eine Person". Mira ist ひとり in dieser Stadt.',
      'variants': [
        {
          'form': 'ひとりで',
          'reading': 'ひとりで',
          'meaning': 'allein (als Art und Weise)',
          'note': 'allein reisen, allein essen',
        },
      ],
    },
    'lex_ja_kasa': {
      'usage': '„Schirm". Erst ein Ding in Miras Hand, dann ein Wort. Als '
          'Kanji: 傘.',
      'variants': [
        {
          'form': 'あまがさ',
          'reading': 'あまがさ',
          'meaning': 'Regenschirm',
          'note': 'wörtlich あめ + かさ',
        },
      ],
    },
    'lex_ja_kore': {
      'usage': '„das hier" — das Ding bei mir, in meiner Hand.',
      'variants': [
        {'form': 'それ', 'reading': 'それ', 'meaning': 'das da', 'note': 'bei dir'},
        {
          'form': 'あれ',
          'reading': 'あれ',
          'meaning': 'das dort',
          'note': 'weit weg',
        },
      ],
    },
    'lex_ja_kowareta': {
      'usage': '„kaputt" — genauer: „ist kaputtgegangen". Die Form sagt: Es '
          'ist schon passiert.',
      'variants': [
        {
          'form': 'こわれている',
          'reading': 'こわれている',
          'meaning': 'ist kaputt',
          'note': 'als Zustand',
        },
        {
          'form': 'こわれました',
          'reading': 'こわれました',
          'meaning': 'ist kaputtgegangen',
          'note': 'dasselbe, höflicher',
        },
      ],
    },
    'lex_ja_dame': {
      'usage': '„geht nicht / kaputt / nein" — das Alltagswort, wenn etwas '
          'nicht geht.',
      'variants': [
        {
          'form': 'だめです',
          'reading': 'だめです',
          'meaning': 'geht nicht',
          'note': 'höflicher',
        },
        {
          'form': 'むり',
          'reading': 'むり',
          'meaning': 'unmöglich',
          'note': 'noch deutlicher',
        },
      ],
    },
    'lex_ja_ikura': {
      'usage': '„wie viel (kostet das)?" — die Frage im Laden.',
      'variants': [
        {
          'form': 'いくらですか',
          'reading': 'いくらですか',
          'meaning': 'wie viel kostet das?',
          'note': 'höflich, der ganze Satz',
        },
      ],
    },
    'lex_ja_iie': {
      'usage': '„nein" — höflich, im Gespräch mit Fremden.',
      'variants': [
        {'form': 'いや', 'reading': 'いや', 'meaning': 'nein', 'note': 'locker'},
        {
          'form': 'ううん',
          'reading': 'ううん',
          'meaning': 'nein',
          'note': 'unter Freunden, oft nur ein Laut',
        },
      ],
    },
    'lex_ja_hontou': {
      'usage': '„wirklich?" — als Frage, wenn man etwas kaum glauben kann.',
      'variants': [
        {
          'form': 'ほんとうに',
          'reading': 'ほんとうに',
          'meaning': 'wirklich (als Verstärkung)',
          'note': 'wirklich kalt, wirklich allein',
        },
        {
          'form': 'ほんと',
          'reading': 'ほんと',
          'meaning': 'wirklich?',
          'note': 'kurz, gesprochen',
        },
      ],
    },
    'lex_ja_daijoubu': {
      'usage': '„alles gut / in Ordnung" — als Frage und als Antwort.',
      'variants': [
        {
          'form': 'だいじょうぶです',
          'reading': 'だいじょうぶです',
          'meaning': 'alles in Ordnung',
          'note': 'höflicher',
        },
        {
          'form': 'へいき',
          'reading': 'へいき',
          'meaning': 'macht nichts',
          'note': 'lockerer',
        },
      ],
    },
    'lex_ja_hai': {
      'usage': '„ja". Und beim Überreichen: „hier, bitte" (はい、どうぞ).',
      'variants': [
        {'form': 'ええ', 'reading': 'ええ', 'meaning': 'ja', 'note': 'weicher'},
        {
          'form': 'うん',
          'reading': 'うん',
          'meaning': 'ja',
          'note': 'locker, unter Freunden',
        },
      ],
    },
    'lex_ja_douzo': {
      'usage': '„bitte, hier" — wenn man etwas gibt oder anbietet. Nicht das '
          '„bitte" einer Bitte. Das Gegenstück ist ありがとう.',
      'variants': [],
    },
    'lex_ja_arigatou': {
      'usage': '„danke".',
      'variants': [
        {
          'form': 'ありがとうございます',
          'reading': 'ありがとうございます',
          'meaning': 'vielen Dank',
          'note': 'höflicher — zu Fremden und Älteren',
        },
        {
          'form': 'どうも',
          'reading': 'どうも',
          'meaning': 'danke',
          'note': 'kurz und beiläufig',
        },
      ],
    },
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
              'text': 'みなみまち駅',
              'hitArea': [
                {'x': 0.30, 'y': 0.36},
                {'x': 0.70, 'y': 0.36},
                {'x': 0.70, 'y': 0.49},
                {'x': 0.30, 'y': 0.49},
              ],
              'tokens': [
                {'surface': 'みなみまち', 'itemId': null},
                {'surface': '駅', 'reading': 'えき', 'itemId': 'lex_ja_eki'},
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
              'text': 'あめ！あめ！',
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
              'speakerId': 'passant_b',
              'text': 'あめ、あめ… さむい、さむい',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
                {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
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
              'text': '傘',
              'hitArea': [
                {'x': 0.30, 'y': 0.36},
                {'x': 0.70, 'y': 0.36},
                {'x': 0.70, 'y': 0.49},
                {'x': 0.30, 'y': 0.49},
              ],
              'tokens': [
                {'surface': '傘', 'reading': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': '…あめ',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
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
              'text': 'これ？かさ？みせ！',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.49, 'y': 0.20},
                {'x': 0.49, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'ひとり？',
              'hitArea': [
                {'x': 0.06, 'y': 0.33},
                {'x': 0.49, 'y': 0.33},
                {'x': 0.49, 'y': 0.43},
                {'x': 0.06, 'y': 0.43},
              ],
              'tokens': [
                {'surface': 'ひとり', 'itemId': 'lex_ja_hitori'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': '…はい。ひとり',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'ひとり', 'itemId': 'lex_ja_hitori'},
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
              'text': 'はい、こわれた、こわれた。だめ、だめ',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.49, 'y': 0.20},
                {'x': 0.49, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
                {'surface': 'だめ', 'itemId': 'lex_ja_dame'},
                {'surface': 'だめ', 'itemId': 'lex_ja_dame'},
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
              'text': 'え？いくら？いくら？',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'え', 'itemId': null},
                {'surface': 'いくら', 'itemId': 'lex_ja_ikura'},
                {'surface': 'いくら', 'itemId': 'lex_ja_ikura'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'いいえ、いいえ。どうぞ、どうぞ。かさ！',
              'hitArea': [
                {'x': 0.06, 'y': 0.20},
                {'x': 0.49, 'y': 0.20},
                {'x': 0.49, 'y': 0.31},
                {'x': 0.06, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'いいえ', 'itemId': 'lex_ja_iie'},
                {'surface': 'いいえ', 'itemId': 'lex_ja_iie'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': '…ほんとう？',
              'hitArea': [
                {'x': 0.56, 'y': 0.20},
                {'x': 0.92, 'y': 0.20},
                {'x': 0.92, 'y': 0.31},
                {'x': 0.56, 'y': 0.31},
              ],
              'tokens': [
                {'surface': 'ほんとう', 'itemId': 'lex_ja_hontou'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'ほんとう。だいじょうぶ、だいじょうぶ',
              'hitArea': [
                {'x': 0.06, 'y': 0.33},
                {'x': 0.49, 'y': 0.33},
                {'x': 0.49, 'y': 0.43},
                {'x': 0.06, 'y': 0.43},
              ],
              'tokens': [
                {'surface': 'ほんとう', 'itemId': 'lex_ja_hontou'},
                {'surface': 'だいじょうぶ', 'itemId': 'lex_ja_daijoubu'},
                {'surface': 'だいじょうぶ', 'itemId': 'lex_ja_daijoubu'},
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
              'text': 'ありがとう… すみません… あめ… かさ… いいえ… だいじょうぶ… えき… みせ…',
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
                {'surface': 'いいえ', 'itemId': 'lex_ja_iie'},
                {'surface': 'だいじょうぶ', 'itemId': 'lex_ja_daijoubu'},
                {'surface': 'えき', 'itemId': 'lex_ja_eki'},
                {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
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
            {
              'speakerId': 'protagonist',
              'text': 'ここ…？あめ…やどり？',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'ここ', 'itemId': 'lex_ja_koko'},
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
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ここ…',
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.18},
                {'x': 0.52, 'y': 0.18},
              ],
              'tokens': [
                {'surface': 'ここ', 'itemId': 'lex_ja_koko'},
              ],
            },
          ],
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

/// The 18 budgeted words from Folge 01 "Regen" (docs/story/DREHBUCH_FOLGE_01_V2.md),
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
  DictionaryEntry(
    id: 'lex_ja_eki',
    headword: 'えき',
    meaning: 'Bahnhof (Kanji: 駅)',
  ),
  DictionaryEntry(
    id: 'lex_ja_samui',
    headword: 'さむい',
    meaning: 'kalt',
  ),
  DictionaryEntry(
    id: 'lex_ja_mise',
    headword: 'みせ',
    meaning: 'Laden, Geschäft',
  ),
  DictionaryEntry(
    id: 'lex_ja_hitori',
    headword: 'ひとり',
    meaning: 'allein / eine Person',
  ),
  DictionaryEntry(
    id: 'lex_ja_dame',
    headword: 'だめ',
    meaning: 'geht nicht / kaputt / nein',
  ),
  DictionaryEntry(
    id: 'lex_ja_ikura',
    headword: 'いくら',
    meaning: 'wie viel (kostet das)?',
  ),
  DictionaryEntry(
    id: 'lex_ja_iie',
    headword: 'いいえ',
    meaning: 'nein',
  ),
  DictionaryEntry(
    id: 'lex_ja_hontou',
    headword: 'ほんとう',
    meaning: 'wirklich?',
  ),
  DictionaryEntry(
    id: 'lex_ja_daijoubu',
    headword: 'だいじょうぶ',
    meaning: 'alles gut / in Ordnung',
  ),
  DictionaryEntry(
    id: 'lex_ja_koko',
    headword: 'ここ',
    meaning: 'hier',
  ),
];
