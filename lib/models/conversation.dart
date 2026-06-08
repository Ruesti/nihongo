enum ConversationStyle { casual, polite, business }

// ── Shadowing ──────────────────────────────────────────────────────────────

class ClipLine {
  final String text;
  final String reading;
  final String translationDe;

  const ClipLine({
    required this.text,
    required this.reading,
    required this.translationDe,
  });
}

class ConversationClip {
  final String id;
  final String titleDe;
  final String context;
  final int minLevel;
  final List<ClipLine> lines;

  const ConversationClip({
    required this.id,
    required this.titleDe,
    required this.context,
    required this.minLevel,
    required this.lines,
  });
}

const List<ConversationClip> shadowingClips = [
  ConversationClip(
    id: 'morning_greeting',
    titleDe: 'Morgengrüße',
    context: 'Zwei Kollegen begrüßen sich am Morgen',
    minLevel: 15,
    lines: [
      ClipLine(text: 'おはようございます。', reading: 'おはようございます。', translationDe: 'Guten Morgen.'),
      ClipLine(text: 'おはようございます。今日もよろしくお願いします。', reading: 'おはようございます。きょうもよろしくおねがいします。', translationDe: 'Guten Morgen. Ich freue mich auf die Zusammenarbeit heute.'),
      ClipLine(text: 'こちらこそ、よろしくお願いします。', reading: 'こちらこそ、よろしくおねがいします。', translationDe: 'Meinerseits, ich freue mich auf die Zusammenarbeit.'),
    ],
  ),
  ConversationClip(
    id: 'shopping',
    titleDe: 'Einkaufen',
    context: 'Im Supermarkt nach dem Preis fragen',
    minLevel: 20,
    lines: [
      ClipLine(text: 'すみません、これはいくらですか？', reading: 'すみません、これはいくらですか？', translationDe: 'Entschuldigung, wie viel kostet das?'),
      ClipLine(text: 'それは三百円です。', reading: 'それはさんびゃくえんです。', translationDe: 'Das kostet 300 Yen.'),
      ClipLine(text: 'じゃあ、一つください。', reading: 'じゃあ、ひとつください。', translationDe: 'Dann geben Sie mir bitte eines.'),
      ClipLine(text: 'ありがとうございます。', reading: 'ありがとうございます。', translationDe: 'Vielen Dank.'),
    ],
  ),
  ConversationClip(
    id: 'directions',
    titleDe: 'Nach dem Weg fragen',
    context: 'Den Weg zur Station erfragen',
    minLevel: 25,
    lines: [
      ClipLine(text: 'すみません、駅はどこですか？', reading: 'すみません、えきはどこですか？', translationDe: 'Entschuldigung, wo ist der Bahnhof?'),
      ClipLine(text: 'この道をまっすぐ行って、右に曲がってください。', reading: 'このみちをまっすぐいって、みぎにまがってください。', translationDe: 'Gehen Sie diese Straße geradeaus und biegen Sie rechts ab.'),
      ClipLine(text: 'どのくらいかかりますか？', reading: 'どのくらいかかりますか？', translationDe: 'Wie lange dauert es?'),
      ClipLine(text: '歩いて五分くらいです。', reading: 'あるいてごふんくらいです。', translationDe: 'Zu Fuß etwa fünf Minuten.'),
    ],
  ),
  ConversationClip(
    id: 'restaurant_order',
    titleDe: 'Im Restaurant bestellen',
    context: 'Ein Gericht bestellen',
    minLevel: 25,
    lines: [
      ClipLine(text: 'ご注文はお決まりですか？', reading: 'ごちゅうもんはおきまりですか？', translationDe: 'Haben Sie Ihre Bestellung bereits entschieden?'),
      ClipLine(text: 'ラーメンを一つお願いします。', reading: 'ラーメンをひとつおねがいします。', translationDe: 'Einen Ramen bitte.'),
      ClipLine(text: 'お飲み物はいかがですか？', reading: 'おのみものはいかがですか？', translationDe: 'Was möchten Sie trinken?'),
      ClipLine(text: 'お水をください。', reading: 'おみずをください。', translationDe: 'Wasser bitte.'),
    ],
  ),
  ConversationClip(
    id: 'weather_chat',
    titleDe: 'Über das Wetter reden',
    context: 'Smalltalk über das Wetter',
    minLevel: 20,
    lines: [
      ClipLine(text: '今日はいい天気ですね。', reading: 'きょうはいいてんきですね。', translationDe: 'Heute ist schönes Wetter, oder?'),
      ClipLine(text: 'そうですね。でも、午後から雨が降るらしいですよ。', reading: 'そうですね。でも、ごごからあめがふるらしいですよ。', translationDe: 'Stimmt. Aber nachmittags soll es wohl regnen.'),
      ClipLine(text: 'そうなんですか。傘を持ってきてよかったです。', reading: 'そうなんですか。かさをもってきてよかったです。', translationDe: 'Wirklich? Gut, dass ich meinen Regenschirm mitgebracht habe.'),
    ],
  ),
];

class ConversationScenario {
  final String id;
  final String titleDe;
  final String titleJp;
  final String systemPrompt;
  final String openingLine;
  final int minLevel;
  final ConversationStyle style;
  final List<String> suggestedPhrases;

  const ConversationScenario({
    required this.id,
    required this.titleDe,
    required this.titleJp,
    required this.systemPrompt,
    required this.openingLine,
    required this.minLevel,
    required this.style,
    required this.suggestedPhrases,
  });
}

class ConversationMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ConversationMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

const List<ConversationScenario> conversationScenarios = [
  ConversationScenario(
    id: 'convenience_store',
    titleDe: 'Im Konbini',
    titleJp: 'コンビニで',
    openingLine: 'いらっしゃいませ！何かお探しですか？',
    minLevel: 25,
    style: ConversationStyle.polite,
    suggestedPhrases: [
      'これをください。',
      'いくらですか？',
      'ありがとうございます。',
      'レジ袋はいりません。',
    ],
    systemPrompt: '''You are a friendly convenience store clerk in Japan.
Speak ONLY in Japanese. Keep responses 1-2 sentences.
Match complexity to beginner-intermediate level: N5/N4 grammar.
Stay in character. React naturally. If the user makes grammar mistakes,
continue naturally but use the correct form once in your reply (implicit correction).
If the user seems stuck, offer one hint in brackets like [ヒント: 〜をください].''',
  ),
  ConversationScenario(
    id: 'izakaya',
    titleDe: 'In der Izakaya',
    titleJp: '居酒屋で',
    openingLine: 'いらっしゃいませ！今日は何名様ですか？',
    minLevel: 25,
    style: ConversationStyle.casual,
    suggestedPhrases: [
      '二人です。',
      'とりあえずビールをください。',
      'おすすめは何ですか？',
      'おいしいですね！',
    ],
    systemPrompt: '''You are a cheerful izakaya (Japanese pub) server.
Speak ONLY in Japanese. Keep responses 1-2 sentences.
Use natural, slightly casual speech. N5/N4 grammar level.
Be warm and friendly. Recommend food and drinks.
Implicit correction only — never break the roleplay.''',
  ),
  ConversationScenario(
    id: 'station',
    titleDe: 'Am Bahnhof',
    titleJp: '駅で',
    openingLine: 'すみません、何かお手伝いできますか？',
    minLevel: 25,
    style: ConversationStyle.polite,
    suggestedPhrases: [
      '渋谷まで一枚ください。',
      '次の電車は何時ですか？',
      '乗り換えはどこですか？',
      'ありがとうございます。',
    ],
    systemPrompt: '''You are a helpful train station staff member in Tokyo.
Speak ONLY in Japanese. Keep responses 1-2 sentences.
Use polite Japanese (〜ます/〜です). N5/N4 grammar level.
Help the user with directions, tickets, and train schedules.
Implicit correction only.''',
  ),
  ConversationScenario(
    id: 'friend_chat',
    titleDe: 'Mit einem Freund',
    titleJp: '友達との会話',
    openingLine: 'やあ！最近どう？',
    minLevel: 30,
    style: ConversationStyle.casual,
    suggestedPhrases: [
      '元気だよ！',
      '最近忙しかった。',
      '週末は何をしたの？',
      '一緒に遊ぼうよ！',
    ],
    systemPrompt: '''You are a friendly Japanese university student chatting with a friend.
Speak ONLY in Japanese using casual speech (〜だ/〜よ/〜ね).
Keep responses 1-2 sentences. N4/N3 grammar level.
Talk about everyday topics: hobbies, food, weekend plans, school.
Implicit correction only. Use natural filler words like ね、よ、さ.''',
  ),
  ConversationScenario(
    id: 'restaurant',
    titleDe: 'Im Restaurant',
    titleJp: 'レストランで',
    openingLine: 'こんにちは！ご予約はございますか？',
    minLevel: 25,
    style: ConversationStyle.polite,
    suggestedPhrases: [
      '予約していません。',
      '二人用のテーブルはありますか？',
      'メニューをください。',
      'これはおすすめですか？',
    ],
    systemPrompt: '''You are a polite restaurant host/server in Japan.
Speak ONLY in Japanese with keigo (polite language, ございます/いただく).
Keep responses 1-2 sentences. N5/N4 grammar level.
Guide the user through the restaurant experience.
Implicit correction only.''',
  ),
];
