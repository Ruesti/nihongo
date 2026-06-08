import '../core/language_module.dart';

class KanaEntry {
  final String kana;
  final String romaji;
  final String cardId;
  final bool isHiragana;

  const KanaEntry({
    required this.kana,
    required this.romaji,
    required this.cardId,
    required this.isHiragana,
  });
}

// Alle Hiragana
const List<KanaEntry> hiragana = [
  // あ行
  KanaEntry(kana: 'あ', romaji: 'a', cardId: 'hira_a', isHiragana: true),
  KanaEntry(kana: 'い', romaji: 'i', cardId: 'hira_i', isHiragana: true),
  KanaEntry(kana: 'う', romaji: 'u', cardId: 'hira_u', isHiragana: true),
  KanaEntry(kana: 'え', romaji: 'e', cardId: 'hira_e', isHiragana: true),
  KanaEntry(kana: 'お', romaji: 'o', cardId: 'hira_o', isHiragana: true),
  // か行
  KanaEntry(kana: 'か', romaji: 'ka', cardId: 'hira_ka', isHiragana: true),
  KanaEntry(kana: 'き', romaji: 'ki', cardId: 'hira_ki', isHiragana: true),
  KanaEntry(kana: 'く', romaji: 'ku', cardId: 'hira_ku', isHiragana: true),
  KanaEntry(kana: 'け', romaji: 'ke', cardId: 'hira_ke', isHiragana: true),
  KanaEntry(kana: 'こ', romaji: 'ko', cardId: 'hira_ko', isHiragana: true),
  // さ行
  KanaEntry(kana: 'さ', romaji: 'sa', cardId: 'hira_sa', isHiragana: true),
  KanaEntry(kana: 'し', romaji: 'shi', cardId: 'hira_shi', isHiragana: true),
  KanaEntry(kana: 'す', romaji: 'su', cardId: 'hira_su', isHiragana: true),
  KanaEntry(kana: 'せ', romaji: 'se', cardId: 'hira_se', isHiragana: true),
  KanaEntry(kana: 'そ', romaji: 'so', cardId: 'hira_so', isHiragana: true),
  // た行
  KanaEntry(kana: 'た', romaji: 'ta', cardId: 'hira_ta', isHiragana: true),
  KanaEntry(kana: 'ち', romaji: 'chi', cardId: 'hira_chi', isHiragana: true),
  KanaEntry(kana: 'つ', romaji: 'tsu', cardId: 'hira_tsu', isHiragana: true),
  KanaEntry(kana: 'て', romaji: 'te', cardId: 'hira_te', isHiragana: true),
  KanaEntry(kana: 'と', romaji: 'to', cardId: 'hira_to', isHiragana: true),
  // な行
  KanaEntry(kana: 'な', romaji: 'na', cardId: 'hira_na', isHiragana: true),
  KanaEntry(kana: 'に', romaji: 'ni', cardId: 'hira_ni', isHiragana: true),
  KanaEntry(kana: 'ぬ', romaji: 'nu', cardId: 'hira_nu', isHiragana: true),
  KanaEntry(kana: 'ね', romaji: 'ne', cardId: 'hira_ne', isHiragana: true),
  KanaEntry(kana: 'の', romaji: 'no', cardId: 'hira_no', isHiragana: true),
  // は行
  KanaEntry(kana: 'は', romaji: 'ha', cardId: 'hira_ha', isHiragana: true),
  KanaEntry(kana: 'ひ', romaji: 'hi', cardId: 'hira_hi', isHiragana: true),
  KanaEntry(kana: 'ふ', romaji: 'fu', cardId: 'hira_fu', isHiragana: true),
  KanaEntry(kana: 'へ', romaji: 'he', cardId: 'hira_he', isHiragana: true),
  KanaEntry(kana: 'ほ', romaji: 'ho', cardId: 'hira_ho', isHiragana: true),
  // ま行
  KanaEntry(kana: 'ま', romaji: 'ma', cardId: 'hira_ma', isHiragana: true),
  KanaEntry(kana: 'み', romaji: 'mi', cardId: 'hira_mi', isHiragana: true),
  KanaEntry(kana: 'む', romaji: 'mu', cardId: 'hira_mu', isHiragana: true),
  KanaEntry(kana: 'め', romaji: 'me', cardId: 'hira_me', isHiragana: true),
  KanaEntry(kana: 'も', romaji: 'mo', cardId: 'hira_mo', isHiragana: true),
  // や行
  KanaEntry(kana: 'や', romaji: 'ya', cardId: 'hira_ya', isHiragana: true),
  KanaEntry(kana: 'ゆ', romaji: 'yu', cardId: 'hira_yu', isHiragana: true),
  KanaEntry(kana: 'よ', romaji: 'yo', cardId: 'hira_yo', isHiragana: true),
  // ら行
  KanaEntry(kana: 'ら', romaji: 'ra', cardId: 'hira_ra', isHiragana: true),
  KanaEntry(kana: 'り', romaji: 'ri', cardId: 'hira_ri', isHiragana: true),
  KanaEntry(kana: 'る', romaji: 'ru', cardId: 'hira_ru', isHiragana: true),
  KanaEntry(kana: 'れ', romaji: 're', cardId: 'hira_re', isHiragana: true),
  KanaEntry(kana: 'ろ', romaji: 'ro', cardId: 'hira_ro', isHiragana: true),
  // わ行 + ん
  KanaEntry(kana: 'わ', romaji: 'wa', cardId: 'hira_wa', isHiragana: true),
  KanaEntry(kana: 'を', romaji: 'wo', cardId: 'hira_wo', isHiragana: true),
  KanaEntry(kana: 'ん', romaji: 'n', cardId: 'hira_n', isHiragana: true),
  // 濁音
  KanaEntry(kana: 'が', romaji: 'ga', cardId: 'hira_ga', isHiragana: true),
  KanaEntry(kana: 'ぎ', romaji: 'gi', cardId: 'hira_gi', isHiragana: true),
  KanaEntry(kana: 'ぐ', romaji: 'gu', cardId: 'hira_gu', isHiragana: true),
  KanaEntry(kana: 'げ', romaji: 'ge', cardId: 'hira_ge', isHiragana: true),
  KanaEntry(kana: 'ご', romaji: 'go', cardId: 'hira_go', isHiragana: true),
  KanaEntry(kana: 'ざ', romaji: 'za', cardId: 'hira_za', isHiragana: true),
  KanaEntry(kana: 'じ', romaji: 'ji', cardId: 'hira_ji', isHiragana: true),
  KanaEntry(kana: 'ず', romaji: 'zu', cardId: 'hira_zu', isHiragana: true),
  KanaEntry(kana: 'ぜ', romaji: 'ze', cardId: 'hira_ze', isHiragana: true),
  KanaEntry(kana: 'ぞ', romaji: 'zo', cardId: 'hira_zo', isHiragana: true),
  KanaEntry(kana: 'だ', romaji: 'da', cardId: 'hira_da', isHiragana: true),
  KanaEntry(kana: 'ぢ', romaji: 'ji', cardId: 'hira_di', isHiragana: true),
  KanaEntry(kana: 'づ', romaji: 'zu', cardId: 'hira_du', isHiragana: true),
  KanaEntry(kana: 'で', romaji: 'de', cardId: 'hira_de', isHiragana: true),
  KanaEntry(kana: 'ど', romaji: 'do', cardId: 'hira_do', isHiragana: true),
  KanaEntry(kana: 'ば', romaji: 'ba', cardId: 'hira_ba', isHiragana: true),
  KanaEntry(kana: 'び', romaji: 'bi', cardId: 'hira_bi', isHiragana: true),
  KanaEntry(kana: 'ぶ', romaji: 'bu', cardId: 'hira_bu', isHiragana: true),
  KanaEntry(kana: 'べ', romaji: 'be', cardId: 'hira_be', isHiragana: true),
  KanaEntry(kana: 'ぼ', romaji: 'bo', cardId: 'hira_bo', isHiragana: true),
  // 半濁音
  KanaEntry(kana: 'ぱ', romaji: 'pa', cardId: 'hira_pa', isHiragana: true),
  KanaEntry(kana: 'ぴ', romaji: 'pi', cardId: 'hira_pi', isHiragana: true),
  KanaEntry(kana: 'ぷ', romaji: 'pu', cardId: 'hira_pu', isHiragana: true),
  KanaEntry(kana: 'ぺ', romaji: 'pe', cardId: 'hira_pe', isHiragana: true),
  KanaEntry(kana: 'ぽ', romaji: 'po', cardId: 'hira_po', isHiragana: true),
];

// Alle Katakana
const List<KanaEntry> katakana = [
  KanaEntry(kana: 'ア', romaji: 'a', cardId: 'kata_a', isHiragana: false),
  KanaEntry(kana: 'イ', romaji: 'i', cardId: 'kata_i', isHiragana: false),
  KanaEntry(kana: 'ウ', romaji: 'u', cardId: 'kata_u', isHiragana: false),
  KanaEntry(kana: 'エ', romaji: 'e', cardId: 'kata_e', isHiragana: false),
  KanaEntry(kana: 'オ', romaji: 'o', cardId: 'kata_o', isHiragana: false),
  KanaEntry(kana: 'カ', romaji: 'ka', cardId: 'kata_ka', isHiragana: false),
  KanaEntry(kana: 'キ', romaji: 'ki', cardId: 'kata_ki', isHiragana: false),
  KanaEntry(kana: 'ク', romaji: 'ku', cardId: 'kata_ku', isHiragana: false),
  KanaEntry(kana: 'ケ', romaji: 'ke', cardId: 'kata_ke', isHiragana: false),
  KanaEntry(kana: 'コ', romaji: 'ko', cardId: 'kata_ko', isHiragana: false),
  KanaEntry(kana: 'サ', romaji: 'sa', cardId: 'kata_sa', isHiragana: false),
  KanaEntry(kana: 'シ', romaji: 'shi', cardId: 'kata_shi', isHiragana: false),
  KanaEntry(kana: 'ス', romaji: 'su', cardId: 'kata_su', isHiragana: false),
  KanaEntry(kana: 'セ', romaji: 'se', cardId: 'kata_se', isHiragana: false),
  KanaEntry(kana: 'ソ', romaji: 'so', cardId: 'kata_so', isHiragana: false),
  KanaEntry(kana: 'タ', romaji: 'ta', cardId: 'kata_ta', isHiragana: false),
  KanaEntry(kana: 'チ', romaji: 'chi', cardId: 'kata_chi', isHiragana: false),
  KanaEntry(kana: 'ツ', romaji: 'tsu', cardId: 'kata_tsu', isHiragana: false),
  KanaEntry(kana: 'テ', romaji: 'te', cardId: 'kata_te', isHiragana: false),
  KanaEntry(kana: 'ト', romaji: 'to', cardId: 'kata_to', isHiragana: false),
  KanaEntry(kana: 'ナ', romaji: 'na', cardId: 'kata_na', isHiragana: false),
  KanaEntry(kana: 'ニ', romaji: 'ni', cardId: 'kata_ni', isHiragana: false),
  KanaEntry(kana: 'ヌ', romaji: 'nu', cardId: 'kata_nu', isHiragana: false),
  KanaEntry(kana: 'ネ', romaji: 'ne', cardId: 'kata_ne', isHiragana: false),
  KanaEntry(kana: 'ノ', romaji: 'no', cardId: 'kata_no', isHiragana: false),
  KanaEntry(kana: 'ハ', romaji: 'ha', cardId: 'kata_ha', isHiragana: false),
  KanaEntry(kana: 'ヒ', romaji: 'hi', cardId: 'kata_hi', isHiragana: false),
  KanaEntry(kana: 'フ', romaji: 'fu', cardId: 'kata_fu', isHiragana: false),
  KanaEntry(kana: 'ヘ', romaji: 'he', cardId: 'kata_he', isHiragana: false),
  KanaEntry(kana: 'ホ', romaji: 'ho', cardId: 'kata_ho', isHiragana: false),
  KanaEntry(kana: 'マ', romaji: 'ma', cardId: 'kata_ma', isHiragana: false),
  KanaEntry(kana: 'ミ', romaji: 'mi', cardId: 'kata_mi', isHiragana: false),
  KanaEntry(kana: 'ム', romaji: 'mu', cardId: 'kata_mu', isHiragana: false),
  KanaEntry(kana: 'メ', romaji: 'me', cardId: 'kata_me', isHiragana: false),
  KanaEntry(kana: 'モ', romaji: 'mo', cardId: 'kata_mo', isHiragana: false),
  KanaEntry(kana: 'ヤ', romaji: 'ya', cardId: 'kata_ya', isHiragana: false),
  KanaEntry(kana: 'ユ', romaji: 'yu', cardId: 'kata_yu', isHiragana: false),
  KanaEntry(kana: 'ヨ', romaji: 'yo', cardId: 'kata_yo', isHiragana: false),
  KanaEntry(kana: 'ラ', romaji: 'ra', cardId: 'kata_ra', isHiragana: false),
  KanaEntry(kana: 'リ', romaji: 'ri', cardId: 'kata_ri', isHiragana: false),
  KanaEntry(kana: 'ル', romaji: 'ru', cardId: 'kata_ru', isHiragana: false),
  KanaEntry(kana: 'レ', romaji: 're', cardId: 'kata_re', isHiragana: false),
  KanaEntry(kana: 'ロ', romaji: 'ro', cardId: 'kata_ro', isHiragana: false),
  KanaEntry(kana: 'ワ', romaji: 'wa', cardId: 'kata_wa', isHiragana: false),
  KanaEntry(kana: 'ヲ', romaji: 'wo', cardId: 'kata_wo', isHiragana: false),
  KanaEntry(kana: 'ン', romaji: 'n', cardId: 'kata_n', isHiragana: false),
  KanaEntry(kana: 'ガ', romaji: 'ga', cardId: 'kata_ga', isHiragana: false),
  KanaEntry(kana: 'ギ', romaji: 'gi', cardId: 'kata_gi', isHiragana: false),
  KanaEntry(kana: 'グ', romaji: 'gu', cardId: 'kata_gu', isHiragana: false),
  KanaEntry(kana: 'ゲ', romaji: 'ge', cardId: 'kata_ge', isHiragana: false),
  KanaEntry(kana: 'ゴ', romaji: 'go', cardId: 'kata_go', isHiragana: false),
  KanaEntry(kana: 'ザ', romaji: 'za', cardId: 'kata_za', isHiragana: false),
  KanaEntry(kana: 'ジ', romaji: 'ji', cardId: 'kata_ji', isHiragana: false),
  KanaEntry(kana: 'ズ', romaji: 'zu', cardId: 'kata_zu', isHiragana: false),
  KanaEntry(kana: 'ゼ', romaji: 'ze', cardId: 'kata_ze', isHiragana: false),
  KanaEntry(kana: 'ゾ', romaji: 'zo', cardId: 'kata_zo', isHiragana: false),
  KanaEntry(kana: 'ダ', romaji: 'da', cardId: 'kata_da', isHiragana: false),
  KanaEntry(kana: 'デ', romaji: 'de', cardId: 'kata_de', isHiragana: false),
  KanaEntry(kana: 'ド', romaji: 'do', cardId: 'kata_do', isHiragana: false),
  KanaEntry(kana: 'バ', romaji: 'ba', cardId: 'kata_ba', isHiragana: false),
  KanaEntry(kana: 'ビ', romaji: 'bi', cardId: 'kata_bi', isHiragana: false),
  KanaEntry(kana: 'ブ', romaji: 'bu', cardId: 'kata_bu', isHiragana: false),
  KanaEntry(kana: 'ベ', romaji: 'be', cardId: 'kata_be', isHiragana: false),
  KanaEntry(kana: 'ボ', romaji: 'bo', cardId: 'kata_bo', isHiragana: false),
  KanaEntry(kana: 'パ', romaji: 'pa', cardId: 'kata_pa', isHiragana: false),
  KanaEntry(kana: 'ピ', romaji: 'pi', cardId: 'kata_pi', isHiragana: false),
  KanaEntry(kana: 'プ', romaji: 'pu', cardId: 'kata_pu', isHiragana: false),
  KanaEntry(kana: 'ペ', romaji: 'pe', cardId: 'kata_pe', isHiragana: false),
  KanaEntry(kana: 'ポ', romaji: 'po', cardId: 'kata_po', isHiragana: false),
];

// Gruppen für Script-Tab und language_module
const List<ScriptGroup> hiraganaGroups = [
  ScriptGroup(
    name: 'あ行',
    characters: ['あ', 'い', 'う', 'え', 'お'],
    romanizations: ['a', 'i', 'u', 'e', 'o'],
  ),
  ScriptGroup(
    name: 'か行',
    characters: ['か', 'き', 'く', 'け', 'こ'],
    romanizations: ['ka', 'ki', 'ku', 'ke', 'ko'],
  ),
  ScriptGroup(
    name: 'さ行',
    characters: ['さ', 'し', 'す', 'せ', 'そ'],
    romanizations: ['sa', 'shi', 'su', 'se', 'so'],
  ),
  ScriptGroup(
    name: 'た行',
    characters: ['た', 'ち', 'つ', 'て', 'と'],
    romanizations: ['ta', 'chi', 'tsu', 'te', 'to'],
  ),
  ScriptGroup(
    name: 'な行',
    characters: ['な', 'に', 'ぬ', 'ね', 'の'],
    romanizations: ['na', 'ni', 'nu', 'ne', 'no'],
  ),
  ScriptGroup(
    name: 'は行',
    characters: ['は', 'ひ', 'ふ', 'へ', 'ほ'],
    romanizations: ['ha', 'hi', 'fu', 'he', 'ho'],
  ),
  ScriptGroup(
    name: 'ま行',
    characters: ['ま', 'み', 'む', 'め', 'も'],
    romanizations: ['ma', 'mi', 'mu', 'me', 'mo'],
  ),
  ScriptGroup(
    name: 'や行',
    characters: ['や', 'ゆ', 'よ'],
    romanizations: ['ya', 'yu', 'yo'],
  ),
  ScriptGroup(
    name: 'ら行',
    characters: ['ら', 'り', 'る', 'れ', 'ろ'],
    romanizations: ['ra', 'ri', 'ru', 're', 'ro'],
  ),
  ScriptGroup(
    name: 'わ行',
    characters: ['わ', 'を', 'ん'],
    romanizations: ['wa', 'wo', 'n'],
  ),
];

const List<ScriptGroup> katakanaGroups = [
  ScriptGroup(
    name: 'ア行',
    characters: ['ア', 'イ', 'ウ', 'エ', 'オ'],
    romanizations: ['a', 'i', 'u', 'e', 'o'],
  ),
  ScriptGroup(
    name: 'カ行',
    characters: ['カ', 'キ', 'ク', 'ケ', 'コ'],
    romanizations: ['ka', 'ki', 'ku', 'ke', 'ko'],
  ),
  ScriptGroup(
    name: 'サ行',
    characters: ['サ', 'シ', 'ス', 'セ', 'ソ'],
    romanizations: ['sa', 'shi', 'su', 'se', 'so'],
  ),
  ScriptGroup(
    name: 'タ行',
    characters: ['タ', 'チ', 'ツ', 'テ', 'ト'],
    romanizations: ['ta', 'chi', 'tsu', 'te', 'to'],
  ),
  ScriptGroup(
    name: 'ナ行',
    characters: ['ナ', 'ニ', 'ヌ', 'ネ', 'ノ'],
    romanizations: ['na', 'ni', 'nu', 'ne', 'no'],
  ),
  ScriptGroup(
    name: 'ハ行',
    characters: ['ハ', 'ヒ', 'フ', 'ヘ', 'ホ'],
    romanizations: ['ha', 'hi', 'fu', 'he', 'ho'],
  ),
  ScriptGroup(
    name: 'マ行',
    characters: ['マ', 'ミ', 'ム', 'メ', 'モ'],
    romanizations: ['ma', 'mi', 'mu', 'me', 'mo'],
  ),
  ScriptGroup(
    name: 'ヤ行',
    characters: ['ヤ', 'ユ', 'ヨ'],
    romanizations: ['ya', 'yu', 'yo'],
  ),
  ScriptGroup(
    name: 'ラ行',
    characters: ['ラ', 'リ', 'ル', 'レ', 'ロ'],
    romanizations: ['ra', 'ri', 'ru', 're', 'ro'],
  ),
  ScriptGroup(
    name: 'ワ行',
    characters: ['ワ', 'ヲ', 'ン'],
    romanizations: ['wa', 'wo', 'n'],
  ),
];

// Hangul-Gruppen für Korean (vollständig: 10 Grundkonsonanten + 10 Grundvokale)
const List<ScriptGroup> hangulGroups = [
  ScriptGroup(
    name: '기본 모음 (Grundvokale)',
    characters: ['아', '야', '어', '여', '오', '요', '우', '유', '으', '이'],
    romanizations: ['a', 'ya', 'eo', 'yeo', 'o', 'yo', 'u', 'yu', 'eu', 'i'],
  ),
  ScriptGroup(
    name: '복합 모음 (Zusammengesetzte Vokale)',
    characters: ['애', '에', '외', '위', '의', '와', '워', '왜', '웨'],
    romanizations: ['ae', 'e', 'oe', 'wi', 'ui', 'wa', 'wo', 'wae', 'we'],
  ),
  ScriptGroup(
    name: '평음 자음 (Einfache Konsonanten)',
    characters: ['가', '나', '다', '라', '마', '바', '사', '아', '자', '하'],
    romanizations: ['g/k', 'n', 'd/t', 'r/l', 'm', 'b/p', 's', 'ng', 'j', 'h'],
  ),
  ScriptGroup(
    name: '격음 자음 (Aspirierte Konsonanten)',
    characters: ['카', '타', '파', '차'],
    romanizations: ['k', 't', 'p', 'ch'],
  ),
  ScriptGroup(
    name: '경음 자음 (Tense Konsonanten)',
    characters: ['까', '따', '빠', '싸', '짜'],
    romanizations: ['kk', 'tt', 'pp', 'ss', 'jj'],
  ),
  ScriptGroup(
    name: '받침 (Endkonsonanten, Batchim)',
    characters: ['박', '산', '달', '감', '집', '길', '봄', '한'],
    romanizations: ['bak', 'san', 'dal', 'gam', 'jip', 'gil', 'bom', 'han'],
  ),
];

// Pinyin-Gruppen für Mandarin
const List<ScriptGroup> pinyinGroups = [
  ScriptGroup(
    name: '声母 (Initiale)',
    characters: ['b', 'p', 'm', 'f', 'd', 't', 'n', 'l'],
    romanizations: ['b', 'p', 'm', 'f', 'd', 't', 'n', 'l'],
  ),
  ScriptGroup(
    name: '韵母 (Finale)',
    characters: ['a', 'o', 'e', 'i', 'u', 'ü', 'ai', 'ei'],
    romanizations: ['a', 'o', 'e', 'i', 'u', 'ü', 'ai', 'ei'],
  ),
];
