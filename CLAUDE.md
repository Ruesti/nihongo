# CLAUDE.md — Nihongo App (Flutter)

> Dieser Brief ist für Claude Code. Lies ihn vollständig bevor du irgendeine Datei erzeugst.
> Ziel: Eine Flutter-App für Japanisch-Lernen. Kein Duolingo-Klon. Echter Lerneffekt.

---

## 1. Produktvision

**Kernprinzip:** Weniger Gamification, mehr Lerneffekt. Keine Herzen, kein Leben-System, kein Streak-Druck. Stattdessen: aktive Produktion, Spaced Repetition, echtes Feedback.

**Was die App macht:**
- Japanisch lernen von Null — Kana → Vokabeln → Sätze → Grammatik
- Gemischtes Lernen: nicht "erst ein Jahr Kanji", sondern alles parallel, gewichtet nach Level
- Hören (TTS), Sprechen (STT), Lesen, Schreiben (Tippen) als vier gleichwertige Kanäle
- KI-Feedback auf freie Eingaben (Anthropic API)
- Abgeschlossene Lektionen mit klarem Fortschritt
- Kleines Maskottchen (Tamago-chan, ein Ei das langsam schlüpft) als stiller Begleiter
- Kein Druck, aber Erfolgserlebnisse durch Lektionsabschlüsse

---

## 2. Tech Stack

```
Flutter 3.x (null safety, Material 3)
Dart
flutter_tts           — Text-to-Speech (japanische Stimme)
speech_to_text        — Spracheingabe
drift + sqlite3       — lokale Datenbank (SRS-Karten, Fortschritt)
flutter_riverpod      — State Management
go_router             — Navigation
http                  — Anthropic API calls
just_audio            — Audio-Playback für vorgerenderte Clips (optional)
lottie                — Maskottchen-Animationen
shared_preferences    — einfache Einstellungen
flutter_svg           — SVG-Strichfolge-Rendering (Kanji-Nachmalen)
sensors_plus          — (optional) Shake-to-shuffle im Schnell-Quiz
```

**Anthropic API:** claude-haiku-4-5 für Grammatik-Feedback (günstig, schnell).
API Key wird vom User in den Einstellungen eingegeben (BYOK-Modell, kein Backend nötig).

---

## 3. Ordnerstruktur

```
lib/
  main.dart
  app.dart                    # Router, Theme, Provider-Setup
  
  core/
    theme.dart                # Design-System (siehe §6)
    srs.dart                  # SM-2 Algorithmus
    database.dart             # Drift DB Schema
    api_client.dart           # Anthropic API
    tts_service.dart          # flutter_tts Wrapper
    stt_service.dart          # speech_to_text Wrapper
  
  data/
    kana_data.dart            # Hiragana + Katakana Tabellen
    vocab_800.dart            # 800 Wörter (N5 + N4, strukturiert)
    lessons.dart              # Lektionsdefinitionen
    grammar_tips.dart         # Grammatik-Notizen
  
  models/
    srs_card.dart             # SRS-Karte (Drift Table)
    lesson.dart               # Lektion
    progress.dart             # User-Fortschritt
    mascot_state.dart         # Tamago-chan Zustand
  
  features/
    home/
      home_screen.dart        # Dashboard
      lesson_grid.dart        # Lektions-Übersicht
      mascot_widget.dart      # Tamago-chan
    
    lesson/
      lesson_screen.dart      # Lektions-Player
      exercise_factory.dart   # Welche Übung kommt als nächste
      exercises/
        kana_read.dart        # Zeichen → Romaji tippen
        kana_write.dart       # Romaji hören → Zeichen erkennen
        vocab_meaning.dart    # Wort → Bedeutung tippen
        vocab_listen.dart     # Audio → Bedeutung
        vocab_speak.dart      # Wort anzeigen → laut sprechen
        sentence_build.dart   # Wörter in Reihenfolge bringen
        free_write.dart       # Freies Schreiben mit KI-Feedback
    
    review/
      review_screen.dart      # SRS-Wiederholung fälliger Karten
    
    progress/
      progress_screen.dart    # Statistiken, Lernkurve
    
    kanji_games/
      games_hub.dart              # Spielauswahl-Screen (4 Spiele)
      kanji_data.dart             # N5+N4 Kanji mit Daten (siehe §18)
      quiz/
        kanji_quiz_screen.dart    # Klassisches Quiz: Kanji → Bedeutung
        quiz_card.dart            # Karten-Widget mit Flip-Animation
      blitz/
        blitz_screen.dart         # Schnellraterunde mit Countdown
        blitz_result.dart         # Ergebnis-Screen
      trace/
        trace_screen.dart         # Kanji nachmalen mit Finger
        stroke_painter.dart       # CustomPainter fuer User-Striche
        stroke_validator.dart     # Strich-Vergleich gegen SVG-Vorlage
        kanji_svg_loader.dart     # SVG-Strichfolge-Daten laden
      memory/
        memory_screen.dart        # Kanji-Paare finden (Konzentration)
        memory_card.dart          # Einzelne Karte (Kanji ↔ Bedeutung)

    settings/
      settings_screen.dart    # API Key, TTS-Stimme, etc.
  
  widgets/
    furigana_text.dart        # Text mit Lesehilfe über Kanji
    audio_button.dart         # Play-Button für TTS
    progress_bar.dart         # Einfacher Fortschrittsbalken
    grade_buttons.dart        # Nochmal / Schwer / Gut / Leicht
```

---

## 4. Lektionssystem

### Struktur

Lektionen sind nummeriert, abgeschlossen, mit klarem Ziel.
Jede Lektion hat: Titel, Lernziel, Karten-Set, Übungstypen, Abschlussbedingung.

```dart
class Lesson {
  final int id;
  final String titleJp;
  final String titleDe;
  final String goal;          // z.B. "Hiragana あ-お sicher lesen"
  final LessonCategory category;
  final List<String> cardIds; // welche SRS-Karten
  final int xpReward;
  final bool isUnlocked;      // abhängig von vorheriger Lektion
}

enum LessonCategory { kana, vocab, grammar, listening, speaking, story }
```

### Lektionen-Curriculum (erste 30)

```
Lektion 01 — Erste Zeichen: あ い う え お  [kana]
Lektion 02 — か行: か き く け こ            [kana]
Lektion 03 — Hören: あ-こ erkennen          [listening]
Lektion 04 — さ行 + た行                    [kana]
Lektion 05 — Erste Wörter: いぬ、ねこ、き   [vocab]  ← GEMISCHT ab hier
Lektion 06 — な行 + は行                    [kana]
Lektion 07 — Story 1: Tamago-chan wacht auf  [story]
Lektion 08 — Sprechen: あ-の laut sagen     [speaking]
Lektion 09 — ま行 + や行 + ら行 + わ行      [kana]
Lektion 10 — Hiragana komplett: Review      [kana]
Lektion 11 — Erste Sätze: これは＿です。    [grammar]
Lektion 12 — Katakana ア-コ                 [kana]
Lektion 13 — Vokabeln: Zahlen 1-10          [vocab]
Lektion 14 — Story 2: Tamago geht einkaufen [story]
Lektion 15 — Katakana komplett              [kana]
Lektion 16 — Grammatik: は vs が            [grammar]
Lektion 17 — Verben: たべる のむ みる いく  [vocab]
Lektion 18 — Sprechen: Sätze formulieren    [speaking]
Lektion 19 — Adjektive: おおきい、ちいさい  [vocab]
Lektion 20 — Story 3: Tamago schlüpft halb  [story]
...
Lektion 50 — Story 7: Tamago ist erwacht    [story]  ← vollständiges Schlüpfen
```

**Story-Lektionen** sind besonders: kurze, einfache Texte auf Japanisch (mit Furigana), die Tamago-chans Geschichte erzählen. Der Text wird vorangepasst an das aktuelle Level. Nach dem Lesen: Verständnisfragen.

### Übungsmix pro Lektion

Der `ExerciseFactory` entscheidet welche Übung kommt, basierend auf:
- Lektions-Kategorie
- User-Level (Karten-Reife)
- Zuletzt gemachter Übungstyp (nicht zwei gleiche hintereinander)

Frühe Lektionen: 80% Lesen/Tippen, 20% Hören
Mittlere Lektionen: 50% Lesen, 30% Hören, 20% Sprechen
Späte Lektionen: 30% Lesen, 30% Hören, 40% Sprechen + Schreiben

---

## 5. SRS — Spaced Repetition

SM-2 Algorithmus. Jede SRS-Karte hat:

```dart
// Drift Table
class SrsCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text()();          // z.B. "hira_a", "v_001"
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get reading => text().nullable()();
  RealColumn get ease => real().withDefault(const Constant(2.5))();
  IntColumn get interval => integer().withDefault(const Constant(0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get dueAt => integer().withDefault(const Constant(0))();  // epoch ms
  TextColumn get cardType => text()();        // 'kana' | 'vocab' | 'grammar'
}
```

Grade 0 (Nochmal): interval = 0, ease -= 0.2
Grade 1 (Schwer):  interval *= 0.8, ease -= 0.15
Grade 2 (Gut):     interval = 1/4/interval*ease (reps 0/1/2+)
Grade 3 (Leicht):  wie Gut * 1.3, ease += 0.1

---

## 6. Design System

### Farbpalette

```dart
// lib/core/theme.dart
class AppColors {
  static const paper    = Color(0xFFF4EDE0);  // warmes Papier-Beige
  static const paper2   = Color(0xFFEDE4D3);
  static const ink      = Color(0xFF1A1410);  // fast-schwarz
  static const ink2     = Color(0xFF6B5F52);  // mittleres Braun
  static const red      = Color(0xFFB5191C);  // Japanisch-Rot (Torii)
  static const red2     = Color(0xFF8A1315);
  static const green    = Color(0xFF2D6A4F);
  static const amber    = Color(0xFF92400E);
  static const card     = Color(0xFFFAF6EE);
  static const border   = Color(0xFFD6C9B5);
}
```

### Typografie

```dart
// Google Fonts
// - Noto Serif JP: alle japanischen Zeichen
// - Epilogue: UI-Text, Labels
// - DM Mono: Romaji, Code-artige Elemente
// - Shippori Mincho B1: Große Überschriften, Ziffern

static const jpStyle = TextStyle(
  fontFamily: 'NotoSerifJP',
  fontSize: 32,
);
static const uiStyle = TextStyle(
  fontFamily: 'Epilogue',
  fontSize: 14,
  letterSpacing: 0.02,
);
```

### Karten-Design

Karten haben:
- Weißer/paper-farbener Hintergrund
- 1px border in `border`-Farbe
- Subtiler Schatten (2px, 8% opacity)
- Keine harten Ecken (borderRadius: 4)
- Keine bunten Hintergründe außer für Feedback (grün/rot)

### Keine Emojis in der UI

Außer für Tamago-chan. UI-Symbole: Linie-Icons (Lucide oder Material Outlined).

---

## 7. Maskottchen: Tamago-chan 🥚

**Konzept:** Ein Ei, das über die Lernreise langsam schlüpft. Kein aufdringlicher Charakter. Taucht dezent auf, reagiert auf Fortschritt. Keine Dialoge die nerven.

**Zustände (Lottie-Animationen oder einfache SVG-Sequenz):**
```dart
enum TamagoState {
  egg,          // Level 0-10: einfaches Ei, wippt leicht
  cracking,     // Level 11-20: kleiner Riss sichtbar
  peeking,      // Level 21-35: Augen schauen raus
  halfOut,      // Level 36-49: halb raus, winkt
  hatched,      // Level 50+: vollständig geschlüpft, freut sich
}
```

**Wann erscheint Tamago-chan:**
- Auf dem Home-Screen (klein, oben rechts)
- Nach Lektionsabschluss (größer, mit kurzer Animation)
- In Story-Lektionen als Protagonist
- Nie während Übungen (lenkt ab)

**Belohnungsmoment:**
Nach jeder abgeschlossenen Lektion: kurze Animation (0.5s), XP-Zähler läuft hoch, Tamago wippt. Kein Konfetti, kein Lärm. Stilles Erfolgserlebnis.

**XP-System (minimal):**
- Lektion abschließen: +50-100 XP je nach Schwierigkeit
- Story-Lektion: +150 XP
- SRS-Session ohne "Nochmal": +10 XP pro Karte
- XP bestimmt Tamago-Zustand (kein Level-Up-Screen, stille Progression)

---

## 8. Hören und Sprechen

### TTS (flutter_tts)

```dart
// tts_service.dart
class TtsService {
  final FlutterTts _tts = FlutterTts();
  
  Future<void> init() async {
    await _tts.setLanguage("ja-JP");
    await _tts.setSpeechRate(0.8);  // etwas langsamer für Lerner
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }
  
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }
  
  Future<void> speakSlow(String text) async {
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
    await _tts.setSpeechRate(0.8);
  }
}
```

Jede Vokabelkarte hat einen Play-Button. Audio spielt beim Aufdecken der Antwort automatisch (optional, einstellbar).

### STT (speech_to_text)

```dart
// stt_service.dart
class SttService {
  final SpeechToText _stt = SpeechToText();
  
  Future<bool> init() => _stt.initialize();
  
  Future<String> listen() async {
    String result = '';
    await _stt.listen(
      localeId: 'ja_JP',
      onResult: (r) => result = r.recognizedWords,
    );
    await Future.delayed(const Duration(seconds: 3));
    await _stt.stop();
    return result;
  }
}
```

**Sprech-Übung UI:**
1. Japanisches Wort/Satz wird angezeigt
2. Großer Mikrofon-Button (roter Kreis)
3. User spricht
4. Erkannter Text erscheint
5. Vergleich: grün wenn korrekt, orange bei Teilübereinstimmung
6. KI-Feedback bei Sätzen (Haiku API)

**Kein Perfektionismus:** Partial matches akzeptieren. Fehler nicht bestrafen. "Gut genug" = grün.

---

## 9. Vokabular-Daten (800 Wörter)

Datei: `lib/data/vocab_800.dart`

Struktur:

```dart
class VocabEntry {
  final String id;
  final String word;        // Kanji/Kana
  final String reading;     // Hiragana
  final String romaji;
  final String meaningDe;   // Deutsch
  final String meaningEn;   // Englisch (Fallback)
  final String type;        // 動詞/名詞/形容詞/表現/副詞
  final String jlpt;        // N5/N4/N3
  final String example;     // Beispielsatz (Japanisch)
  final String exampleDe;   // Übersetzung
  final int lessonId;       // ab welcher Lektion verfügbar
  final List<String> tags;  // ['food','daily','body',...]
}
```

Kategorien (mit Lektions-Zuordnung):
- Lektion 1-10:  Grundkana-Wörter (いぬ、ねこ、き、みず...)
- Lektion 11-15: Zahlen, Farben, Familie
- Lektion 16-25: Verben des Alltags (N5 Core)
- Lektion 26-35: Adjektive, Beschreibungen
- Lektion 36-50: N4 Vokabeln, Grammatik-Wörter
- Gesamt: ~800 Einträge

Alle 800 Wörter in der Datei als `const List<VocabEntry> vocab800 = [...]`.
Deutsche Bedeutungen haben Priorität. Englisch als Fallback.

---

## 10. Story-System

Story-Lektionen sind kurze Texte (5-8 Sätze) auf Japanisch.
Jede Story ist an den aktuellen Lernstand angepasst — frühe Storys nur Hiragana, spätere mit Kanji und Furigana.

```dart
class StoryLesson {
  final int id;
  final String title;
  final List<StorySentence> sentences;
  final List<String> vocabUsed;     // welche Wörter vorkommen
  final List<StoryQuestion> comprehensionQuestions;
}

class StorySentence {
  final String japanese;
  final String reading;    // für Furigana
  final String german;
  final bool showTranslation;  // erst nach Tippen aufdecken
}
```

Story 1 (Lektion 7) — "おはよう、たまご！"
Tamago-chan wacht auf. Erst Hiragana, sehr einfach.
Sätze: おはようございます。/ あさごはんをたべます。/ etc.

Story 2 (Lektion 14) — "たまごのおかいもの"
Tamago geht einkaufen. Zahlen, Farben, einfache Verben.

Story 3 (Lektion 20) — erste Kanji tauchen auf.

---

## 11. KI-Feedback (Anthropic API)

Nur für `FreeWriteExercise` und speaking-Bewertung bei Sätzen.

```dart
// api_client.dart
class AnthropicClient {
  final String apiKey;
  static const model = 'claude-haiku-4-5-20251001';
  
  Future<String> getFeedback({
    required String userInput,
    required String scenario,
    required String task,
  }) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 500,
        'system': '''Du bist ein geduldiger Japanisch-Tutor. 
Gib kurzes Feedback auf Deutsch:
1. Was war richtig
2. Was kann verbessert werden (mit korrigiertem Japanisch)
3. Ein natürlicher Modellsatz

Sei warm, direkt, kurz. Maximal 5 Sätze gesamt.''',
        'messages': [
          {
            'role': 'user',
            'content': 'Szenario: $scenario\nAufgabe: $task\nMeine Antwort: $userInput'
          }
        ],
      }),
    );
    // parse response...
  }
}
```

API Key wird in `shared_preferences` gespeichert, nie im Code.

---

## 12. Screens

### Home Screen

Layout:
```
[Tamago-chan widget, oben rechts]
[Tagesfortschritt: X Karten fällig]
[Start-Button: "Heute lernen"]
[Lektions-Grid]
[Schnellzugriff: SRS-Review]
```

Lektions-Grid: 2-spaltig, jede Lektion als Karte mit Titel, Kategorie-Icon, Fortschrittsbalken. Abgeschlossene Lektionen haben ein dezentes Häkchen. Gesperrte sind ausgegraut.

### Lesson Screen

Oben: Fortschrittsbalken (wieviele Übungen noch)
Mitte: aktuelle Übung (wechselt dynamisch)
Unten: Antwort-Input oder Grade-Buttons

Lektionsabschluss: eigener Screen mit Tamago-Animation, XP-Zusammenfassung, "Weiter"-Button.

### Review Screen

SRS-Wiederholung. Alle fälligen Karten. Kein Zeitdruck.
Nach Session: Statistik (richtig/falsch, Genauigkeit).

### Progress Screen

- Lernkurve (Karten gelernt pro Tag, 30-Tage-Chart)
- Tamago-Zustand mit XP bis nächster Stufe
- Kana-Tabelle mit Fortschritt eingefärbt
- Gesprochene Stunden (geschätzt)

---

## 13. Navigation (go_router)

```
/                   → HomeScreen
/lesson/:id         → LessonScreen
/lesson/:id/done    → LessonCompleteScreen
/review             → ReviewScreen
/progress           → ProgressScreen
/settings           → SettingsScreen
```

---

## 14. Wichtige Implementierungs-Hinweise

**Furigana-Widget:**
Ruby-Text in Flutter ist nicht nativ. Implementierung über Stack oder RichText mit custom spans.
Furigana toggle: global in Settings. Anfänger: ON. Fortgeschrittene: OFF.

**TTS auf iOS:**
`flutter_tts` auf iOS benötigt `com.apple.developer.speech-recognition` entitlement.
Info.plist: `NSSpeechRecognitionUsageDescription` und `NSMicrophoneUsageDescription` setzen.

**Offline-first:**
Alle Lektionsdaten, Vokabeln, Kana sind lokal (kein Netzwerk nötig).
Nur KI-Feedback und (optional) TTS benötigen Netz.
TTS hat Offline-Fallback: `flutter_tts` nutzt System-TTS, die offline funktioniert.

**Keine Werbung, kein Tracking.**
BYOK (Bring Your Own Key) für API. Key liegt lokal.

**Datenbankmigrationen:**
Drift-Migrationen sauber versionieren. Startend bei schemaVersion 1.

**Lektions-Unlock-Logik:**
Lektion N+1 wird freigeschaltet wenn Lektion N mit >= 70% Genauigkeit abgeschlossen.
Story-Lektionen immer erreichbar sobald Vorgänger fertig.

---

## 15. Was NICHT gebaut wird (bewusste Entscheidungen)

- Kein Streak-Counter (zu viel Druck)
- Keine Herzen / Leben
- Kein Social/Leaderboard
- Kein Abo-Modell (BYOK ist genug)
- Kein Multiple Choice (aktive Produktion ist besser)
- Kein Roman-Schreib-System (Handschrift-Erkennung ist zu fehleranfällig)
- Keine Romaji-Option für Vokabeln (schadet dem Lernen langfristig)

---

## 16. Erste Schritte für Claude Code

1. `flutter create nihongo_app --org com.softbrew --platforms ios,android`
2. `pubspec.yaml` mit allen Dependencies aus §2 befüllen
3. `lib/core/theme.dart` aus §6 anlegen
4. `lib/core/srs.dart` SM-2 Algorithmus implementieren
5. `lib/data/kana_data.dart` — Hiragana + Katakana Tabellen
6. `lib/data/vocab_800.dart` — erste 50 Wörter, Rest kann ergänzt werden
7. Drift Database Schema aus §5 aufsetzen
8. HomeScreen Grundstruktur
9. Erste Lektion end-to-end durchspielbar machen
10. TTS integrieren

**Priorität:** Erst Lektion 01-05 vollständig spielbar, dann iterieren.

---

## 17. Dateibenennung & Konventionen

- Dart: snake_case für Dateien, UpperCamelCase für Klassen
- Keine statischen Strings in Widgets — alles in `lib/data/` oder als Konstante
- Riverpod: StateNotifier für komplexen State, Provider für Services
- Alle japanischen Strings als UTF-8 Literale (keine Escape-Sequenzen)
- Kommentare auf Deutsch oder Englisch, nie auf Japanisch

---

## 18. Kanji-Spiele-Modul

### Übersicht

Eigener Tab in der Bottom Navigation: "遊" (Spiele).
Vier Spiele, alle unabhängig voneinander spielbar.
Fortschritt fließt auch in die SRS-Datenbank — ein im Spiel korrekt erkanntes Kanji
erhält einen positiven Grade-2-Eintrag, falls noch nicht bekannt.

```
/games                → GamesHub (Auswahl)
/games/quiz           → KanjiQuiz
/games/blitz          → BlitzRunde
/games/trace          → Nachmalen
/games/memory         → Paare finden
```

---

### 18.1 Kanji-Daten

Datei: `lib/features/kanji_games/kanji_data.dart`

```dart
class KanjiEntry {
  final String kanji;           // z.B. "日"
  final String onyomi;          // Chinesische Lesung: "ニチ、ジツ"
  final String kunyomi;         // Japanische Lesung: "ひ、か"
  final String meaningDe;       // "Sonne, Tag"
  final String meaningEn;       // "sun, day"
  final int strokeCount;        // Anzahl Striche
  final String jlpt;            // "N5"
  final String svgAssetPath;    // "assets/kanji_svg/65e5.svg"
  final List<String> examples;  // ["日本語", "毎日", "今日"]
  final List<String> exampleReadings;
  final List<String> exampleMeanings;
  final int lessonUnlock;       // ab welcher Lektion im Spiel verfügbar
}

// N5-Kanji (80 Zeichen): 一二三四五六七八九十
//   日月火水木金土山川田
//   人口目耳手足力気心
//   大小中上下左右先生
//   学校本文字子女男
//   電車自動車道来行見
//   食飲書読聞話語
// N4-Kanji (weitere ~170): nach Lektionsfortschritt freigeschaltet

const List<KanjiEntry> kanjiN5 = [ ... ]; // alle 80 N5-Kanji
const List<KanjiEntry> kanjiN4 = [ ... ]; // N4-Kanji
```

**SVG-Strichfolge-Dateien:**
KanjiVG ist ein Open-Source-Projekt mit SVG-Strichfolge-Daten für alle Kanji.
Download von: https://kanjivg.tagaini.net (Lizenz: CC BY-SA 3.0)
SVGs kommen in `assets/kanji_svg/` — Dateiname = Unicode-Codepoint (z.B. `65e5.svg` für 日).
`pubspec.yaml`: `assets/kanji_svg/` als Asset-Verzeichnis eintragen.

---

### 18.2 Games Hub Screen

```
┌─────────────────────────────────┐
│  遊  Kanji-Spiele               │
│                                 │
│  ┌─────────┐   ┌─────────┐     │
│  │   Quiz  │   │  Blitz  │     │
│  │   日?   │   │  ⏱ 60s  │     │
│  │ N5 · 12 │   │ Rekord  │     │
│  │  richtig│   │  23/30  │     │
│  └─────────┘   └─────────┘     │
│                                 │
│  ┌─────────┐   ┌─────────┐     │
│  │ Schrei- │   │ Paare   │     │
│  │  ben    │   │ finden  │     │
│  │  日 ✏   │   │  🀄🀄   │     │
│  │  N5 Set │   │  4x4   │     │
│  └─────────┘   └─────────┘     │
└─────────────────────────────────┘
```

Jede Karte zeigt: Spielname, Icon, letztes Ergebnis / Rekord.
Vor jedem Spiel: kleines Setup-Sheet (welches Set, N5/N4/gemischt, Anzahl).

---

### 18.3 Kanji Quiz

**Modus:** Kanji sehen → Bedeutung wählen oder tippen.
Zwei Varianten wählbar:
- **Tippen** (besser fürs Lernen): leeres Textfeld, freie Eingabe
- **Auswahl** (lockerer): 4 Optionen, eine korrekt

```dart
class QuizSession {
  final List<KanjiEntry> deck;    // 10-20 Kanji
  int currentIndex = 0;
  int correct = 0;
  int wrong = 0;
  final List<QuizResult> results;
}

class QuizResult {
  final KanjiEntry kanji;
  final String userAnswer;
  final bool wasCorrect;
  final Duration responseTime;
}
```

**UI-Flow:**
1. Kanji groß anzeigen (Noto Serif JP, 96px)
2. Darunter: On'yomi und Kun'yomi (aufklappbar, als Hint)
3. Eingabefeld oder 4 Buttons
4. Nach Antwort: sofort Feedback (grün/rot), korrekte Antwort, Beispielwort
5. TTS spielt Kanji-Lesung ab
6. "Weiter" oder automatisch nach 1.5s

**Ergebnis-Screen:**
- Richtig/Falsch Übersicht
- Alle falsch beantworteten Kanji mit korrekter Antwort
- "Diese in SRS aufnehmen"-Button
- Highscore (lokal gespeichert)

---

### 18.4 Blitz-Runde

**Ziel:** So viele Kanji wie möglich in 60 Sekunden korrekt benennen.
Schnell, spannend, keine Lernkurve nötig — reines Retrieval-Training.

```dart
class BlitzState {
  final int timeLeft;           // Sekunden, zählt runter
  final KanjiEntry current;     // aktuelles Kanji
  final int streak;             // aktuelle Richtig-Serie
  final int bestStreak;
  final int score;
  bool isRunning;
}
```

**UI:**
```
┌─────────────────────────────────┐
│  ⏱ 45s          Serie: 7 🔥    │
│                                 │
│           木                    │
│        (80px, mittig)           │
│                                 │
│  [ Baum / Holz     ] [→]       │
│                                 │
│  ✓ ✓ ✓ ✗ ✓ ✓ ✓ ...  (History) │
└─────────────────────────────────┘
```

- Eingabefeld autofokus
- Enter = prüfen + nächstes Kanji
- Falsch: kurzes Rot-Flash, korrekte Antwort 0.8s einblenden, weiter
- Streak: ab 5 richtig hintereinander zeigt Tamago-chan kurz auf
- Partial Match (z.B. "Baum" statt "Baum, Holz") zählt als richtig

**Highscore-Tabelle:** lokal, die letzten 10 Runs mit Datum und Score.

---

### 18.5 Nachmalen (Stroke Tracing)

**Ziel:** Kanji mit dem Finger korrekt nachschreiben. Strichfolge lernen.

**Technische Umsetzung:**

```dart
// stroke_painter.dart
class StrokePainter extends CustomPainter {
  final List<List<Offset>> referenceStrokes;  // aus SVG geparst
  final List<List<Offset>> userStrokes;       // gezeichnet via GestureDetector
  final int completedStrokes;                 // wie viele Striche fertig
  final bool showGuide;                       // Vorlage einblenden

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Referenz-Kanji als helles Grau zeichnen (wenn showGuide)
    // 2. Abgeschlossene User-Striche in Ink-Farbe
    // 3. Aktuellen Strich in Echtzeit zeichnen
    // 4. Nächsten erwarteten Strich animiert hervorheben (Pfeil)
  }
}
```

```dart
// stroke_validator.dart
class StrokeValidator {
  // Vergleicht User-Strich mit Referenz-Strich
  // Toleranz: ~25% Abweichung erlaubt
  // Methode: Frechet-Distanz (vereinfacht) oder DTW
  static double similarity(List<Offset> user, List<Offset> reference);
  static bool isAcceptable(List<Offset> user, List<Offset> ref) =>
    similarity(user, ref) > 0.72;
}
```

**SVG-Parser für KanjiVG:**
KanjiVG-SVGs haben `<path>` Elemente mit `kvg:element` Attribut.
Pfade in Liste von Offset-Listen umwandeln (Bezier-Kurven diskretisieren).

```dart
// kanji_svg_loader.dart
class KanjiSvgLoader {
  static Future<List<List<Offset>>> loadStrokes(String assetPath) async {
    final svgString = await rootBundle.loadString(assetPath);
    // XML parsen, path d-Attribute extrahieren
    // Bezier-Punkte samplen (alle 5px ein Punkt)
    // Skalieren auf Canvas-Größe (typisch 300x300)
  }
}
```

**UI-Flow:**

1. Kanji + Bedeutung anzeigen, dazu: Strichanzahl, Lesung
2. "Anleitung"-Button: animiert alle Striche der Reihe nach (TTS spricht Kanji)
3. Canvas (300x300, weißer Hintergrund, leichte Gitter-Linien wie Kalligrafie-Papier)
4. User zeichnet Strich für Strich
5. Nach jedem Strich: sofortiges Feedback (grün = gut, rot = nochmal)
   - Zu kurz/lang: Hinweis "Strich zu kurz"
   - Falsche Richtung: Hinweis "Von links nach rechts"
6. Nach allen Strichen: Bewertung (1-3 Pinsel 🖌)
7. Nächstes Kanji oder Wiederholen

**Schwierigkeitsstufen:**
- Einfach: Vorlage durchgehend sichtbar (Nachzeichnen)
- Mittel: Vorlage verblasst nach 2s
- Schwer: Keine Vorlage, nur nächster Strich angedeutet

---

### 18.6 Paare finden (Memory)

**Modus:** Konzentrationsspiel. Kanji-Karten und Bedeutungs-Karten aufdecken,
Paare finden. Trainiert visuelle Erkennung ohne Tippen.

```dart
class MemorySession {
  final int gridSize;           // 3x4 (12 Karten = 6 Paare) oder 4x4 (16 = 8 Paare)
  final List<MemoryCard> cards;
  int? firstFlipped;
  int? secondFlipped;
  int moves;
  int matchesFound;
  DateTime startTime;
}

class MemoryCard {
  final String id;              // Paare haben gleiche id
  final MemoryCardType type;    // kanji | meaning | reading
  final String content;
  bool isFlipped;
  bool isMatched;
}
```

**Karten-Paare-Varianten** (im Setup wählbar):
- Kanji ↔ Deutsche Bedeutung (Anfänger)
- Kanji ↔ Hiragana-Lesung (Fortgeschritten)
- Kanji ↔ Beispielwort (Expert)

**UI:**
- Grid aus Karten (Rückseite: dezentes Muster, Vorderseite: Kanji oder Text)
- Flip-Animation: 3D-Karten-Flip (Transform.rotateY)
- Match: beide Karten kurz grün pulsieren, dann verblassen (sichtbar aber inaktiv)
- Falsch: beide kurz rot, dann zurückklappen (0.6s)
- TTS: beim Aufdecken spielt Kanji-Lesung ab (optional)

**Ergebnis:**
- Zeit, Züge, Fehler
- Bestzeit lokal gespeichert
- "Diese Kanji üben"-Button → öffnet Quiz mit den heutigen Karten

---

### 18.7 Fortschritts-Integration

Alle Spiele schreiben in dieselbe SRS-Datenbank:

```dart
// Nach jedem Kanji-Spiel:
Future<void> recordGameResult(KanjiEntry kanji, bool correct) async {
  final existing = await db.getSrsCard('kanji_${kanji.kanji}');
  if (existing == null) {
    // Neue Karte anlegen
    await db.insertSrsCard(SrsCard(
      cardId: 'kanji_${kanji.kanji}',
      front: kanji.kanji,
      back: kanji.meaningDe,
      cardType: 'kanji',
      dueAt: 0,  // sofort fällig für nächste Review
    ));
  } else {
    // Bestehende Karte graden
    final grade = correct ? 2 : 0;
    await db.updateSrsCard(srsGrade(existing, grade));
  }
}
```

Auf dem Progress-Screen: eigener Abschnitt "Kanji gelernt" mit Übersicht welche
Kanji wie oft richtig/falsch waren, heatmap-artige Darstellung.

---

### 18.8 Tamago-chan in den Spielen

- Beim Start jedes Spiels: kurze Tamago-Animation (wippt aufgeregt, 0.5s)
- Nach Blitz-Highscore: Tamago springt
- Nach 10 korrekt nachgemalten Kanji: Tamago zeigt Daumen hoch
- Nach Memory unter Bestzeit: Tamago dreht sich
- Keine Pop-ups, keine Unterbrechungen während des Spiels

---

### 18.9 Navigation-Ergänzung

Bottom Navigation erhält fünften Tab:

```
首 Home | 仮 Kana | 復 Review | 遊 Spiele | 設 Settings
```

Oder bei 5 Tabs: Icons ohne Beschriftung verwenden um Platz zu sparen.

---

### 18.10 Erste Implementierungs-Schritte für Kanji-Modul

1. `kanji_data.dart` — N5-Kanji (80 Einträge) vollständig befüllen
2. `GamesHub`-Screen mit 4 Karten-Widgets (noch nicht navigierbar)
3. `KanjiQuiz` — Tippen-Modus, 10 Karten, Ergebnis-Screen
4. `BlitzScreen` — Timer + Eingabe, lokaler Highscore
5. KanjiVG SVG-Dateien für N5 als Assets einbinden
6. `StrokePainter` — Vorlage zeichnen, User-Input aufnehmen
7. `StrokeValidator` — einfache Ähnlichkeits-Prüfung
8. `MemoryScreen` — 3x4 Grid, Flip-Animationen
9. SRS-Integration für alle vier Spiele
10. Tamago-Reaktionen einbauen

---

## 19. Echte Gespräche & Konversationsmodus (Level 3+)

### Konzept

Ab einem bestimmten Fortschritt (ca. Lektion 25+, ~300 Karten gelernt) schaltet
sich ein neuer Bereich frei: **「会話」Kaiwa — Gespräche**.

Zwei Säulen:
1. **Echte Gesprächsfetzen** — authentische kurze Audio-Szenen, die man
   versteht, analysiert und nachahmt (Shadowing)
2. **KI-Konversation** — freies Gespräch mit Claude als Gesprächspartner,
   der sich ans Level anpasst und korrigiert

Beides zusammen ist effektiver als jede Grammatikübung: man hört wie echtes
Japanisch klingt, und produziert selbst Sprache in echtem Kontext.

---

### 19.1 Echte Gesprächsfetzen (Shadowing-Modus)

**Was sind das für Clips?**

Kurze Alltagsgespräche, 15–45 Sekunden. Entweder:
- Eigens aufgenommene Clips (zwei Sprecher, professionell, CC-Lizenz) — ideal
- Oder: Hochwertige TTS mit zwei verschiedenen Stimmen (Mann/Frau, schnell/normal)
  via `flutter_tts` oder Google Cloud TTS (bessere Qualität, kostet wenig)
- Oder: JapanesePod101, NHK World, Tatoeba haben freie Audiodateien

Für den MVP: TTS mit zwei Stimmen reicht. Später echte Aufnahmen austauschen.

**Klipdaten-Struktur:**

```dart
class ConversationClip {
  final String id;
  final String titleDe;               // "An der Kasse"
  final String scenario;              // Kurzbeschreibung
  final int minLevel;                 // Lektion ab der verfügbar
  final ClipDifficulty difficulty;    // beginner / intermediate / advanced
  final List<ClipLine> lines;         // Zeile für Zeile
  final List<String> keyVocab;        // Neue Wörter im Clip
  final List<String> grammarPoints;   // z.B. ["て-Form", "〜ましょうか"]
}

class ClipLine {
  final String speaker;       // "A" | "B" (oder Name)
  final String japanese;      // authentischer Text
  final String reading;       // Furigana-Version
  final String germanTrans;   // Übersetzung
  final String audioAsset;    // Pfad oder TTS-Input
  final double speed;         // 1.0 = normal, 0.75 = langsam
}
```

**Beispiel-Clips nach Level:**

```
Level 25–30 (Beginner Clips):
  - コンビニで (Im Convenience Store)
  - 駅で道を聞く (Nach dem Weg fragen)
  - 自己紹介 (Sich vorstellen)
  - レストランで注文する (Im Restaurant bestellen)
  - 天気の話 (Über das Wetter reden)

Level 31–40 (Intermediate Clips):
  - 電話で予約する (Reservierung per Telefon)
  - 職場での会話 (Small Talk im Büro)
  - 買い物で値段を聞く (Preis erfragen)
  - 友達と約束する (Verabredung treffen)
  - 病院の受付 (Arztanmeldung)

Level 41–50 (Advanced Clips):
  - 早口の自然会話 (Schnelle natürliche Unterhaltung)
  - 方言混じり (Mit Dialekt-Einflüssen)
  - ビジネス会話 (Formelle Geschäftssprache)
  - 居酒屋トーク (Lockerer Abend-Small-Talk)
  - 感情のある会話 (Gespräch mit Emotion, Überraschung, Ärger)
```

**UI-Flow für einen Clip:**

```
1. Einstieg:
   ┌───────────────────────────────┐
   │ コンビニで                    │
   │ "Im Convenience Store"        │
   │ Schwierigkeit: ●●○○           │
   │ Dauer: 32s · 3 neue Wörter    │
   │                               │
   │  [▶ Zuhören]  [Vokabeln]      │
   └───────────────────────────────┘

2. Zuhören (Blindhören):
   - Audio spielt komplett ab, kein Text sichtbar
   - Danach: "Was hast du verstanden?" (freies Textfeld, optional)

3. Verstehen (Zeile für Zeile):
   - Jede Zeile einzeln — erst Japanisch, Tipp auf Übersetzung
   - Play-Button pro Zeile (auch langsam)
   - Furigana toggle

4. Shadowing:
   - Zeile spielt ab → User spricht nach (STT aufnehmen)
   - Vergleich: erkannter Text vs. Original
   - Geschwindigkeit einstellbar: 0.75x / 1.0x / 1.25x

5. Quiz über den Clip:
   - 3 Verständnisfragen (Multiple Choice oder Tippen)
   - z.B. "Was hat Person A bestellt?" / "Wie viel hat es gekostet?"

6. Abschluss:
   - Gelernte Vokabeln in SRS aufnehmen
   - XP je nach Performance
```

---

### 19.2 KI-Konversation (freies Gespräch mit Claude)

**Konzept:**
Claude spielt eine Rolle (Ladenbesitzer, Freund, Kollege) und führt ein echtes
Gespräch auf Japanisch. Der User antwortet per Tippen oder Sprache.
Claude passt Komplexität ans Level an, korrigiert dezent, bleibt im Gespräch.

Kein starres Skript. Echte, unvorhersehbare Antworten — wie ein Gespräch
mit einem Muttersprachler, der Geduld hat.

**Gesprächs-Szenarien:**

```dart
class ConversationScenario {
  final String id;
  final String titleDe;
  final String titleJp;
  final String systemPrompt;        // Claude-Instruktion (englisch)
  final String openingLine;         // Claudes erster Satz auf Japanisch
  final int minLevel;
  final ConversationStyle style;    // casual | polite | business
  final List<String> suggestedPhrases;  // Starter-Hilfen für den User
}
```

```
Szenarien nach Level:

Level 25: 
  友達との会話 — "Du triffst einen Austauschstudenten"
  コンビニの店員 — "Der Kassierer macht Small Talk"

Level 30:
  居酒屋 — "Abend in einer Izakaya mit Kollegen"
  道案内 — "Du bittest jemanden um den Weg, der redet schnell"

Level 35:
  面接 — "Kurzes Vorstellungsgespräch (informell)"
  日本語の先生 — "Dein Japanischlehrer fragt dich aus"

Level 40+:
  電話 — "Nur Audio, kein Text — Telefongespräch simulieren"
  議論 — "Meinungsverschiedenheit über ein alltägliches Thema"
  ニュース — "Diskussion über eine einfache Nachricht"
```

**System-Prompt-Vorlage:**

```dart
String buildSystemPrompt(ConversationScenario scenario, int userLevel) {
  return """
You are roleplaying as: ${scenario.titleDe}
Scenario: ${scenario.id}

CRITICAL RULES:
- Speak ONLY in Japanese. Never switch to German or English.
- Match complexity to level $userLevel/50:
  * Level <30: Short sentences, N5/N4 grammar only, speak slowly
  * Level 30-40: Natural pace, N4/N3 grammar, occasional slang
  * Level 40+: Full natural speed, idioms, regional expressions ok
- Stay in character. React naturally to what the user says.
- If the user makes a grammar mistake, continue the conversation
  naturally but use the correct form once in your next reply
  (implicit correction, not explicit).
- If the user is clearly stuck, offer ONE simple hint in brackets
  like [ヒント: 〜をください？] — but only if they seem lost.
- Keep responses SHORT: 1-3 sentences max. This is conversation,
  not a lecture.
- React with emotion: surprise, laughter, confusion — make it real.

Opening line: ${scenario.openingLine}
""";
}
```

**UI-Flow:**

```
┌─────────────────────────────────────┐
│  居酒屋 — Izakaya-Abend              │
│  ────────────────────────────────   │
│                                     │
│  [Claude/Tanaka-san]:               │
│  いらっしゃいませ！今日は何名       │
│  様ですか？                          │
│  ──────────────────────────────     │
│                                     │
│  [Du]:                              │
│  二人です。                          │
│                                     │
│  [Claude/Tanaka-san]:               │
│  かしこまりました。こちらへどうぞ。  │
│  お飲み物は何にしますか？            │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 日本語で答えてください…    │   │
│  └─────────────────────────────┘   │
│  [🎤 Sprechen]  [💡 Hilfe]  [送信] │
│                                     │
│  [Beenden]  [Feedback anzeigen]     │
└─────────────────────────────────────┘
```

**Konversations-Nachbesprechung:**

Nach dem Gespräch (User tippt "Ende" oder nach 10 Minuten):

```dart
String buildReviewPrompt(List<ConversationMessage> history) {
  return """
Review this Japanese conversation between a learner (level X) and you.
Give feedback in German, concisely:

1. Was lief gut? (2-3 Punkte)
2. Grammatikfehler die auffielen (max 3, mit Korrektur)
3. Einen natürlicheren Alternativsatz für den schwächsten Moment
4. Wörter/Ausdrücke die nützlich wären zu lernen

Keep it under 150 words. Warm, direct tone.

Conversation:
${history.map((m) => "${m.role}: ${m.content}").join('\n')}
""";
}
```

Ergebnis: strukturiertes Feedback-Panel, Fehler können direkt in SRS
aufgenommen werden.

---

### 19.3 Telefon-Modus (Level 40+)

Besondere Variante der KI-Konversation: **kein Text sichtbar**.
Nur Audio rein und raus — wie ein echtes Telefongespräch.

- Claude "spricht" via TTS (kein Text angezeigt)
- User antwortet per STT
- Kein Furigana, kein Nachschauen
- Sehr schwer, sehr effektiv

UI: schwarzer Screen, großes Telefon-Icon, Wellenform-Visualisierung.
"Auflegen"-Button zum Beenden.

Aktivierbar erst ab Level 40. Kann nicht übersprungen werden.

---

### 19.4 Pitch Accent (optional, Level 35+)

Japanisch hat Tonhöhenakzent — oft ignoriert, hörbar wichtig.
Keine Pflicht, aber als optionales Feature:

- Bei jedem Vokabel-Clip: Pitch-Akzent-Diagramm einblendbar
- Beim Shadowing: Vergleich von Tonhöhe (vereinfacht, via Analyse der STT-Ausgabe)
- Erklärung: "Tokyo-Dialekt hat folgende Muster..."

```dart
class PitchPattern {
  final String word;
  final List<bool> highLow;   // true = hoch, false = tief, pro Mora
  // 食べる: [L, H, H] — "ta-BE-ru"
}
```

Wird in `VocabEntry` als optionales Feld ergänzt.

---

### 19.5 Level-Gate und Freischaltung

```dart
bool isKaiwaUnlocked(UserProgress progress) =>
  progress.completedLessons >= 25 &&
  progress.totalCardsLearned >= 250;

bool isPhoneUnlocked(UserProgress progress) =>
  progress.completedLessons >= 40 &&
  progress.conversationSessions >= 10;
```

Auf dem Home-Screen: Kaiwa-Tab ist sichtbar aber ausgegraut mit
"Freigeschaltet bei Lektion 25" — kein Geheimnis, Motivation statt Sperre.

---

### 19.6 Technische Umsetzung KI-Konversation

```dart
// Streaming-Response für natürlicheres Tippen-Erscheinen
Future<Stream<String>> streamConversation({
  required List<ConversationMessage> history,
  required ConversationScenario scenario,
  required String userMessage,
  required int userLevel,
}) async {
  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
      'anthropic-beta': 'prompt-caching-2024-07-31',  // System Prompt cachen
    },
    body: jsonEncode({
      'model': 'claude-haiku-4-5-20251001',  // Haiku: schnell, guenstig
      'max_tokens': 200,                      // Kurze Antworten erzwingen
      'stream': true,
      'system': buildSystemPrompt(scenario, userLevel),
      'messages': [
        ...history.map((m) => {'role': m.role, 'content': m.content}),
        {'role': 'user', 'content': userMessage},
      ],
    }),
  );
  // SSE-Stream parsen, Text-Chunks zurückgeben
}
```

Streaming wichtig: Antwort erscheint Wort für Wort wie beim echten Tippen —
fühlt sich lebendiger an. Nach vollständiger Antwort: TTS spielt sofort ab.

**Kosten-Abschätzung (Haiku):**
- Pro Konversations-Nachricht: ~$0.0003
- Eine 10-minütige Konversation (20 Nachrichten): ~$0.006
- Für den User komplett transparent da BYOK

---

### 19.7 Navigation-Ergänzung

```
首 Home | 仮 Kana | 復 Review | 会 Gespräch | 遊 Spiele | 設 Settings
```

Bei 6 Tabs nur Icons verwenden (kein Label), oder "Gespräch" und "Spiele"
unter einem "Mehr"-Tab zusammenfassen bis Lektion 25 erreicht ist.

---

## 20. Mehrsprachigkeit — Vollständiges Lernsystem für alle Sprachen

### 20.1 Grundprinzip

Die App ist eine **Sprachlern-Plattform**, nicht eine Japan-App.
Japanisch ist die erste und tiefste Implementierung — aber das System ist
von Anfang an so gebaut, dass jede weitere Sprache denselben vollen Lernpfad
bekommt: Vokabeln, Lektionen, Grammatik, Hören, Sprechen, KI-Konversation,
Spiele, Shadowing-Clips.

**Script-Block:** Wenn eine Sprache kein eigenes Schriftsystem hat (Spanisch,
Französisch, Türkisch...), wird der Kana/Script-Tab einfach nicht gerendert.
`hasScript: false` → Tab existiert nicht. Kein Sondercode, keine leere Seite.

---

### 20.2 Was ist wiederverwendbar?

```
VOLLSTÄNDIG WIEDERVERWENDBAR:
  ✓ SRS-Algorithmus + Drift-Datenbank
  ✓ Lektionssystem (Unlock-Logik, Kategorien, XP)
  ✓ Alle Übungstypen: meaning, listen, speak, sentence_build, free_write
  ✓ KI-Konversation (System-Prompt parametrisch)
  ✓ Shadowing-Clips (andere Audio-Inhalte, gleiche Engine)
  ✓ Story-Lektionen (anderer Text, gleiche Engine)
  ✓ Quiz, Blitz, Memory — Spiele ohne Script
  ✓ TTS (flutter_tts ~30 Sprachen), STT (~20 Sprachen)
  ✓ Fortschritt, XP, Tamago-chan
  ✓ Travel-Quicklearn

OPTIONAL — nur wenn hasScript: true:
  ~ Script-Lerntab (Hiragana, Hangul, Devanagari...)
  ~ Furigana-äquivalentes Widget
  ~ Script-Quiz in den Spielen
  ~ Nachmalen (nur wenn hasStrokeOrder: true)

JAPAN-EXKLUSIV (nicht portierbar):
  ✗ KanjiVG Stroke-Order-Daten
  ✗ Pitch-Accent-System
```

---

### 20.3 LanguageModule Interface

```dart
// lib/core/language_module.dart

abstract class LanguageModule {
  // Identität
  String get code;              // "ja", "es", "ko", "fr", "tr", "hi"...
  String get nameDE;            // "Japanisch", "Spanisch"...
  String get nameNative;        // "日本語", "Español", "한국어"...
  String get flagEmoji;
  String get ttsLocale;         // "ja-JP", "es-ES", "ko-KR"...
  String get sttLocale;
  bool get isRtl;               // Arabisch, Hebräisch, Persisch

  // Feature-Flags — false = Block/Tab wird nicht gerendert
  bool get hasScript;           // eigenes Schriftsystem?
  bool get hasStrokeOrder;      // Strichfolge-Training?
  bool get hasToneSystem;       // Töne relevant? (Mandarin, Vietnamesisch)
  bool get hasRomanization;     // Romanisierung nötig?
  bool get hasGender;           // Genus (Spanisch, Französisch, Deutsch)
  bool get hasConjugation;      // Verb-Konjugation als Übungstyp?

  // Lerninhalte
  List<VocabEntry> get vocab;           // 800+ Einträge
  List<Lesson> get curriculum;
  List<GrammarTip> get grammarTips;
  List<ConversationScenario> get convScenarios;
  List<ConversationClip> get audioClips;
  List<ScriptGroup>? get scriptGroups;  // null wenn hasScript: false

  // KI-Kontext
  String get aiSystemLanguage;    // "Deutsch"
  String get targetLanguageName;  // "Japanisch", "Spanisch"...
}
```

---

### 20.4 Navigation passt sich dynamisch an

```dart
List<NavItem> buildNav(LanguageModule lang) => [
  NavItem(key: "home",    icon: Icons.home_outlined),
  if (lang.hasScript)
    NavItem(key: "script", icon: Icons.auto_stories),
  NavItem(key: "review",  icon: Icons.refresh),
  NavItem(key: "convo",   icon: Icons.chat_bubble_outline),
  NavItem(key: "games",   icon: Icons.games_outlined),
  NavItem(key: "travel",  icon: Icons.flight_outlined),
];
```

Spanisch: 5 Tabs (kein Schrift-Tab).
Japanisch: 6 Tabs.
Arabisch: 6 Tabs + RTL-Layout via `Directionality`.

---

### 20.5 Vollständige Sprach-Module

**Koreanisch 🇰🇷**
```
hasScript: true       Hangul — 40 Grundzeichen, in 1 Woche lernbar
hasStrokeOrder: false
hasToneSystem: false
hasGender: false

Script-Block: Vokal + Konsonant Kombinationstabelle (wie Kana)
Besonderheit: Grammatik fast identisch zu Japanisch (SOV, Partikel) —
              viele Grammatik-Erklärungen direkt wiederverwendbar
Vokabular: TOPIK 1+2 Basis (~800 Wörter)
Aufwand: ~6 Wochen
```

**Mandarin 🇨🇳**
```
hasScript: true        Hanzi (Vereinfacht)
hasStrokeOrder: true   KanjiVG hat Hanzi-Subset
hasToneSystem: true    4 Töne + neutral — eigene Übungstypen nötig
hasRomanization: true  Pinyin

Script-Block: Pinyin zuerst (wie Kana), dann Hanzi parallel einführen
Ton-Übung: Ton hören → richtigen von 4 wählen; TTS spricht alle 4 ab
Vokabular: HSK 1+2 (600 Wörter)
Aufwand: ~10 Wochen
```

**Spanisch 🇪🇸**
```
hasScript: false   lateinisches Alphabet
hasToneSystem: false
hasGender: true    maskulin/feminin
hasConjugation: true

Kein Script-Tab. Direkt: Vokabeln → Grammatik → Gespräch.
Zusatz-Übungstypen: gender_assign, verb_conjugate (siehe 20.6)
Regional-Variante wählbar: Kastilisch / Lateinamerikanisch
Vokabular: A1/A2 nach CEFR (~800 Wörter)
Aufwand: ~4 Wochen
```

**Französisch 🇫🇷**
```
hasScript: false
hasGender: true
hasConjugation: true

Besonderheit: Liaison und Nasalvokale → Aussprache-Fokus im Shadowing
              Viele unregelmäßige Verben — eigene Kartenkategorie
Aufwand: ~4 Wochen (nach Spanisch: viel Code-Reuse)
```

**Italienisch 🇮🇹**
```
hasScript: false
hasGender: true
hasConjugation: true
Aufwand: ~3 Wochen (nach Spanisch/Französisch)
```

**Türkisch 🇹🇷**
```
hasScript: false   lateinisch + ş ğ ı ö ü ç
hasGender: false   kein Genus
hasConjugation: true

Besonderheit: Vokalharmonie — eigene Grammatik-Erklärungen
              Agglutinativ — Wörter werden sehr lang, Karten entsprechend
Aufwand: ~5 Wochen
```

**Arabisch 🇸🇦**
```
hasScript: true    28 Buchstaben, Anfangs-/Mittel-/Endform
isRtl: true        Flutter Directionality.rtl nötig
hasRomanization: true

Script-Block: Buchstaben-Tabelle mit allen 3 Formen
RTL: alle Layout-Widgets mit Directionality wrappen, testen
Vokabular: MSA (Modernes Hocharabisch) als Basis
Aufwand: ~14 Wochen (RTL + Script komplex)
```

**Hindi 🇮🇳**
```
hasScript: true    Devanagari, 46 Grundzeichen
hasStrokeOrder: false
hasRomanization: true  (vereinfachte IAST)

Script-Block: Devanagari-Tabelle (ähnlich Kana-Struktur)
Aufwand: ~8 Wochen
```

---

### 20.6 Zusatz-Übungstypen für romanische Sprachen

```dart
// Nur für Sprachen mit hasConjugation: true
// "sprechen" → Präsens ich-Form → "hablo"
class VerbConjugateExercise extends Exercise {
  final VocabEntry verb;
  final ConjugationTense tense;     // Präsens, Imperfekt, Futur...
  final ConjugationPerson person;   // ich / du / er / wir / ihr / sie
  final String correctForm;
}

// Nur für Sprachen mit hasGender: true
// "der/die/das Tisch?" → "der"
class GenderExercise extends Exercise {
  final VocabEntry noun;
  final List<String> options;   // ["der","die","das"] oder ["el","la"]
  final String correct;
}
```

`ExerciseFactory` fragt `lang.hasConjugation` und `lang.hasGender` ab
bevor diese Typen in die Übungsreihenfolge aufgenommen werden.

---

### 20.7 VocabEntry — sprachunabhängige Struktur

```dart
class VocabEntry {
  final String id;
  final String word;              // Zielsprache (native Schrift)
  final String? romanization;     // Pinyin, Romaji — null wenn nicht nötig
  final String meaningDE;
  final String? meaningEN;        // Fallback
  final String partOfSpeech;
  final String level;             // "A1"/"A2" oder "N5"/"TOPIK1"/"HSK1"
  final String example;
  final String exampleDE;
  final String? exampleRoman;
  final int lessonId;
  final List<String> tags;

  // Sprach-spezifisch (nullable)
  final String? gender;               // "m"/"f"/"n"
  final String? conjugationGroup;     // "AR"/"ER"/"IR" (Spanisch)
  final String? toneMarked;           // "nǐ hǎo" (Mandarin)
  final List<int>? tonePattern;       // [3,3]
}
```

---

### 20.8 Sprachauswahl beim App-Start

```
┌─────────────────────────────────────┐
│  Welche Sprache lernst du?          │
│                                     │
│  Vollständige Lernpfade:            │
│  🇯🇵 Japanisch    ████████ fertig   │
│  🇰🇷 Koreanisch   ████░░░░ Beta     │
│  🇪🇸 Spanisch     ██░░░░░░ bald     │
│                                     │
│  Mehrere Sprachen parallel lernen   │
│  ist möglich — eigene SRS-Stacks.   │
│                                     │
│  ✈ Reise-Schnellkurs (alle Länder)  │
│  [ Ich reise nach... ]              │
└─────────────────────────────────────┘
```

Jede Sprache hat eigenen SRS-Stack und Fortschritt.
Unteres Nav zeigt aktive Sprach-Flagge.
Sprachwechsel in Settings ohne Datenverlust.

---

### 20.9 Travel Quicklearn — "Ich reise nach..."

Kompakter Notfall-Block für jedes Land der Welt.
50 Phrasen, 8 Kategorien, in 2–3 Stunden abhakbar.
Kein SRS, kein Level nötig, offline verfügbar.

```dart
class TravelPhrase {
  final String target;          // Zielsprache
  final String? romanization;   // immer wenn hasRomanization, sonst null
  final String germanDE;
  final String context;         // "Höfliche Form", "als Frau", "im Laden"
  final bool isEssential;       // Top-10 die man wirklich kennen muss
}
```

**Kategorien:** 🌟 Top 10 · 🙏 Begrüßung · 🍜 Essen · 🚌 Transport ·
🏨 Unterkunft · 🛒 Einkaufen · 🆘 Notfall · 💬 Smalltalk · 🔢 Zahlen

**Generierung:** Claude erzeugt Packs on-demand (~$0.02, Sonnet).
Einmal generiert → lokal gecacht → offline auf dem Flug.
~100 Länder sofort verfügbar ohne Redaktionsaufwand.

---

### 20.10 Roadmap

```
Phase 1 — jetzt:         Japanisch vollständig
Phase 2 — Travel:        KI-Packs für alle Länder (~100), sofort
Phase 3 — Koreanisch:    vollständiger Lernpfad (~6 Wochen)
Phase 4 — Spanisch:      kein Script, schnell (~4 Wochen)
Phase 5 — Fr/It/Pt:      parallel, viel Reuse (~3 Wo. je)
Phase 6 — Mandarin:      Ton-System, Pinyin, Hanzi (~10 Wochen)
Phase 7 — Community:     User können Vokabelpacks beisteuern
```

Travel-Packs (Phase 2) sind unabhängig von den Lernpfaden —
können direkt nach Phase 1 veröffentlicht werden.

---

*Softbrew Studio — nihongo_app — Stand: 2026*

---

## 21. Monetarisierung & In-App Purchases

### 21.1 Strategie

Kein Abo. Einmalige Käufe pro Sprache + Travel Bundle.
BYOK für KI — keine laufenden API-Kosten für den Entwickler.

```
FREE (kein Kauf nötig):
  Japanisch Lektionen 1–15    (Kana komplett + erste Vokabeln)
  Kanji-Spiele: Quiz + Memory (N5-Set)
  Travel Quicklearn: 3 Länder (Japan, Spanien, Frankreich)
  SRS-Review: unbegrenzt für gelernte Karten

JAPANISCH VOLLSTÄNDIG — 6,99 €
  Alle 50+ Lektionen
  KI-Konversation (BYOK)
  Shadowing-Clips
  Kanji-Nachmalen + Blitz-Spiel
  Alle Story-Lektionen

PRO VOLLSPRACHE — 5,99 € je
  Koreanisch, Spanisch, Mandarin, Französisch...
  Gleicher Umfang wie Japanisch

TRAVEL BUNDLE — 2,99 €
  Alle Länder freigeschaltet
  Offline-Generierung unbegrenzt
  (Einzelne Packs: kostenlos, BYOK zahlt ~$0.02 API-Call)

ALLES-BUNDLE — 14,99 €
  Alle aktuellen + zukünftigen Vollsprachen
  Travel Bundle inklusive
```

---

### 21.2 RevenueCat — IAP-Abstraktion

RevenueCat als einzige IAP-Bibliothek für iOS und Android.
Kein doppelter Store-Code, kein manuelles Receipt-Validation.

```
purchases_flutter    — RevenueCat Flutter SDK
```

```dart
// pubspec.yaml ergänzen:
// purchases_flutter: ^6.x.x
```

**Setup:**
1. RevenueCat Dashboard: zwei Apps anlegen (iOS + Android)
2. App Store Connect + Google Play: Produkte anlegen (IDs unten)
3. RevenueCat: Produkte verknüpfen, Entitlements definieren
4. API Keys in app.dart initialisieren

```dart
// lib/core/purchases_service.dart

class PurchasesService {
  static const _rcApiKeyIos     = 'appl_XXXXXXXXXXXXXXXX';
  static const _rcApiKeyAndroid = 'goog_XXXXXXXXXXXXXXXX';

  static Future<void> init() async {
    final apiKey = Platform.isIOS ? _rcApiKeyIos : _rcApiKeyAndroid;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  }

  // Entitlements (definiert in RevenueCat Dashboard)
  static const entitlementJapanese = 'japanese_full';
  static const entitlementTravel   = 'travel_bundle';
  static const entitlementAll      = 'all_languages';
  // Sprach-Entitlements dynamisch: 'lang_ko', 'lang_es', 'lang_zh'...

  static Future<bool> isUnlocked(String entitlement) async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(entitlement);
    } catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  static Future<bool> purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  static Future<void> restorePurchases() async {
    await Purchases.restorePurchases();
  }
}
```

---

### 21.3 Produkt-IDs (Store-Konvention)

```
App Bundle ID: com.softbrew.nihongo

iOS / Android Produkt-IDs:
  com.softbrew.nihongo.japanese_full     — Japanisch vollständig
  com.softbrew.nihongo.travel_bundle     — Travel alle Länder
  com.softbrew.nihongo.all_languages     — Alles-Bundle
  com.softbrew.nihongo.lang_ko           — Koreanisch
  com.softbrew.nihongo.lang_es           — Spanisch
  com.softbrew.nihongo.lang_zh           — Mandarin
  com.softbrew.nihongo.lang_fr           — Französisch
  com.softbrew.nihongo.lang_it           — Italienisch
  com.softbrew.nihongo.lang_tr           — Türkisch
```

---

### 21.4 Paywall-Screen

Kein aggressiver Paywall. Erscheint wenn User auf gesperrte Lektion tippt.
Kurz, klar, kein Dark Pattern.

```
┌──────────────────────────────────────┐
│                                      │
│   Lektion 16 — は vs が              │
│                                      │
│   Teil des vollständigen             │
│   Japanisch-Lernpfads                │
│                                      │
│   ✓ Alle 50 Lektionen               │
│   ✓ KI-Konversation                 │
│   ✓ Shadowing & Stories             │
│   ✓ Kanji-Spiele komplett           │
│                                      │
│   [ Japanisch freischalten  6,99 € ] │
│   [ Alles-Bundle           14,99 € ] │
│                                      │
│   Käufe wiederherstellen             │
└──────────────────────────────────────┘
```

Kein Timer, kein "Nur noch heute!", kein Konfetti.
Preis direkt sichtbar — kein "Starten" Button der zum Preis führt.

---

### 21.5 Feature-Gate im Code

```dart
// lib/core/feature_gate.dart

class FeatureGate {
  static Future<bool> canAccessLesson(Lesson lesson) async {
    if (lesson.id <= 15) return true;  // immer frei
    if (await PurchasesService.isUnlocked(
        PurchasesService.entitlementAll)) return true;
    final langEntitlement = 'lang_${lesson.languageCode}';
    return PurchasesService.isUnlocked(langEntitlement);
  }

  static Future<bool> canUseTravelCountry(String countryCode) async {
    const freeTravelCountries = ['jp', 'es', 'fr'];
    if (freeTravelCountries.contains(countryCode)) return true;
    return PurchasesService.isUnlocked(
        PurchasesService.entitlementTravel);
  }

  static Future<bool> canUseKiConversation() async {
    // KI-Konversation: Entitlement + API Key gesetzt
    final hasEntitlement = await PurchasesService.isUnlocked(
        PurchasesService.entitlementJapanese);
    final hasApiKey = await ApiKeyService.hasKey();
    return hasEntitlement && hasApiKey;
  }
}
```

`FeatureGate` ist der einzige Ort wo Paywall-Logik lebt.
Widgets fragen nur `FeatureGate.canAccess...` — nie direkt RevenueCat.

---

### 21.6 API Key Onboarding

KI-Konversation und KI-Feedback brauchen einen Anthropic API Key vom User.
Einmalige Einrichtung in Settings, einfach erklärt.

```
┌──────────────────────────────────────┐
│  KI-Konversation einrichten          │
│                                      │
│  Die App nutzt deinen eigenen        │
│  Anthropic API Key — du behältst     │
│  die volle Kontrolle über Kosten.    │
│                                      │
│  Kosten: ~0,01 € pro Gespräch        │
│  (Claude Haiku, sehr günstig)        │
│                                      │
│  1. console.anthropic.com öffnen     │
│  2. API Key erstellen                │
│  3. Hier einfügen:                   │
│                                      │
│  [ sk-ant-...              ] [✓]    │
│                                      │
│  Key wird nur lokal gespeichert.     │
│  Nie an Softbrew übertragen.         │
└──────────────────────────────────────┘
```

```dart
// lib/core/api_key_service.dart
class ApiKeyService {
  static const _key = 'anthropic_api_key';

  static Future<void> save(String key) =>
      SharedPreferences.getInstance()
          .then((p) => p.setString(_key, key));

  static Future<String?> get() =>
      SharedPreferences.getInstance()
          .then((p) => p.getString(_key));

  static Future<bool> hasKey() async =>
      (await get())?.isNotEmpty ?? false;

  static Future<void> delete() =>
      SharedPreferences.getInstance()
          .then((p) => p.remove(_key));
}
```

---

### 21.7 Analytics (optional, Privacy-first)

Kein Firebase, kein invasives Tracking.
RevenueCat hat eingebautes Purchase-Analytics — reicht für Conversion-Daten.

Für Nutzungsverhalten optional: PostHog (self-hostbar, DSGVO-konform)
oder gar nichts. Für den MVP: gar nichts außer RevenueCat.

```dart
// Nur wenn Analytics gewünscht:
// posthog_flutter: ^3.x.x
// Einzige Events die Sinn machen:
//   lesson_completed (lesson_id, language, score)
//   purchase_initiated (product_id)
//   api_key_added
// Kein User-Tracking, keine Session-Daten.
```

---

### 21.8 App Store Optimierung (ASO)

```
Name (iOS/Android):
  "Nihongo — Japanisch lernen"
  oder breiter: "Kaiwa — Sprachen lernen"

Keywords:
  japanisch lernen, hiragana, katakana, kanji, jlpt,
  sprachlern app, duolingo alternative, srs karteikarten,
  japanisch sprechen, konversation japanisch

Screenshots-Priorität:
  1. Review-Screen mit Kana-Karte (sofort verständlich)
  2. KI-Konversation (Alleinstellungsmerkmal)
  3. Kanji-Nachmalen (visuell stark)
  4. Lernpfad / Home-Screen
  5. Travel Quicklearn (zweite Zielgruppe)

Promo-Text:
  "Kein Duolingo. Echter Lerneffekt."
  "Aktives Erinnern statt Tippen im Takt."
```

---

*Softbrew Studio — nihongo_app — Stand: 2026*
