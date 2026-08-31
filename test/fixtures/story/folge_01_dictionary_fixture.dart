import 'package:nihongo_app/features/story/dictionary.dart';

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
