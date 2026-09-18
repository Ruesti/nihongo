//
// Der Wortvorrat 800 als eine Liste (Spec §2). Die thematischen Teillisten
// sind reine Daten; hier werden sie zusammengesteckt und benannt.

import 'pool_entry.dart';
import 'vocab_pool_ja_adjektive_ausdruecke.dart';
import 'vocab_pool_ja_alltag.dart';
import 'vocab_pool_ja_cafe_einkaufen.dart';
import 'vocab_pool_ja_menschen.dart';
import 'vocab_pool_ja_orte_wetter.dart';
import 'vocab_pool_ja_verben.dart';
import 'vocab_pool_ja_zahlen_zeit.dart';

/// Größe des Grundwortschatzes, fest (Spec §2).
const int vocabPoolTarget = 800;

/// Höchstzahl der Reservewörter (Spec §2 „Reservebank").
const int vocabPoolBankMax = 40;

/// Alle Einträge inklusive Bank, in Listen-Reihenfolge.
const List<PoolEntry> vocabPoolJa = [
  ...vocabPoolJaZahlenZeit,
  ...vocabPoolJaCafeEinkaufen,
  ...vocabPoolJaMenschen,
  ...vocabPoolJaOrteWetter,
  ...vocabPoolJaVerben,
  ...vocabPoolJaAdjektiveAusdruecke,
  ...vocabPoolJaAlltag,
  ...vocabPoolJaBank,
];

/// Die 800 ohne Bank.
Iterable<PoolEntry> get vocabPoolCore =>
    vocabPoolJa.where((e) => e.status != PoolStatus.bank);

/// Die Wörter, die Folge 01 „Regen" eingeführt hat (IDs wie im Pack-Seed).
const List<String> folge01ItemIds = [
  'lex_ja_sumimasen',
  'lex_ja_ame',
  'lex_ja_kasa',
  'lex_ja_kore',
  'lex_ja_kowareta',
  'lex_ja_hai',
  'lex_ja_douzo',
  'lex_ja_arigatou',
  'lex_ja_eki',
  'lex_ja_samui',
  'lex_ja_mise',
  'lex_ja_hitori',
  'lex_ja_dame',
  'lex_ja_ikura',
  'lex_ja_iie',
  'lex_ja_hontou',
  'lex_ja_daijoubu',
  'lex_ja_koko',
];

/// Alt-Lexeme aus dem Seed vor der Story-Engine; behalten ihre englischen IDs.
const List<String> legacySeedIds = [
  'lex_ja_dog',
  'lex_ja_cat',
  'lex_ja_water',
  'lex_ja_eat',
  'lex_ja_what',
];

final Map<String, PoolEntry> _byId = {for (final e in vocabPoolJa) e.id: e};

PoolEntry? poolEntryById(String id) => _byId[id];
