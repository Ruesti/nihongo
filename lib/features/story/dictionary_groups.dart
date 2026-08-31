import '../../core/language_module.dart' show ScriptGroup;

/// Gojūon rows for browsing the diegetic dictionary (brief §3.2), each
/// extended to include its voiced (濁音) and semi-voiced (半濁音) kana in
/// the same row — e.g. た行 also covers だ/ぢ/づ/で/ど. `kana_data.dart`'s
/// `hiraganaGroups` only lists the 10 base seion rows, which would leave
/// words starting with a voiced kana (like どうぞ, one of Folge 01's own
/// budgeted words) unreachable when browsing by row. Kept local to this
/// feature rather than added to the shared `kana_data.dart`, since no other
/// feature currently needs full-row voiced-kana grouping.
const List<ScriptGroup> dictionaryGroups = [
  ScriptGroup(
    name: 'あ行',
    characters: ['あ', 'い', 'う', 'え', 'お'],
    romanizations: ['a', 'i', 'u', 'e', 'o'],
  ),
  ScriptGroup(
    name: 'か行',
    characters: ['か', 'き', 'く', 'け', 'こ', 'が', 'ぎ', 'ぐ', 'げ', 'ご'],
    romanizations: [
      'ka', 'ki', 'ku', 'ke', 'ko',
      'ga', 'gi', 'gu', 'ge', 'go',
    ],
  ),
  ScriptGroup(
    name: 'さ行',
    characters: ['さ', 'し', 'す', 'せ', 'そ', 'ざ', 'じ', 'ず', 'ぜ', 'ぞ'],
    romanizations: [
      'sa', 'shi', 'su', 'se', 'so',
      'za', 'ji', 'zu', 'ze', 'zo',
    ],
  ),
  ScriptGroup(
    name: 'た行',
    characters: ['た', 'ち', 'つ', 'て', 'と', 'だ', 'ぢ', 'づ', 'で', 'ど'],
    romanizations: [
      'ta', 'chi', 'tsu', 'te', 'to',
      'da', 'ji', 'zu', 'de', 'do',
    ],
  ),
  ScriptGroup(
    name: 'な行',
    characters: ['な', 'に', 'ぬ', 'ね', 'の'],
    romanizations: ['na', 'ni', 'nu', 'ne', 'no'],
  ),
  ScriptGroup(
    name: 'は行',
    characters: [
      'は', 'ひ', 'ふ', 'へ', 'ほ',
      'ば', 'び', 'ぶ', 'べ', 'ぼ',
      'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ',
    ],
    romanizations: [
      'ha', 'hi', 'fu', 'he', 'ho',
      'ba', 'bi', 'bu', 'be', 'bo',
      'pa', 'pi', 'pu', 'pe', 'po',
    ],
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
