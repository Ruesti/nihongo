# Phasenmodell — Nihongo App

Entwicklungsplan auf Basis von CLAUDE.md. Jede Phase ist eigenständig lieferbar.
Status: `[ ]` offen · `[x]` fertig · `[~]` in Arbeit

---

## Phase 0 — Scaffold ✓

Bereits abgeschlossen.

- [x] Flutter-Projekt erstellt (`com.softbrew/nihongo_app`)
- [x] Ordnerstruktur aus CLAUDE.md §3 angelegt
- [x] `pubspec.yaml` mit allen Dependencies (§2)
- [x] Git-Repo + GitHub Push

---

## Phase 1 — Japanisch: Core + Lektionen 1–15 (Free Tier)

**Ziel:** App ist spielbar. Lektion 01–15 end-to-end durchspielbar. Free Tier vollständig.

### 1.1 Core-Infrastruktur

- [ ] `lib/core/theme.dart` — Farbpalette + Typografie aus §6
- [ ] `lib/core/srs.dart` — SM-2 Algorithmus (§5)
- [ ] `lib/core/database.dart` — Drift-Schema: `SrsCards`, `UserProgress` (§5)
- [ ] `lib/core/tts_service.dart` — flutter_tts Wrapper, ja-JP (§8)
- [ ] `lib/core/stt_service.dart` — speech_to_text Wrapper, ja_JP (§8)
- [ ] `lib/core/api_key_service.dart` — SharedPreferences BYOK (§21.6)

### 1.2 Daten

- [ ] `lib/data/kana_data.dart` — Hiragana + Katakana vollständig (§3)
- [ ] `lib/data/vocab_800.dart` — erste 100 Wörter (Lektion 1–15) (§9)
- [ ] `lib/data/lessons.dart` — Lektionen 01–15 definiert (§4)
- [ ] `lib/data/grammar_tips.dart` — Grammatiknotizen Lektion 11–15

### 1.3 Models

- [ ] `lib/models/srs_card.dart` — Drift Table + SrsCard Dart-Klasse
- [ ] `lib/models/lesson.dart` — Lesson, LessonCategory, LessonStatus
- [ ] `lib/models/progress.dart` — UserProgress
- [ ] `lib/models/mascot_state.dart` — TamagoState enum

### 1.4 Übungstypen (Lektion 01–15)

- [ ] `exercises/kana_read.dart` — Zeichen → Romaji tippen
- [ ] `exercises/kana_write.dart` — Romaji hören → Zeichen erkennen
- [ ] `exercises/vocab_meaning.dart` — Wort → Bedeutung tippen
- [ ] `exercises/vocab_listen.dart` — Audio → Bedeutung
- [ ] `lib/features/lesson/exercise_factory.dart` — Übungsmix-Logik (§4)

### 1.5 UI-Screens

- [ ] `lib/app.dart` — go_router Routen, Riverpod ProviderScope, Theme
- [ ] `lib/features/home/home_screen.dart` — Dashboard (§12)
- [ ] `lib/features/home/lesson_grid.dart` — 2-spaltig, Fortschrittsbalken
- [ ] `lib/features/home/mascot_widget.dart` — Tamago-chan, Zustand egg/cracking
- [ ] `lib/features/lesson/lesson_screen.dart` — Lektions-Player, Fortschrittsbalken
- [ ] `lib/features/review/review_screen.dart` — SRS-Wiederholung
- [ ] `lib/features/settings/settings_screen.dart` — API Key Eingabe (§21.6)
- [ ] `lib/widgets/furigana_text.dart` — Ruby-Text über Kanji (§14)
- [ ] `lib/widgets/audio_button.dart` — TTS Play-Button
- [ ] `lib/widgets/grade_buttons.dart` — Nochmal/Schwer/Gut/Leicht (§5)
- [ ] `lib/widgets/progress_bar.dart`

### 1.6 Abschluss Phase 1

- [ ] Lektion 01–05 vollständig spielbar (Kana lesen/hören)
- [ ] SRS-Review funktioniert
- [ ] Tamago-chan Belohnungsanimation nach Lektionsabschluss
- [ ] `flutter build apk --debug` ohne Fehler

---

## Phase 2 — Japanisch: Lektionen 16–50 + Stories (Paid Tier)

**Ziel:** Vollständiger Lernpfad. FeatureGate aktiviert. RevenueCat integriert.

### 2.1 Daten

- [ ] `lib/data/vocab_800.dart` — alle 800 Wörter vollständig (§9)
- [ ] `lib/data/lessons.dart` — Lektionen 16–50
- [ ] Story-Texte für Lektionen 07, 14, 20, 28, 35, 42, 50 (§10)

### 2.2 Übungstypen (Phase 2)

- [ ] `exercises/vocab_speak.dart` — STT-Ausspracheübung (§8)
- [ ] `exercises/sentence_build.dart` — Wörter sortieren
- [ ] `exercises/free_write.dart` — Freitexteingabe + KI-Feedback

### 2.3 KI-Feedback

- [ ] `lib/core/api_client.dart` — Anthropic API, Haiku-4-5 (§11)
- [ ] FreeWrite-Exercise ruft Feedback ab
- [ ] Speak-Exercise: KI-Bewertung bei Sätzen

### 2.4 Story-Lektionen

- [ ] Story-Screen mit Furigana-Zeile-für-Zeile (§10)
- [ ] Verständnisfragen nach Story
- [ ] Tamago-chan als Protagonist eingeblendet

### 2.5 IAP

- [ ] `lib/core/purchases_service.dart` — RevenueCat SDK (§21.2)
- [ ] `lib/core/feature_gate.dart` — Paywall-Logik (§21.5)
- [ ] Paywall-Screen (§21.4)
- [ ] Restore Purchases

### 2.6 Progress-Screen

- [ ] `lib/features/progress/progress_screen.dart` — Lernkurve, Kana-Tabelle (§12)
- [ ] Tamago-chan Zustand peeking/halfOut/hatched je nach XP

### 2.7 Abschluss Phase 2

- [ ] Lektion 01–50 spielbar, Unlock-Logik aktiv (§14)
- [ ] Story 1–7 vollständig
- [ ] Tamago schlüpft bei Lektion 50
- [ ] IAP: Japanisch-Kauf funktioniert (Sandbox)

---

## Phase 3 — Kanji-Spiele-Modul

**Ziel:** Eigener "遊"-Tab. Vier Spiele spielbar. SRS-Integration.

### 3.1 Daten

- [ ] `lib/features/kanji_games/kanji_data.dart` — N5-Kanji (80 Einträge) (§18.1)
- [ ] KanjiVG SVG-Assets für N5 in `assets/kanji_svg/` (§18.1)

### 3.2 Games Hub

- [ ] `games_hub.dart` — 4-Karten-Grid, letztes Ergebnis je Spiel (§18.2)

### 3.3 Kanji Quiz

- [ ] `quiz/kanji_quiz_screen.dart` — Kanji → Tippen, 10–20 Karten (§18.3)
- [ ] `quiz/quiz_card.dart` — Flip-Animation, Feedback (§18.3)
- [ ] Ergebnis-Screen mit falschen Karten + "In SRS aufnehmen"

### 3.4 Blitz-Runde

- [ ] `blitz/blitz_screen.dart` — 60s Timer, Streak, Score (§18.4)
- [ ] `blitz/blitz_result.dart` — Highscore-Tabelle (10 Runs)

### 3.5 Nachmalen

- [ ] `trace/kanji_svg_loader.dart` — KanjiVG SVG parsen → Offset-Listen (§18.5)
- [ ] `trace/stroke_painter.dart` — CustomPainter: Vorlage + User-Striche (§18.5)
- [ ] `trace/stroke_validator.dart` — Frechet/DTW Ähnlichkeit ≥ 0.72 (§18.5)
- [ ] `trace/trace_screen.dart` — drei Schwierigkeitsstufen (§18.5)

### 3.6 Memory / Paare finden

- [ ] `memory/memory_screen.dart` — 3×4 und 4×4 Grid (§18.6)
- [ ] `memory/memory_card.dart` — 3D Flip-Animation (§18.6)
- [ ] Drei Paar-Varianten: Kanji↔Bedeutung, Kanji↔Lesung, Kanji↔Beispiel

### 3.7 Integration

- [ ] SRS-Schreiben nach jedem Spiel (§18.7)
- [ ] N4-Kanji freigeschaltet nach Fortschritt
- [ ] Tamago-Reaktionen: Highscore, 10 korrekte Striche, Memory-Bestzeit (§18.8)
- [ ] Bottom-Nav: fünfter Tab "遊" (§18.9)

---

## Phase 4 — KI-Konversation & Shadowing

**Ziel:** 「会話」Kaiwa-Tab. Freischalten ab Lektion 25.

### 4.1 Shadowing-Clips

- [ ] `ConversationClip` + `ClipLine` Datenmodell (§19.1)
- [ ] Mindestens 5 Beginner-Clips (TTS, zwei Stimmen) (§19.1)
- [ ] Shadowing-Screen: Blindhören → Zeile für Zeile → STT-Vergleich
- [ ] Geschwindigkeit 0.75× / 1.0× / 1.25×

### 4.2 KI-Konversation

- [ ] `ConversationScenario` Datenmodell (§19.2)
- [ ] Mindestens 4 Szenarien (Lektion 25–40) (§19.2)
- [ ] Streaming-Response (SSE) via http (§19.6)
- [ ] Konversations-Screen mit Nachrichtenhistorie (§19.2)
- [ ] TTS spielt Claudeantwort sofort ab
- [ ] Nachbesprechungs-Feedback per API (§19.2)

### 4.3 Telefon-Modus

- [ ] Kein Text, nur Audio rein/raus (§19.3)
- [ ] Freischaltung ab Lektion 40 + 10 Konversationssessions

### 4.4 Level-Gates

- [ ] `isKaiwaUnlocked` / `isPhoneUnlocked` (§19.5)
- [ ] Kaiwa-Tab ausgegraut mit Fortschrittsangabe bis Lektion 25
- [ ] Bottom-Nav: sechster Tab "会" (§19.7)

---

## Phase 5 — Travel Quicklearn

**Ziel:** Reise-Schnellkurs für alle Länder. Offline. On-Demand-Generierung.

- [ ] `TravelPhrase` + `TravelPack` Datenmodell (§20.9)
- [ ] 8 Kategorien: Top10, Begrüßung, Essen, Transport, Unterkunft, Einkaufen, Notfall, Smalltalk (§20.9)
- [ ] Japan, Spanien, Frankreich — kostenlos vorbelegt
- [ ] On-Demand-Generierung via Claude Sonnet (§20.9)
- [ ] Lokaler Cache (SQLite oder JSON-File)
- [ ] Travel-Tab in Bottom-Nav "✈"
- [ ] `canUseTravelCountry` FeatureGate (§21.5)

---

## Phase 6 — Mehrsprachigkeit: Koreanisch

**Ziel:** Vollständiger Lernpfad Koreanisch. LanguageModule Interface live.

- [ ] `lib/core/language_module.dart` — abstraktes Interface (§20.3)
- [ ] Dynamische Bottom-Nav nach `hasScript` (§20.4)
- [ ] Koreanisch-Modul: `hasScript: true`, Hangul-Tabellen (§20.5)
- [ ] Sprachauswahl-Screen beim App-Start (§20.8)
- [ ] Eigener SRS-Stack pro Sprache
- [ ] IAP: `com.softbrew.nihongo.lang_ko` (§21.3)

---

## Phase 7 — Mehrsprachigkeit: Spanisch + Fr/It

**Ziel:** Romanische Sprachen. Kein Script-Tab. Konjugation + Genus-Übungen.

- [ ] `VerbConjugateExercise` + `GenderExercise` (§20.6)
- [ ] Spanisch-Modul: `hasScript: false`, `hasConjugation: true`, `hasGender: true` (§20.5)
- [ ] Französisch-Modul (nach Spanisch: viel Reuse)
- [ ] Italienisch-Modul
- [ ] IAP: `lang_es`, `lang_fr`, `lang_it`
- [ ] Alles-Bundle aktivierbar (§21.1)

---

## Phase 8 — Mandarin

**Ziel:** Ton-System, Pinyin, Hanzi. Komplexeste Nicht-Europa-Sprache.

- [ ] `hasToneSystem: true` — Ton-Übungstyp: Ton hören → 1/2/3/4 wählen (§20.5)
- [ ] Pinyin als Romanisierung (`hasRomanization: true`)
- [ ] Hanzi Stroke-Order (KanjiVG Hanzi-Subset)
- [ ] HSK 1+2 Vokabular (§20.5)
- [ ] Pitch-Accent optional (§19.4)
- [ ] IAP: `lang_zh`

---

## Technische Querschnittsthemen

Diese Punkte betreffen mehrere Phasen und werden parallel bearbeitet:

- [ ] **CI/CD:** GitHub Actions — `flutter analyze` + `flutter test` bei jedem Push
- [ ] **iOS Berechtigungen:** `NSSpeechRecognitionUsageDescription`, `NSMicrophoneUsageDescription` (§14)
- [ ] **Analytics:** PostHog optional, Privacy-first (§21.7)
- [ ] **ASO:** Screenshots, Keywords, Promo-Text (§21.8)
- [ ] **Pitch Accent:** `PitchPattern` in `VocabEntry`, ab Phase 4 optional (§19.4)

---

## Meilenstein-Übersicht

| Phase | Inhalt                        | Aufwand  | Freischaltet         |
|-------|-------------------------------|----------|----------------------|
| 0     | Scaffold                      | ✓ fertig | —                    |
| 1     | Core + Lektionen 1–15         | ~3 Wo.   | Free Tier            |
| 2     | Lektionen 16–50 + IAP         | ~4 Wo.   | Paid: Japanisch 6,99€|
| 3     | Kanji-Spiele                  | ~3 Wo.   | im Japanisch-Bundle  |
| 4     | KI-Konversation + Shadowing   | ~2 Wo.   | im Japanisch-Bundle  |
| 5     | Travel Quicklearn             | ~1 Wo.   | Travel Bundle 2,99€  |
| 6     | Koreanisch                    | ~6 Wo.   | lang_ko 5,99€        |
| 7     | Spanisch + Fr/It              | ~3 Wo. je| lang_es/fr/it        |
| 8     | Mandarin                      | ~10 Wo.  | lang_zh 5,99€        |

**MVP für Store-Release:** Phase 1 + Phase 2 + Phase 3 (Kanji Quiz + Blitz).

---

*Softbrew Studio — nihongo_app — Stand: 2026-05-19*
