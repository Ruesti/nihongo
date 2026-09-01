/// Folge 01 — "Regen", encoded per docs/story/PILOT_01_REGEN.md.
const Map<String, dynamic> pilot01RegenJson = {
  'id': 'ep_ja_shotengai_01',
  'seasonId': 'season_ja_shotengai',
  'orderIndex': 1,
  'title': 'Regen',
  'locale': 'ja',
  'era': '1996',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'すみません',
              'tokens': [
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
          'notes':
              'Eine ältere Frau kommt ihr entgegen, Einkaufstüte, zügig. '
              'Die Figur hebt die Hand. Ihr erstes Wort der Serie, im Zug '
              'auswendig gelernt. Sprechmoment 1.',
        },
        {
          'index': 8,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'passantin',
              'text': 'はい？',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'あめ',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Ein einzelnes warmes Licht weiter hinten. Offene Schiebetür. '
              'Ladenschild: Kanji, reine Bildtextur.',
        },
        {
          'index': 13,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie tritt unter das Vordach. Nicht hinein — sie will sich '
              'nur unterstellen.',
        },
        {
          'index': 14,
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ、こわれた',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'これ… こわれた…？',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい。かさ。どうぞ',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう… すみません',
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
          'notes':
              'Sie, Schirm in beiden Händen, Verbeugung angedeutet. Hängt '
              'sumimasen an, weil es das einzige andere Wort ist, das sie '
              'hat — falsch verwendet, und dadurch richtig. Er zieht eine '
              'Augenbraue hoch statt sie zu korrigieren. Sprechmoment 2.',
        },
        {
          'index': 23,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'かさ…',
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
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'buch',
              'text': 'あめ',
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
            {'type': 'trace', 'diegetic': true},
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
