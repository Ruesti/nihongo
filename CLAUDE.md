# CLAUDE.md — Nihongo App

> Kurzreferenz für Claude Code. Details liegen im Code; hier steht nur was NICHT ableitbar ist.

---

## Produktprinzip

Kein Duolingo-Klon. Kein Streak-Druck, keine Herzen. Stattdessen:
- Aktive Produktion (Tippen, Sprechen) statt Multiple Choice
- SM-2 Spaced Repetition
- KI-Feedback via Anthropic API (BYOK)
- Tamago-chan — ein Ei das langsam schlüpft, stiller Begleiter ohne Nervfaktor

---

## Tech Stack

| Paket | Zweck |
|---|---|
| `drift` + `sqlite3_flutter_libs` | Lokale DB, Code-Gen via `build_runner` |
| `flutter_riverpod` | State — `FutureProvider.family<T, String>` nach Sprache |
| `go_router` | Navigation, ShellRoute für Bottom-Nav |
| `flutter_tts` | TTS, Singleton `TtsService.instance` |
| `speech_to_text` | STT, Singleton `SttService.instance` |
| `purchases_flutter` | RevenueCat IAP |
| `http` | Anthropic API (claude-haiku-4-5-20251001) |
| `xml` | KanjiVG SVG-Parsing |

**Nach jeder Änderung an `database.dart`:** `dart run build_runner build`

**Drift-Typen:** `SrsCardRow` (DB-Row), `SrsCard` (Model in models/srs_card.dart), `UserStat`, `BlitzHighscore`, `MemoryBesttime`, `LessonProgressData`, `StudyHistoryData`. `dbProvider` liegt in `core/database.dart`.

---

## Design-System

```dart
// AppColors (lib/core/theme.dart)
paper  = 0xFFF4EDE0   ink   = 0xFF1A1410
paper2 = 0xFFEDE4D3   ink2  = 0xFF6B5F52
red    = 0xFFB5191C   red2  = 0xFF8A1315
green  = 0xFF2D6A4F   amber = 0xFF92400E
card   = 0xFFFAF6EE   border= 0xFFD6C9B5
```

Fonts: **Epilogue** (UI), **NotoSerifJP** (Japanisch), **ShipporiMinchoB1** (Headlines), **DM Mono** (Romaji).
Kein Emoji in der UI außer Tamago-chan. Icons: Material Outlined.

---

## IAP — RevenueCat Entitlements

```
Bundle ID: com.softbrew.nihongo

Entitlements:
  japanese_full     Lektionen 16–50, Kanji-Spiele, KI-Konversation
  travel_bundle     Alle Travel-Länder
  all_languages     Alles-Bundle
  lang_ko / lang_es / lang_fr / lang_it / lang_zh / lang_tr

Free: Lektionen 1–15, Quiz + Memory (N5), Travel jp/es/fr
```

`FeatureGate` (lib/core/feature_gate.dart) ist der einzige Ort mit Paywall-Logik.

---

## Bewusste Nicht-Entscheidungen

- Kein Streak-Counter
- Kein Multiple Choice (aktive Produktion > Tippen im Takt)
- Kein Romaji-Mode für Vokabeln
- Kein Backend (BYOK), kein Tracking außer RevenueCat

---

## Konventionen

- Dart: `snake_case` Dateien, `UpperCamelCase` Klassen
- Alle Provider: `FutureProvider.family<T, String>` keyed by `lang`
- SRS-Card IDs: `'hira_a'`, `'ja_v_001'`, `'kanji_日'`
- Japanische Strings als UTF-8 Literale (keine Escape-Sequenzen)
- Kommentare auf Deutsch oder Englisch

---

## Phasenstatus

| Phase | Inhalt | Status |
|---|---|---|
| 0 | Scaffold | ✓ |
| 1 | Core + Lektionen 1–15 | ✓ |
| 2 | Lektionen 16–50 + IAP + KI | ✓ |
| 3 | Kanji-Spiele (Quiz, Blitz, Trace, Memory) | ✓ |
| 4 | KI-Konversation (Kaiwa) | ✓ |
| 5 | Travel Quicklearn | ✓ |
| 6 | Koreanisch | ✓ (Daten, Lektionen, Grammatik, Hangul-Script) |
| 7 | Spanisch + Übungstypen (VerbConjugate, Gender) | ✓ |
| 8 | Mandarin | ✓ (Daten, Lektionen, Grammatik, Töne) |

`flutter analyze` — 0 errors, 0 warnings ✓

---

*Softbrew Studio — nihongo_app*
