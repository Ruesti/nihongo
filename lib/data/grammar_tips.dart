class GrammarTip {
  final String id;
  final String titleDe;
  final String explanation;
  final List<String> examples;
  final List<String> exampleTranslations;
  final int lessonId;
  final String languageCode;

  const GrammarTip({
    required this.id,
    required this.titleDe,
    required this.explanation,
    required this.examples,
    required this.exampleTranslations,
    required this.lessonId,
    this.languageCode = 'ja',
  });
}

const List<GrammarTip> allGrammarTips = [
  GrammarTip(
    id: 'desu',
    titleDe: 'です (desu) — höfliche Aussageform',
    explanation:
        'です steht am Satzende und macht eine höfliche Aussage. '
        'Entspricht "ist" oder "bin". Bei Fragen: ですか？',
    examples: [
      'これはほんです。',
      'わたしはがくせいです。',
      'これはなんですか？',
    ],
    exampleTranslations: [
      'Das ist ein Buch.',
      'Ich bin Student.',
      'Was ist das?',
    ],
    lessonId: 11,
  ),
  GrammarTip(
    id: 'wa_ga',
    titleDe: 'は (wa) vs が (ga) — Thema vs. Subjekt',
    explanation:
        'は markiert das Thema des Satzes (worüber gesprochen wird). '
        'が markiert das grammatikalische Subjekt. '
        'は betont den Rest des Satzes, が betont das Subjekt.',
    examples: [
      'わたしはがくせいです。',
      'たまごがあります。',
      'なにがすきですか？',
    ],
    exampleTranslations: [
      'Ich bin Student. (Thema: ich)',
      'Es gibt ein Ei. (Subjekt: Ei)',
      'Was magst du? (Subjekt: was)',
    ],
    lessonId: 16,
  ),
  GrammarTip(
    id: 'wo',
    titleDe: 'を (wo) — Objektpartikel',
    explanation:
        'を markiert das direkte Objekt eines Verbs. '
        'Was wird gemacht/gegessen/getrunken etc.?',
    examples: [
      'ほんをよみます。',
      'みずをのみます。',
      'にほんごをべんきょうします。',
    ],
    exampleTranslations: [
      'Ich lese ein Buch.',
      'Ich trinke Wasser.',
      'Ich lerne Japanisch.',
    ],
    lessonId: 17,
  ),
  GrammarTip(
    id: 'ni',
    titleDe: 'に (ni) — Richtungs- und Ortspartikel',
    explanation:
        'に zeigt eine Richtung (wohin?) oder einen Ort (wo ist etwas?). '
        'Mit Bewegungsverben: Richtung. Mit います/あります: Ort.',
    examples: [
      'がっこうにいきます。',
      'つくえのうえにほんがあります。',
      'にほんにすんでいます。',
    ],
    exampleTranslations: [
      'Ich gehe zur Schule.',
      'Auf dem Tisch liegt ein Buch.',
      'Ich wohne in Japan.',
    ],
    lessonId: 25,
  ),
  GrammarTip(
    id: 'de',
    titleDe: 'で (de) — Partikel für Mittel und Ort',
    explanation:
        'で zeigt das Mittel (womit?) oder den Ort einer Handlung. '
        'Mit dem Zug, im Park spielen etc.',
    examples: [
      'でんしゃでいきます。',
      'こうえんであそびます。',
      'えいごでかきます。',
    ],
    exampleTranslations: [
      'Ich fahre mit dem Zug.',
      'Ich spiele im Park.',
      'Ich schreibe auf Englisch.',
    ],
    lessonId: 28,
  ),
  GrammarTip(
    id: 'te_form',
    titleDe: 'て形 — Verbindungsform',
    explanation:
        'Die て-Form verbindet Verben oder bildet Bitten. '
        '〜てください = Bitte machen Sie. '
        '〜ています = gerade tun / Zustand.',
    examples: [
      'ちょっとまってください。',
      'にほんごをべんきょうしています。',
      'てをあらってたべます。',
    ],
    exampleTranslations: [
      'Bitte warten Sie kurz.',
      'Ich lerne gerade Japanisch.',
      'Ich wasche die Hände und esse.',
    ],
    lessonId: 30,
  ),
  GrammarTip(
    id: 'tai_form',
    titleDe: '〜たい — Wunschform',
    explanation:
        '〜たい drückt einen Wunsch aus: "ich möchte...". '
        'Verb-Stamm + たい. Bei Verneinung: 〜たくない.',
    examples: [
      'すしをたべたいです。',
      'にほんにいきたいです。',
      'いまねたくないです。',
    ],
    exampleTranslations: [
      'Ich möchte Sushi essen.',
      'Ich möchte nach Japan gehen.',
      'Ich möchte jetzt nicht schlafen.',
    ],
    lessonId: 35,
  ),
  GrammarTip(
    id: 'koto_ga_dekiru',
    titleDe: '〜ことができる — Können/Fähigkeit',
    explanation:
        '〜ことができる drückt Fähigkeit aus: "kann...". '
        'Auch: 〜られる (Potential-Form).',
    examples: [
      'にほんごをはなすことができます。',
      'わたしはおよぐことができます。',
      'かんじをよむことができますか？',
    ],
    exampleTranslations: [
      'Ich kann Japanisch sprechen.',
      'Ich kann schwimmen.',
      'Können Sie Kanji lesen?',
    ],
    lessonId: 40,
  ),
  GrammarTip(
    id: 'ageru_morau_kureru',
    titleDe: 'あげる・もらう・くれる — Geben und Bekommen',
    explanation:
        'あげる: ich gebe (an jemanden). '
        'もらう: ich bekomme (von jemandem). '
        'くれる: jemand gibt mir (aus Sprecherperspektive).',
    examples: [
      'ともだちにプレゼントをあげます。',
      'せんせいにほんをもらいました。',
      'かれはわたしにはなをくれました。',
    ],
    exampleTranslations: [
      'Ich gebe dem Freund ein Geschenk.',
      'Ich habe vom Lehrer ein Buch bekommen.',
      'Er hat mir eine Blume gegeben.',
    ],
    lessonId: 43,
  ),
  GrammarTip(
    id: 'ba_form',
    titleDe: '〜ば — Konditionalis (wenn〜)',
    explanation:
        'Die ば-Form drückt eine Bedingung aus: "wenn ... dann". '
        'Verb-Stamm + ば. Bei い-Adjektiven: 〜ければ.',
    examples: [
      'はやくおきれば、まにあいます。',
      'たかければ、かいません。',
      'べんきょうすれば、じょうずになります。',
    ],
    exampleTranslations: [
      'Wenn ich früh aufstehe, bin ich pünktlich.',
      'Wenn es teuer ist, kaufe ich es nicht.',
      'Wenn du lernst, wirst du gut.',
    ],
    lessonId: 45,
  ),
];

// ── Koreanisch ───────────────────────────────────────────────────────────────
const List<GrammarTip> koGrammarTips = [
  GrammarTip(
    id: 'ko_ieyo', titleDe: '이에요 / 예요 — "sein"', languageCode: 'ko', lessonId: 11,
    explanation: 'Im Koreanischen gibt es kein einfaches "ist". Nach einem Konsonanten steht 이에요, nach einem Vokal 예요.',
    examples: ['저는 학생이에요.', '저는 마리아예요.', '이것은 책이에요.'],
    exampleTranslations: ['Ich bin Student.', 'Ich bin Maria.', 'Das ist ein Buch.'],
  ),
  GrammarTip(
    id: 'ko_topic', titleDe: '은/는 — Thema-Partikel', languageCode: 'ko', lessonId: 6,
    explanation: 'Die Partikel 은 (nach Konsonant) / 는 (nach Vokal) markiert das Thema des Satzes, ähnlich wie japanisch は.',
    examples: ['저는 독일 사람이에요.', '오늘은 좋아요.', '커피는 맛있어요.'],
    exampleTranslations: ['Ich bin Deutscher.', 'Heute ist es schön.', 'Kaffee ist lecker.'],
  ),
  GrammarTip(
    id: 'ko_object', titleDe: '을/를 — Objekt-Partikel', languageCode: 'ko', lessonId: 7,
    explanation: '을 (nach Konsonant) / 를 (nach Vokal) markiert das direkte Objekt — was jemand tut/macht.',
    examples: ['밥을 먹어요.', '책을 읽어요.', '커피를 마셔요.'],
    exampleTranslations: ['Ich esse Reis.', 'Ich lese ein Buch.', 'Ich trinke Kaffee.'],
  ),
  GrammarTip(
    id: 'ko_go', titleDe: '~고 싶어요 — "möchten"', languageCode: 'ko', lessonId: 13,
    explanation: 'Um Wünsche auszudrücken: Verbstamm + 고 싶어요.',
    examples: ['한국에 가고 싶어요.', '한국어를 배우고 싶어요.'],
    exampleTranslations: ['Ich möchte nach Korea gehen.', 'Ich möchte Koreanisch lernen.'],
  ),
];

// ── Spanisch ─────────────────────────────────────────────────────────────────
const List<GrammarTip> esGrammarTips = [
  GrammarTip(
    id: 'es_ar_conj', titleDe: '-AR Verben Präsens', languageCode: 'es', lessonId: 3,
    explanation: 'Verben auf -AR werden im Präsens nach Person konjugiert: yo -o, tú -as, él/ella -a, nosotros -amos, vosotros -áis, ellos -an.',
    examples: ['hablar → yo hablo', 'hablar → tú hablas', 'hablar → él habla'],
    exampleTranslations: ['ich spreche', 'du sprichst', 'er spricht'],
  ),
  GrammarTip(
    id: 'es_gender', titleDe: 'Genus: el / la', languageCode: 'es', lessonId: 4,
    explanation: 'Alle Substantive haben ein Genus (maskulin/feminin). Maskulin → el, feminin → la. Auf -o endet meist maskulin, auf -a meist feminin.',
    examples: ['el amigo (Freund)', 'la amiga (Freundin)', 'el agua (Wasser, Ausnahme!)'],
    exampleTranslations: ['maskulin', 'feminin', 'Ausnahme: agua ist feminin, nimmt aber el'],
  ),
  GrammarTip(
    id: 'es_ser_estar', titleDe: 'ser vs. estar — zwei "sein"', languageCode: 'es', lessonId: 5,
    explanation: 'Ser für permanente Eigenschaften (Nationalität, Beruf), estar für temporäre Zustände (Ort, Befinden).',
    examples: ['Soy alemán.', 'Estoy bien.', 'Madrid está en España.'],
    exampleTranslations: ['Ich bin Deutscher. (permanent)', 'Mir geht es gut. (temporär)', 'Madrid ist in Spanien. (Ort)'],
  ),
];

// ── Französisch ──────────────────────────────────────────────────────────────
const List<GrammarTip> frGrammarTips = [
  GrammarTip(
    id: 'fr_er_conj', titleDe: '-ER Verben Präsens', languageCode: 'fr', lessonId: 3,
    explanation: 'Verben auf -ER im Präsens: Stamm + e/es/e/ons/ez/ent. Parler → je parle, tu parles, il parle, nous parlons, vous parlez, ils parlent.',
    examples: ['je parle', 'tu parles', 'nous parlons'],
    exampleTranslations: ['ich spreche', 'du sprichst', 'wir sprechen'],
  ),
  GrammarTip(
    id: 'fr_articles', titleDe: 'Artikel le / la / les', languageCode: 'fr', lessonId: 4,
    explanation: 'Maskulin → le, Feminin → la, Plural → les. Vor Vokal: le/la → l\'.',
    examples: ['le livre (Buch)', 'la maison (Haus)', "l'eau (Wasser)"],
    exampleTranslations: ['maskulin', 'feminin', 'vor Vokal'],
  ),
  GrammarTip(
    id: 'fr_negation', titleDe: 'Verneinung: ne … pas', languageCode: 'fr', lessonId: 3,
    explanation: 'Verneinung durch ne … pas um das Verb: je ne parle pas = ich spreche nicht.',
    examples: ['Je ne parle pas anglais.', 'Il ne mange pas de viande.'],
    exampleTranslations: ['Ich spreche kein Englisch.', 'Er isst kein Fleisch.'],
  ),
];

// ── Italienisch ───────────────────────────────────────────────────────────────
const List<GrammarTip> itGrammarTips = [
  GrammarTip(
    id: 'it_are_conj', titleDe: '-ARE Verben Präsens', languageCode: 'it', lessonId: 3,
    explanation: 'Verben auf -ARE: Stamm + o/i/a/iamo/ate/ano. Parlare → io parlo, tu parli, lui parla, noi parliamo, voi parlate, loro parlano.',
    examples: ['io parlo', 'tu parli', 'noi parliamo'],
    exampleTranslations: ['ich spreche', 'du sprichst', 'wir sprechen'],
  ),
  GrammarTip(
    id: 'it_articles', titleDe: 'Artikel il / la', languageCode: 'it', lessonId: 4,
    explanation: 'Maskulin Singular: il (vor Konsonant), lo (vor s+Kons., z), l\' (vor Vokal). Feminin: la, l\' (vor Vokal).',
    examples: ['il libro (Buch)', 'la casa (Haus)', "l'amico (Freund)"],
    exampleTranslations: ['maskulin', 'feminin', 'vor Vokal'],
  ),
  GrammarTip(
    id: 'it_negation', titleDe: 'Verneinung: non', languageCode: 'it', lessonId: 3,
    explanation: 'Verneinung durch non direkt vor dem Verb: io non parlo = ich spreche nicht.',
    examples: ['Non parlo tedesco.', 'Non mangio carne.'],
    exampleTranslations: ['Ich spreche kein Deutsch.', 'Ich esse kein Fleisch.'],
  ),
];

// ── Mandarin ─────────────────────────────────────────────────────────────────
const List<GrammarTip> zhGrammarTips = [
  GrammarTip(
    id: 'zh_tones', titleDe: 'Die 4 Töne', languageCode: 'zh', lessonId: 1,
    explanation: 'Mandarin hat 4 Töne + einen neutralen Ton. Gleiche Laute, unterschiedliche Töne = unterschiedliche Bedeutung!',
    examples: ['mā (妈) — Ton 1', 'má (麻) — Ton 2', 'mǎ (马) — Ton 3', 'mà (骂) — Ton 4'],
    exampleTranslations: ['Mutter (hoch, eben)', 'Hanf (steigend)', 'Pferd (fallend-steigend)', 'schimpfen (fallend)'],
  ),
  GrammarTip(
    id: 'zh_shi', titleDe: '是 (shì) — "sein"', languageCode: 'zh', lessonId: 3,
    explanation: 'Das chinesische Äquivalent von "sein" ist 是 (shì). Verneinung: 不是 (bú shì). Kein Konjugieren nach Person!',
    examples: ['我是德国人。', '他不是日本人。', '这是书。'],
    exampleTranslations: ['Ich bin Deutscher.', 'Er ist kein Japaner.', 'Das ist ein Buch.'],
  ),
  GrammarTip(
    id: 'zh_ma', titleDe: '吗 (ma) — Fragesatz', languageCode: 'zh', lessonId: 3,
    explanation: 'Einen Aussagesatz in eine Ja/Nein-Frage verwandeln: einfach 吗 ans Ende hängen.',
    examples: ['你好吗？', '你是学生吗？', '好吃吗？'],
    exampleTranslations: ['Wie geht es dir?', 'Bist du Student?', 'Ist es lecker?'],
  ),
  GrammarTip(
    id: 'zh_meiyou', titleDe: '没有 (méiyǒu) — Verneinung Vergangenheit', languageCode: 'zh', lessonId: 4,
    explanation: 'Für die Verneinung von Verben außer 是: 不 + Verb im Präsens, 没 + Verb für Vergangenheit.',
    examples: ['我不吃肉。', '我没吃早饭。'],
    exampleTranslations: ['Ich esse kein Fleisch. (generell)', 'Ich habe kein Frühstück gegessen.'],
  ),
];
