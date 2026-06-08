enum TravelCategory {
  essential,
  greeting,
  food,
  transport,
  accommodation,
  shopping,
  emergency,
  smalltalk,
  numbers,
}

extension TravelCategoryExt on TravelCategory {
  String get labelDe {
    switch (this) {
      case TravelCategory.essential: return '⭐ Top 10';
      case TravelCategory.greeting: return '🙏 Begrüßung';
      case TravelCategory.food: return '🍜 Essen';
      case TravelCategory.transport: return '🚌 Transport';
      case TravelCategory.accommodation: return '🏨 Unterkunft';
      case TravelCategory.shopping: return '🛒 Einkaufen';
      case TravelCategory.emergency: return '🆘 Notfall';
      case TravelCategory.smalltalk: return '💬 Smalltalk';
      case TravelCategory.numbers: return '🔢 Zahlen';
    }
  }
}

class TravelPhrase {
  final String target;
  final String? romanization;
  final String germanDE;
  final String context;
  final bool isEssential;
  final TravelCategory category;

  const TravelPhrase({
    required this.target,
    this.romanization,
    required this.germanDE,
    required this.context,
    this.isEssential = false,
    required this.category,
  });
}

class TravelPack {
  final String countryCode;
  final String countryName;
  final String targetLanguage;
  final String ttsLocale;
  final List<TravelPhrase> phrases;
  final DateTime? generatedAt;

  const TravelPack({
    required this.countryCode,
    required this.countryName,
    required this.targetLanguage,
    required this.ttsLocale,
    required this.phrases,
    this.generatedAt,
  });
}

// Built-in pack for Japan — always available offline
const TravelPack japanPack = TravelPack(
  countryCode: 'jp',
  countryName: 'Japan',
  targetLanguage: 'Japanisch',
  ttsLocale: 'ja-JP',
  phrases: [
    TravelPhrase(
      target: 'ありがとうございます。',
      romanization: 'Arigatou gozaimasu.',
      germanDE: 'Vielen Dank.',
      context: 'Höfliche Form',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'すみません。',
      romanization: 'Sumimasen.',
      germanDE: 'Entschuldigung. / Excuse me.',
      context: 'Um Aufmerksamkeit bitten oder sich entschuldigen',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'これをください。',
      romanization: 'Kore wo kudasai.',
      germanDE: 'Das hier, bitte.',
      context: 'Beim Zeigen auf etwas',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'いくらですか？',
      romanization: 'Ikura desu ka?',
      germanDE: 'Wie viel kostet das?',
      context: 'Im Laden oder Restaurant',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'トイレはどこですか？',
      romanization: 'Toire wa doko desu ka?',
      germanDE: 'Wo ist die Toilette?',
      context: 'Notwendige Frage überall',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'わかりません。',
      romanization: 'Wakarimasen.',
      germanDE: 'Ich verstehe nicht.',
      context: 'Wenn man etwas nicht versteht',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'えいごをはなせますか？',
      romanization: 'Eigo wo hanasemasu ka?',
      germanDE: 'Sprechen Sie Englisch?',
      context: 'Als Fallback',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: '～へいきたいです。',
      romanization: '~ e ikitai desu.',
      germanDE: 'Ich möchte nach ~ gehen.',
      context: 'Im Taxi oder nach dem Weg fragen',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'たすけてください！',
      romanization: 'Tasukete kudasai!',
      germanDE: 'Hilfe!',
      context: 'Notfall',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'ゆっくりはなしてください。',
      romanization: 'Yukkuri hanashite kudasai.',
      germanDE: 'Bitte sprechen Sie langsamer.',
      context: 'Wenn jemand zu schnell spricht',
      isEssential: true,
      category: TravelCategory.essential,
    ),
    TravelPhrase(
      target: 'おはようございます。',
      romanization: 'Ohayou gozaimasu.',
      germanDE: 'Guten Morgen.',
      context: 'Formelle Begrüßung am Morgen',
      category: TravelCategory.greeting,
    ),
    TravelPhrase(
      target: 'こんにちは。',
      romanization: 'Konnichiwa.',
      germanDE: 'Guten Tag. / Hallo.',
      context: 'Begrüßung tagsüber',
      category: TravelCategory.greeting,
    ),
    TravelPhrase(
      target: 'こんばんは。',
      romanization: 'Konbanwa.',
      germanDE: 'Guten Abend.',
      context: 'Begrüßung abends',
      category: TravelCategory.greeting,
    ),
    TravelPhrase(
      target: 'さようなら。',
      romanization: 'Sayounara.',
      germanDE: 'Auf Wiedersehen.',
      context: 'Förmlicher Abschied',
      category: TravelCategory.greeting,
    ),
    TravelPhrase(
      target: 'よろしくおねがいします。',
      romanization: 'Yoroshiku onegaishimasu.',
      germanDE: 'Freut mich. / Bitte um Ihr Wohlwollen.',
      context: 'Beim Kennenlernen, unverzichtbar',
      category: TravelCategory.greeting,
    ),
    TravelPhrase(
      target: 'メニューをください。',
      romanization: 'Menyu wo kudasai.',
      germanDE: 'Die Speisekarte, bitte.',
      context: 'Im Restaurant',
      category: TravelCategory.food,
    ),
    TravelPhrase(
      target: 'おすすめはなんですか？',
      romanization: 'Osusume wa nan desu ka?',
      germanDE: 'Was empfehlen Sie?',
      context: 'Im Restaurant',
      category: TravelCategory.food,
    ),
    TravelPhrase(
      target: 'アレルギーがあります。',
      romanization: 'Arerugii ga arimasu.',
      germanDE: 'Ich habe Allergien.',
      context: 'Im Restaurant — dann Allergen nennen',
      category: TravelCategory.food,
    ),
    TravelPhrase(
      target: 'おかいけいをください。',
      romanization: 'Okaikei wo kudasai.',
      germanDE: 'Die Rechnung, bitte.',
      context: 'Im Restaurant',
      category: TravelCategory.food,
    ),
    TravelPhrase(
      target: 'おいしいです！',
      romanization: 'Oishii desu!',
      germanDE: 'Das ist lecker!',
      context: 'Kompliment ans Personal',
      category: TravelCategory.food,
    ),
    TravelPhrase(
      target: '～えきはどこですか？',
      romanization: '~ eki wa doko desu ka?',
      germanDE: 'Wo ist der Bahnhof ~?',
      context: 'Nach dem Weg fragen',
      category: TravelCategory.transport,
    ),
    TravelPhrase(
      target: 'このでんしゃは～にとまりますか？',
      romanization: 'Kono densha wa ~ ni tomarimasu ka?',
      germanDE: 'Hält dieser Zug in ~?',
      context: 'Im Zug',
      category: TravelCategory.transport,
    ),
    TravelPhrase(
      target: 'のりかえはどこですか？',
      romanization: 'Norikae wa doko desu ka?',
      germanDE: 'Wo ist der Umstieg?',
      context: 'In U-Bahn oder Zug',
      category: TravelCategory.transport,
    ),
    TravelPhrase(
      target: '～まで、いくらですか？',
      romanization: '~ made, ikura desu ka?',
      germanDE: 'Wie viel kostet es bis ~?',
      context: 'Im Taxi',
      category: TravelCategory.transport,
    ),
    TravelPhrase(
      target: 'チェックインをおねがいします。',
      romanization: 'Chekkuin wo onegaishimasu.',
      germanDE: 'Check-in, bitte.',
      context: 'Im Hotel',
      category: TravelCategory.accommodation,
    ),
    TravelPhrase(
      target: 'ちょっとまってください。',
      romanization: 'Chotto matte kudasai.',
      germanDE: 'Einen Moment bitte.',
      context: 'Vielseitig einsetzbar',
      category: TravelCategory.smalltalk,
    ),
    TravelPhrase(
      target: 'いち、に、さん、し、ご',
      romanization: 'Ichi, ni, san, shi, go',
      germanDE: 'Eins, zwei, drei, vier, fünf',
      context: 'Zahlen 1-5',
      category: TravelCategory.numbers,
    ),
    TravelPhrase(
      target: 'ろく、なな、はち、きゅう、じゅう',
      romanization: 'Roku, nana, hachi, kyuu, juu',
      germanDE: 'Sechs, sieben, acht, neun, zehn',
      context: 'Zahlen 6-10',
      category: TravelCategory.numbers,
    ),
    TravelPhrase(
      target: 'きゅうきゅうしゃをよんでください！',
      romanization: 'Kyuukyuusha wo yonde kudasai!',
      germanDE: 'Rufen Sie einen Krankenwagen!',
      context: 'Medizinischer Notfall',
      category: TravelCategory.emergency,
    ),
    TravelPhrase(
      target: 'けいさつをよんでください！',
      romanization: 'Keisatsu wo yonde kudasai!',
      germanDE: 'Rufen Sie die Polizei!',
      context: 'Sicherheitsnotfall',
      category: TravelCategory.emergency,
    ),
  ],
);

