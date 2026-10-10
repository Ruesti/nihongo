# Café als Übungsraum — Plan A (Gerüst, Wirtin, Schulmädchen)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nach einer Folge (und beim freien Besuch) führt das Café durch feste Stationen; in Plan A stehen die Wirtin (Wort auflösen, nachsprechen) und das Schulmädchen (Hören→Schreiben auf Kana-Tastatur, Sehen→Sprechen) — die alte Nachbesprechung und der alte Abfrage-Bildschirm verschwinden.

**Architecture:** Ein reiner Planer (`CafeVisitPlanner`) verteilt die Wörter auf Stationen; `CafeVisitScreen` zeigt den Raum mit Stationsleiste und reicht die Items an je einen Stations-Screen weiter, der pro Item ein `CafeOutcome` zurückmeldet. Bausteine als reine Funktionen/Widgets: Zerlegung in Laut-Kacheln, Kana-Tastatur, Blasen-Überlagerung über dem Panel, Abschlusstext. Bewertung geht wie bisher über `LadderReview.submit`.

**Tech Stack:** Flutter/Dart, `flutter_test` (Widget-Tests mit `LearningDb.forTesting()` + `SharedPreferences.setMockInitialValues`), vorhandene Dienste `TtsService`, `SttService`/`SpeakEvaluator`, `kana_data.dart`.

**Spec:** `docs/superpowers/specs/2026-10-08-cafe-uebungsraum-design.md` (§2, §3.1, §3.2, §4, §6, §7, §9; Plan A = §10)

**Basis:** Branch `design/cafe-uebungsraum` (HEAD 594374c, enthält die Spec; sitzt auf `impl/mira-schweigt`, PR #60). Neuer Branch `impl/cafe-uebungsraum-a` davon.

## Global Constraints

- Keine Antwort steht je zur Auswahl; kein „gewusst/nicht" (I1, Spec §3). Keine Zähler, Punkte, Häkchen (I3/INV-10) — auch nicht in der Stationsleiste.
- Alle Oberflächentexte deutsch; kein „Got it".
- Bewertung (Spec §7): Schulmädchen 1. Versuch richtig → `ReviewResult.good`, 2. Versuch richtig → `hard`, sonst `again`. Wirtin bewertet nichts (nur „wackelig" für diesen Besuch).
- Sprech-Schwelle wie in `diegetic_speak_sheet.dart`: `score >= 0.6`.
- Kana-Vergleich nach Normalisierung: Leerzeichen und `！？。、…・` entfernt.
- Offline: fehlt TTS/STT → kein Crash; Mikro-Knopf bleibt, Station geht weiter.
- Tests einzeln auf dem NUC: `~/flutter/bin/flutter test <datei>`; Vollsuite: `~/flutter/bin/flutter test` (bekannt rot: 8 Native-Tokenizer-Tests unter `test/mining_packs/ja/`).
- Commit-Messages enden mit `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` und `Claude-Session: https://claude.ai/code/session_01YT3vxdimKnf5CxqKiS26Tx`. `android/gradle.properties` hat eine fremde lokale Änderung — nie mitcommitten (immer `git add <pfade>`).

## Review Focus

1. **Wort mit Kanji-Lesung (駅, 傘):** `decompose` bekommt immer die Kana-Lesung (`lexeme.reading`), nie das Kanji; die Wirtin zeigt Kanji groß nur, wenn `writtenForm != reading`. Test in Task 6.
2. **Zweiter Fehlversuch beim Schulmädchen:** nach zwei falschen Antworten geht es weiter, Ergebnis `again`, genau ein Eintrag im `review_log`. Test in Task 7.
3. **„Später weiter" mitten in einer Station:** Fortsetzen setzt bei derselben Station und demselben Item wieder auf; abgeschlossene Items werden nicht erneut bewertet. Test in Task 8.
4. **Item ohne Lexem in der DB** (Budget-Item nie gesät): wird übersprungen, kein Crash, Station läuft mit dem Rest. Test in Task 6.
5. **Freier Besuch ohne fällige Items:** Raum zeigt „Die Wirtin wischt den Tresen", keine Station startet. Test in Task 8.

---

## File Structure

| Datei | Verantwortung | Task |
|---|---|---|
| `lib/features/cafe/word_decomposition.dart` | `decompose(kana) → List<SoundUnit>` | 1 |
| `lib/features/cafe/kana_keyboard.dart` | `KanaKeyboard` Widget, `normalizeKana` | 2 |
| `lib/features/cafe/bubble_overlay.dart` | `BubbleOverlay` über Panel-Bild (hervorheben/ausblenden) | 3 |
| `lib/features/cafe/cafe_visit.dart` | `CafeStation`, `CafeVisitPlan`, `CafeVisitPlanner` | 4 |
| `lib/features/story/story_progress_store.dart` | Fortsetzen (`cafeVisitPosition`, `saveCafeVisitPosition`, `markCafeVisitDone`, `isCafeVisitPending`) | 4 |
| `lib/core/db/learning_db.dart` | `lastReviewResult(learnItemId)` | 4 |
| `lib/features/cafe/cafe_summary.dart` | `summaryLines(...)` | 5 |
| `lib/features/cafe/stations/station_frame.dart` | gemeinsamer Rahmen (Kopfbild, Stimme, Inhalt, Weiter) | 6 |
| `lib/features/cafe/stations/wirtin_station.dart` | Station 1 | 6 |
| `lib/features/cafe/stations/schulmaedchen_station.dart` | Station 2 | 7 |
| `lib/features/cafe/cafe_visit_screen.dart` | Raum, Leiste, Ablauf, Fortsetzen, Abschluss | 8 |
| `lib/features/cafe/cafe_route.dart` | Einstiege Weg 1/Weg 2 → `CafeVisitScreen` | 9 |
| entfällt: `cafe_screen.dart`, `cafe_debrief_screen.dart`, `cafe_debrief_card.dart`, `cafe_turn_screen.dart`, `cafe_speaker_plan.dart` + ihre Tests | Abriss | 9 |

---

### Task 1: Zerlegung in Laut-Kacheln

**Files:**
- Create: `lib/features/cafe/word_decomposition.dart`
- Test: `test/features/cafe/word_decomposition_test.dart`

**Interfaces:**
- Produces: `class SoundUnit { final String text; final String romaji; }`, `List<SoundUnit> decompose(String kana)`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/word_decomposition.dart';

List<String> _texts(String w) => decompose(w).map((u) => u.text).toList();
List<String> _romaji(String w) => decompose(w).map((u) => u.romaji).toList();

void main() {
  test('einfache Kana: eine Kachel je Zeichen', () {
    expect(_texts('あめ'), ['あ', 'め']);
    expect(_romaji('あめ'), ['a', 'me']);
  });

  test('Yōon (きょ) ist eine Kachel', () {
    expect(_texts('きょう'), ['きょ']);
    expect(_romaji('きょう'), ['kyō']);
  });

  test('kleines っ verdoppelt den Folgekonsonanten', () {
    expect(_texts('ちょっと'), ['ちょ', 'っ', 'と']);
    expect(_romaji('ちょっと'), ['cho', 't', 'to']);
  });

  test('Dehnung とう wird zu tō, ん ist eine Kachel', () {
    expect(_texts('ありがとう'), ['あ', 'り', 'が', 'とう']);
    expect(_romaji('ありがとう'), ['a', 'ri', 'ga', 'tō']);
    expect(_romaji('さんぽ'), ['sa', 'n', 'po']);
  });

  test('Dehnung ei und Katakana-Strich', () {
    expect(_romaji('えいが'), ['ē', 'ga']);
    expect(_texts('コーヒー'), ['コー', 'ヒー']);
    expect(_romaji('コーヒー'), ['kō', 'hī']);
  });

  test('じゃ/じゅ/じょ und ぢ/づ', () {
    expect(_romaji('じょうぶ'), ['jō', 'bu']);
    expect(_romaji('だいじょうぶ'), ['da', 'i', 'jō', 'bu']);
  });

  test('unbekanntes Zeichen bleibt als Kachel ohne Laut', () {
    expect(_texts('駅'), ['駅']);
    expect(_romaji('駅'), ['']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/word_decomposition_test.dart`
Expected: FAIL — `decompose` nicht definiert.

- [ ] **Step 3: Write minimal implementation**

`lib/features/cafe/word_decomposition.dart`:

```dart
import '../../data/kana_data.dart';

/// Eine Laut-Einheit für die Kacheln der Wirtin (Spec §3.1 Punkt 3 / §6.2):
/// das Stück Kana, wie es gesprochen wird, und seine Lautschrift.
class SoundUnit {
  final String text;
  final String romaji;
  const SoundUnit(this.text, this.romaji);

  @override
  bool operator ==(Object o) =>
      o is SoundUnit && o.text == text && o.romaji == romaji;
  @override
  int get hashCode => Object.hash(text, romaji);
  @override
  String toString() => 'SoundUnit($text $romaji)';
}

const _small = {'ゃ', 'ゅ', 'ょ', 'ャ', 'ュ', 'ョ'};
const _smallVowel = {'ゃ': 'a', 'ゅ': 'u', 'ょ': 'o', 'ャ': 'a', 'ュ': 'u', 'ョ': 'o'};
const _sokuon = {'っ', 'ッ'};
const _longMark = 'ー';
const _macron = {'a': 'ā', 'i': 'ī', 'u': 'ū', 'e': 'ē', 'o': 'ō'};

final Map<String, String> _romajiOf = {
  for (final e in hiragana) e.kana: e.romaji,
  for (final e in katakana) e.kana: e.romaji,
};

/// Dehnung: der Vokal, den ein Folgezeichen verlängert, oder null.
/// う nach o/u, い nach e/i, あ nach a, Strich ー immer.
String? _lengthens(String prevRomaji, String next) {
  if (prevRomaji.isEmpty) return null;
  final v = prevRomaji[prevRomaji.length - 1];
  if (next == _longMark) return v;
  if ((next == 'う' || next == 'ウ') && (v == 'o' || v == 'u')) return v;
  if ((next == 'い' || next == 'イ') && (v == 'e' || v == 'i')) return v;
  if ((next == 'あ' || next == 'ア') && v == 'a') return v;
  return null;
}

/// Zerlegt ein Kana-Wort in Laut-Einheiten (Spec §6.2). Regeln:
/// Grundzeichen = eine Kachel; Zeichen + kleines ゃゅょ = eine Kachel
/// (きょ kyo, しゃ sha, じょ jo); kleines っ = Kachel mit verdoppeltem
/// Folgekonsonanten; ん = n; Dehnung (う nach o/u, い nach e/i, ー) wird an
/// die Kachel davor angehängt und als Makron geschrieben (とう tō).
/// Unbekannte Zeichen (Kanji) bleiben als Kachel ohne Laut.
List<SoundUnit> decompose(String kana) {
  final chars = kana.runes.map(String.fromCharCode).toList();
  final units = <SoundUnit>[];
  var i = 0;
  while (i < chars.length) {
    final c = chars[i];
    if (_sokuon.contains(c)) {
      final next = i + 1 < chars.length ? _romajiOf[chars[i + 1]] : null;
      final consonant = (next != null && next.isNotEmpty) ? next[0] : '';
      units.add(SoundUnit(c, consonant));
      i++;
      continue;
    }
    var text = c;
    var romaji = _romajiOf[c] ?? '';
    // Yōon: Konsonant des Grundzeichens + Vokal des kleinen Zeichens.
    if (i + 1 < chars.length && _small.contains(chars[i + 1]) && romaji.isNotEmpty) {
      final base = romaji.substring(0, romaji.length - 1); // ki → k, shi → sh, ji → j
      final stem = (base == 'sh' || base == 'ch' || base == 'j') ? base : '${base}y';
      romaji = '$stem${_smallVowel[chars[i + 1]]}';
      text = c + chars[i + 1];
      i++;
    }
    // Dehnung an die Kachel hängen.
    if (i + 1 < chars.length) {
      final v = _lengthens(romaji, chars[i + 1]);
      if (v != null) {
        text += chars[i + 1];
        romaji = romaji.substring(0, romaji.length - 1) + _macron[v]!;
        i++;
      }
    }
    units.add(SoundUnit(text, romaji));
    i++;
  }
  return units;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/word_decomposition_test.dart`
Expected: PASS (7 Tests). Falls `kana_data.dart` ein Zeichen anders romanisiert als erwartet (z. B. `ぢ` → `ji`), gilt die Tabelle; Test nur anpassen, wenn die Tabelle recht hat.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/word_decomposition.dart test/features/cafe/word_decomposition_test.dart
git commit -m "feat(cafe): Zerlegung eines Kana-Worts in Laut-Kacheln (Yōon, っ, ん, Dehnung)"
```

---

### Task 2: Kana-Tastatur

**Files:**
- Create: `lib/features/cafe/kana_keyboard.dart`
- Test: `test/features/cafe/kana_keyboard_test.dart`

**Interfaces:**
- Produces: `class KanaKeyboard extends StatelessWidget { KanaKeyboard({required String value, required ValueChanged<String> onChanged}) }` — zeigt das Hiragana-Raster (`hiraganaGroups`), Tasten `゛゜`, `小`, `⌫`; `String normalizeKana(String s)`; `String applyDakuten(String s)`, `String applySmall(String s)` (reine Funktionen auf dem letzten Zeichen).
- Keys: `kana-key-<kana>` je Zeichen, `kana-key-dakuten`, `kana-key-small`, `kana-key-backspace`, `kana-keyboard-value`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/kana_keyboard.dart';

void main() {
  test('normalizeKana entfernt Leerzeichen und Satzzeichen', () {
    expect(normalizeKana(' あめ！ '), 'あめ');
    expect(normalizeKana('ここ、ここ。'), 'ここここ');
    expect(normalizeKana('あめ…'), 'あめ');
  });

  test('applyDakuten kreist か → が → か, は → ば → ぱ → は', () {
    expect(applyDakuten('か'), 'が');
    expect(applyDakuten('が'), 'か');
    expect(applyDakuten('は'), 'ば');
    expect(applyDakuten('ば'), 'ぱ');
    expect(applyDakuten('ぱ'), 'は');
    expect(applyDakuten('あ'), 'あ');
    expect(applyDakuten(''), '');
  });

  test('applySmall macht das letzte Zeichen klein und zurück', () {
    expect(applySmall('じよ'), 'じょ');
    expect(applySmall('じょ'), 'じよ');
    expect(applySmall('つ'), 'っ');
    expect(applySmall('か'), 'か');
  });

  testWidgets('だいじょうぶ lässt sich über das Raster tippen', (tester) async {
    var value = '';
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: KanaKeyboard(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    Future<void> tap(String key) async {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$key')));
      await tester.tap(find.byKey(ValueKey('kana-key-$key')));
      await tester.pump();
    }

    await tap('た');
    await tap('dakuten'); // だ
    await tap('い');
    await tap('し');
    await tap('dakuten'); // じ
    await tap('よ');
    await tap('small'); // ょ
    await tap('う');
    await tap('ふ');
    await tap('dakuten'); // ぶ
    expect(value, 'だいじょうぶ');

    await tap('backspace');
    expect(value, 'だいじょう');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/kana_keyboard_test.dart`
Expected: FAIL — Symbole nicht definiert.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

import '../../data/kana_data.dart';

/// Vergleichsform für Kana-Antworten (Spec Global Constraints): ohne
/// Leerzeichen und ohne die Satzzeichen, die in Blasen vorkommen.
String normalizeKana(String s) =>
    s.replaceAll(RegExp(r'[\s！？。、…・!?.,]'), '');

const _dakutenCycle = {
  'か': 'が', 'が': 'か', 'き': 'ぎ', 'ぎ': 'き', 'く': 'ぐ', 'ぐ': 'く',
  'け': 'げ', 'げ': 'け', 'こ': 'ご', 'ご': 'こ',
  'さ': 'ざ', 'ざ': 'さ', 'し': 'じ', 'じ': 'し', 'す': 'ず', 'ず': 'す',
  'せ': 'ぜ', 'ぜ': 'せ', 'そ': 'ぞ', 'ぞ': 'そ',
  'た': 'だ', 'だ': 'た', 'ち': 'ぢ', 'ぢ': 'ち', 'つ': 'づ', 'づ': 'つ',
  'て': 'で', 'で': 'て', 'と': 'ど', 'ど': 'と',
  'は': 'ば', 'ば': 'ぱ', 'ぱ': 'は', 'ひ': 'び', 'び': 'ぴ', 'ぴ': 'ひ',
  'ふ': 'ぶ', 'ぶ': 'ぷ', 'ぷ': 'ふ', 'へ': 'べ', 'べ': 'ぺ', 'ぺ': 'へ',
  'ほ': 'ぼ', 'ぼ': 'ぽ', 'ぽ': 'ほ',
};

const _smallCycle = {
  'や': 'ゃ', 'ゃ': 'や', 'ゆ': 'ゅ', 'ゅ': 'ゆ', 'よ': 'ょ', 'ょ': 'よ',
  'つ': 'っ', 'っ': 'つ', 'あ': 'ぁ', 'ぁ': 'あ', 'い': 'ぃ', 'ぃ': 'い',
  'う': 'ぅ', 'ぅ': 'う', 'え': 'ぇ', 'ぇ': 'え', 'お': 'ぉ', 'ぉ': 'お',
};

String _replaceLast(String s, Map<String, String> cycle) {
  if (s.isEmpty) return s;
  final last = s.substring(s.length - 1);
  final next = cycle[last];
  return next == null ? s : s.substring(0, s.length - 1) + next;
}

/// ゛゜-Taste: das letzte Zeichen stimmhaft / halbstimmhaft / zurück.
String applyDakuten(String s) => _replaceLast(s, _dakutenCycle);

/// 小-Taste: das letzte Zeichen klein (ゃゅょっ, ぁぃぅぇぉ) und zurück.
String applySmall(String s) => _replaceLast(s, _smallCycle);

/// Eingebaute Hiragana-Tastatur (Spec §6.1): 50-Laute-Raster in Spalten je
/// Reihe (hiraganaGroups), dazu ゛゜, 小 und ⌫. Keine System-Tastatur nötig.
/// [value] ist der bisherige Text, [onChanged] bekommt den neuen.
class KanaKeyboard extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const KanaKeyboard({super.key, required this.value, required this.onChanged});

  Widget _key(String label, String keyName, VoidCallback onTap) => SizedBox(
        width: 44,
        height: 44,
        child: OutlinedButton(
          key: ValueKey('kana-key-$keyName'),
          style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 20)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value.isEmpty ? ' ' : value,
            key: const ValueKey('kana-keyboard-value'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28),
          ),
        ),
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // あ行 rechts wie in der 50-Laute-Tafel
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in hiraganaGroups.reversed)
                  Column(
                    children: [
                      for (final kana in group.characters)
                        _key(kana, kana, () => onChanged(value + kana)),
                    ],
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _key('゛゜', 'dakuten', () => onChanged(applyDakuten(value))),
            const SizedBox(width: 8),
            _key('小', 'small', () => onChanged(applySmall(value))),
            const SizedBox(width: 8),
            _key('⌫', 'backspace', () {
              if (value.isNotEmpty) {
                onChanged(value.substring(0, value.length - 1));
              }
            }),
          ],
        ),
      ],
    );
  }
}
```

Hinweis: `hiraganaGroups` enthält nur die Grundreihen (あ…わ + ん). Stimmhafte Zeichen entstehen über ゛゜ — so bleibt das Raster klein.

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/kana_keyboard_test.dart`
Expected: PASS. Wenn `ensureVisible` in der horizontalen Liste nicht reicht, `tester.scrollUntilVisible(find.byKey(...), 100, scrollable: find.byType(Scrollable).first)` verwenden.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/kana_keyboard.dart test/features/cafe/kana_keyboard_test.dart
git commit -m "feat(cafe): eingebaute Kana-Tastatur mit ゛゜, 小 und Normalisierung"
```

---

### Task 3: Blasen-Überlagerung über dem Panel

**Files:**
- Create: `lib/features/cafe/bubble_overlay.dart`
- Test: `test/features/cafe/bubble_overlay_test.dart`

**Interfaces:**
- Consumes: `StoryPanel.assetFor(PanelFormat)`, `StoryBubble.hitAreaFor(PanelFormat).points` (normiert 0..1), `aspectOf(PanelFormat)` aus `panel_geometry.dart`.
- Produces: `enum BubbleOverlayMode { highlight, blank }`, `class PanelWithBubble extends StatelessWidget { PanelWithBubble({required StoryPanel panel, required StoryBubble bubble, required String targetSurface, required BubbleOverlayMode mode, PanelFormat format = PanelFormat.portrait}) }`, `List<InlineSpan> bubbleSpans(String text, String target, BubbleOverlayMode mode, TextStyle base)`.
- Keys: `bubble-overlay`, `bubble-overlay-text`, Panelbild `bubble-overlay-panel`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/bubble_overlay.dart';
import 'package:nihongo_app/features/story/episode.dart';

StoryPanel _panel() => StoryPanel.fromJson({
      'index': 0,
      'asset': 'assets/story/folge01/p03.jpg',
      'assetPortrait': 'assets/story/folge01/p03_hoch.jpg',
      'bubbles': [
        {
          'speakerId': 'passant_a',
          'text': 'すみません！あめ！さむい！',
          'hitArea': [
            {'x': 0.725, 'y': 0.1}, {'x': 0.96, 'y': 0.1},
            {'x': 0.96, 'y': 0.22}, {'x': 0.725, 'y': 0.22},
          ],
          'hitAreaPortrait': [
            {'x': 0.6, 'y': 0.212}, {'x': 0.9, 'y': 0.212},
            {'x': 0.9, 'y': 0.277}, {'x': 0.6, 'y': 0.277},
          ],
          'tokens': [
            {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
            {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
            {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
          ],
        },
      ],
      'thoughts': [],
      'interactions': [],
    });

String _plain(List<InlineSpan> spans) =>
    spans.map((s) => (s as TextSpan).text ?? '').join();

void main() {
  const base = TextStyle(fontSize: 14);

  test('highlight lässt den Text ganz und färbt nur das Zielwort', () {
    final spans = bubbleSpans('すみません！あめ！さむい！', 'あめ',
        BubbleOverlayMode.highlight, base);
    expect(_plain(spans), 'すみません！あめ！さむい！');
    final hit = spans.cast<TextSpan>().where((s) => s.text == 'あめ').single;
    expect(hit.style?.color, isNot(base.color));
    expect(hit.style?.fontWeight, FontWeight.bold);
  });

  test('blank ersetzt genau das Zielwort durch ___', () {
    final spans = bubbleSpans('すみません！あめ！さむい！', 'あめ',
        BubbleOverlayMode.blank, base);
    expect(_plain(spans), 'すみません！___！さむい！');
  });

  testWidgets('die Überlagerung sitzt auf dem Rechteck der Hochformat-Blase',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 270,
          height: 484, // 1080:1936
          child: PanelWithBubble(
            panel: _panel(),
            bubble: _panel().bubbles.first,
            targetSurface: 'あめ',
            mode: BubbleOverlayMode.blank,
          ),
        ),
      ),
    ));
    await tester.pump();
    final overlay = tester.getRect(find.byKey(const ValueKey('bubble-overlay')));
    final panel = tester.getRect(find.byKey(const ValueKey('bubble-overlay-panel')));
    expect(overlay.left, closeTo(panel.left + 0.6 * panel.width, 1));
    expect(overlay.top, closeTo(panel.top + 0.212 * panel.height, 1));
    expect(overlay.width, closeTo(0.3 * panel.width, 1));
    expect(find.text('すみません！___！さむい！'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/bubble_overlay_test.dart`
Expected: FAIL — Symbole nicht definiert.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

import '../story/episode.dart';
import '../story/panel_geometry.dart';

/// Wie die Blase über dem Panel gezeichnet wird (Spec §6.3): Zielwort
/// hervorgehoben (Wirtin) oder ausgeblendet (Schulmädchen, Sehen→Sprechen).
enum BubbleOverlayMode { highlight, blank }

/// Der Blasentext als Spans: [target] farbig/fett oder durch „___" ersetzt.
List<InlineSpan> bubbleSpans(
    String text, String target, BubbleOverlayMode mode, TextStyle base) {
  final spans = <InlineSpan>[];
  var rest = text;
  while (rest.isNotEmpty) {
    final at = target.isEmpty ? -1 : rest.indexOf(target);
    if (at < 0) {
      spans.add(TextSpan(text: rest, style: base));
      break;
    }
    if (at > 0) spans.add(TextSpan(text: rest.substring(0, at), style: base));
    spans.add(switch (mode) {
      BubbleOverlayMode.highlight => TextSpan(
          text: target,
          style: base.copyWith(
              color: const Color(0xFFB3261E), fontWeight: FontWeight.bold)),
      BubbleOverlayMode.blank => TextSpan(text: '___', style: base),
    });
    rest = rest.substring(at + target.length);
  }
  return spans;
}

/// Panelbild (Hochformat, `assetFor`) mit einer weißen Blase an der Stelle
/// des Blasen-Rechtecks (`hitAreaFor`) — die gelesene Blase darunter bleibt
/// verdeckt. Kein neues Rendern, keine zusätzlichen Bilddateien.
class PanelWithBubble extends StatelessWidget {
  final StoryPanel panel;
  final StoryBubble bubble;
  final String targetSurface;
  final BubbleOverlayMode mode;
  final PanelFormat format;

  const PanelWithBubble({
    super.key,
    required this.panel,
    required this.bubble,
    required this.targetSurface,
    required this.mode,
    this.format = PanelFormat.portrait,
  });

  Rect _bbox() {
    final pts = bubble.hitAreaFor(format).points;
    if (pts.isEmpty) return const Rect.fromLTWH(0.05, 0.05, 0.9, 0.12);
    var l = 1.0, t = 1.0, r = 0.0, b = 0.0;
    for (final p in pts) {
      if (p.x < l) l = p.x;
      if (p.y < t) t = p.y;
      if (p.x > r) r = p.x;
      if (p.y > b) b = p.y;
    }
    return Rect.fromLTRB(l, t, r, b);
  }

  @override
  Widget build(BuildContext context) {
    final box = _bbox();
    return AspectRatio(
      aspectRatio: aspectOf(format),
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              panel.assetFor(format),
              key: const ValueKey('bubble-overlay-panel'),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFF2A3035)),
            ),
            Positioned(
              left: box.left * w,
              top: box.top * h,
              width: box.width * w,
              height: box.height * h,
              child: Container(
                key: const ValueKey('bubble-overlay'),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    key: const ValueKey('bubble-overlay-text'),
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: bubbleSpans(
                          bubble.text,
                          targetSurface,
                          mode,
                          const TextStyle(
                              color: Colors.black, fontSize: 16, height: 1.2)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/bubble_overlay_test.dart`
Expected: PASS. (`find.text` findet RichText über seinen Klartext; falls nicht, `find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == '…')` verwenden.)

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/bubble_overlay.dart test/features/cafe/bubble_overlay_test.dart
git commit -m "feat(cafe): Blasen-Überlagerung über dem Panel — Zielwort hervorheben oder ausblenden"
```

---

### Task 4: Planer, Fortsetzen, letztes Ergebnis

**Files:**
- Create: `lib/features/cafe/cafe_visit.dart`
- Modify: `lib/features/story/story_progress_store.dart` (neue Methoden ans Ende der Klasse)
- Modify: `lib/core/db/learning_db.dart` (neue Methode nach `getLearnItem`, Zeile ~101)
- Test: `test/features/cafe/cafe_visit_test.dart`, `test/features/story/story_progress_store_cafe_test.dart`

**Interfaces:**
- Consumes: `debriefOrder(episode)` (`cafe_debrief.dart`), `LearnItem` (`masteryRung`, `refId`, `dueAt`), `guestForRung`.
- Produces:
  - `enum CafeStation { wirtin, schulmaedchen, vielredner, gleichaltrige }`
  - `class CafeVisitPlan { final List<CafeStationPlan> stations; }`, `class CafeStationPlan { final CafeStation station; final List<String> itemIds; }`
  - `CafeVisitPlan planAfterEpisode(Episode episode, {Set<String> vielrednerTargets = const {}, Set<String> gleichaltrigeTargets = const {}, Set<String> wobbly = const {}})`
  - `CafeVisitPlan planFreeVisit(List<LearnItem> due, Map<String, String?> lastResultById, {int maxItems = 12})`
  - `StoryProgressStore`: `Future<({int station, int item})?> cafeVisitPosition(String visitId)`, `saveCafeVisitPosition(String visitId, int station, int item)`, `clearCafeVisitPosition(String visitId)`, `markCafeVisitDone(String episodeId)`, `isCafeVisitPending(String episodeId)` (= `isCompleted && !done`).
  - `LearningDb.lastReviewResult(String learnItemId) → Future<String?>`, `LearningDb.learnItemsFor(String langId) → Future<List<LearnItem>>` (alle Items der Sprache, für die freiwillige Runde §2).
  - `CafeVisitPlan planPracticeAnyway(List<LearnItem> all, {int max = 6, required int seed})` — Schulmädchen über bis zu [max] bekannte Wörter (Sprosse ≥ 1), deterministisch gemischt mit `Random(seed)`.

- [ ] **Step 1: Write the failing tests**

`test/features/cafe/cafe_visit_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_visit.dart';
import 'package:nihongo_app/features/story/episode.dart';

Episode _episode(List<String> ids) => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [for (final id in ids) {'id': id, 'refType': 'lexeme'}],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'x', 'hitArea': [],
                  'tokens': [for (final id in ids.reversed) {'surface': 'x', 'itemId': id}],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

LearnItem _item(String id, int rung, {int dueDaysAgo = 0}) => LearnItem(
      id: 'lang_ja:lexeme:$id', languageId: 'lang_ja', refType: 'lexeme',
      refId: id, masteryRung: rung, ease: 2.5, intervalDays: 1,
      dueAt: DateTime.now().subtract(Duration(days: dueDaysAgo)),
      reps: 1, lapses: 0, consecutiveCorrect: 0);

void main() {
  group('planAfterEpisode', () {
    test('Wirtin bekommt alle Wörter in Auftrittsreihenfolge, Schulmädchen '
        'alle ohne anderes Ziel, wackelige zuerst', () {
      final ep = _episode(['a', 'b', 'c', 'd']);
      final plan = planAfterEpisode(ep,
          vielrednerTargets: {'c'}, gleichaltrigeTargets: {'d'}, wobbly: {'b'});
      expect(plan.stations.map((s) => s.station),
          [CafeStation.wirtin, CafeStation.schulmaedchen]);
      expect(plan.stations[0].itemIds, ['d', 'c', 'b', 'a']); // Token-Reihenfolge
      expect(plan.stations[1].itemIds, ['b', 'a']);
    });

    test('jedes Wort ist Ziel in mindestens einer aktiven Station (INV-23)', () {
      final ep = _episode(['a', 'b', 'c']);
      final plan = planAfterEpisode(ep, vielrednerTargets: {'a'});
      final covered = {
        for (final s in plan.stations)
          if (s.station != CafeStation.wirtin) ...s.itemIds,
        'a',
      };
      expect(covered, {'a', 'b', 'c'});
    });

    test('Stationen ohne Items fehlen im Plan', () {
      final ep = _episode(['a']);
      final plan = planAfterEpisode(ep, vielrednerTargets: {'a'});
      expect(plan.stations.map((s) => s.station), [CafeStation.wirtin]);
    });
  });

  group('planFreeVisit', () {
    test('Sprosse ≤2 mit letztem again/hard → Wirtin, sonst Schulmädchen; '
        'Sprosse 4/5 in Plan A ebenfalls Schulmädchen', () {
      final plan = planFreeVisit(
        [_item('a', 1), _item('b', 2), _item('c', 3), _item('d', 5)],
        {'lang_ja:lexeme:a': 'again', 'lang_ja:lexeme:b': 'good'},
      );
      expect(plan.stationFor(CafeStation.wirtin)?.itemIds, ['a']);
      expect(plan.stationFor(CafeStation.schulmaedchen)?.itemIds, ['b', 'c', 'd']);
    });

    test('höchstens maxItems, die am längsten fälligen zuerst', () {
      final due = [for (var i = 0; i < 15; i++) _item('w$i', 3, dueDaysAgo: i)];
      final plan = planFreeVisit(due, const {}, maxItems: 12);
      final ids = plan.stations.expand((s) => s.itemIds).toList();
      expect(ids.length, 12);
      expect(ids.first, 'w14');
      expect(ids, isNot(contains('w0')));
    });

    test('nichts fällig → leerer Plan', () {
      expect(planFreeVisit(const [], const {}).stations, isEmpty);
    });
  });

  group('planPracticeAnyway', () {
    test('bis zu max bekannte Wörter (Sprosse ≥ 1) beim Schulmädchen, '
        'gleiche Saat → gleiche Reihenfolge', () {
      final all = [_item('neu', 0), for (var i = 0; i < 8; i++) _item('k$i', 2)];
      final a = planPracticeAnyway(all, seed: 7);
      final b = planPracticeAnyway(all, seed: 7);
      expect(a.stations.single.station, CafeStation.schulmaedchen);
      expect(a.stations.single.itemIds.length, 6);
      expect(a.stations.single.itemIds, isNot(contains('neu')));
      expect(a.stations.single.itemIds, b.stations.single.itemIds);
    });

    test('ohne bekannte Wörter → leerer Plan', () {
      expect(planPracticeAnyway([_item('neu', 0)], seed: 1).stations, isEmpty);
    });
  });
}
```

`test/features/story/story_progress_store_cafe_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StoryProgressStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
  });

  test('Position speichern, lesen, löschen', () async {
    expect(await store.cafeVisitPosition('ep_1'), isNull);
    await store.saveCafeVisitPosition('ep_1', 1, 3);
    expect(await store.cafeVisitPosition('ep_1'), (station: 1, item: 3));
    await store.clearCafeVisitPosition('ep_1');
    expect(await store.cafeVisitPosition('ep_1'), isNull);
  });

  test('Besuch offen = Folge beendet und Besuch nicht erledigt', () async {
    expect(await store.isCafeVisitPending('ep_1'), isFalse);
    await store.markCompleted('ep_1');
    expect(await store.isCafeVisitPending('ep_1'), isTrue);
    await store.markCafeVisitDone('ep_1');
    expect(await store.isCafeVisitPending('ep_1'), isFalse);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_visit_test.dart test/features/story/story_progress_store_cafe_test.dart`
Expected: FAIL — Symbole nicht definiert.

- [ ] **Step 3: Write minimal implementation**

`lib/features/cafe/cafe_visit.dart`:

```dart
import '../../core/db/learning_db.dart';
import '../story/episode.dart';
import 'cafe_debrief.dart';

/// Die vier Stationen (Spec §3) in fester Reihenfolge.
enum CafeStation { wirtin, schulmaedchen, vielredner, gleichaltrige }

class CafeStationPlan {
  final CafeStation station;
  final List<String> itemIds; // refIds (Lexem-IDs), in Übungsreihenfolge
  const CafeStationPlan(this.station, this.itemIds);
}

class CafeVisitPlan {
  final List<CafeStationPlan> stations;
  const CafeVisitPlan(this.stations);

  CafeStationPlan? stationFor(CafeStation s) {
    for (final p in stations) {
      if (p.station == s) return p;
    }
    return null;
  }
}

/// Weg 1 (Spec §2.1): Wirtin alle Wörter in Auftrittsreihenfolge; Schul-
/// mädchen alle Wörter, die weder beim alten Mann noch bei der Gleichaltrigen
/// Ziel sind — wackelige zuerst. Stationen 3/4 füllt Plan B über die
/// Ziel-Mengen; leere Stationen fehlen im Plan.
CafeVisitPlan planAfterEpisode(
  Episode episode, {
  Set<String> vielrednerTargets = const {},
  Set<String> gleichaltrigeTargets = const {},
  Set<String> wobbly = const {},
}) {
  final order = [
    for (final id in debriefOrder(episode))
      if (episode.budget.items.any((i) => i.id == id && i.refType == RefType.lexeme)) id,
  ];
  final others = {...vielrednerTargets, ...gleichaltrigeTargets};
  final rest = order.where((id) => !others.contains(id)).toList();
  final schul = [
    ...rest.where(wobbly.contains),
    ...rest.where((id) => !wobbly.contains(id)),
  ];
  return CafeVisitPlan([
    if (order.isNotEmpty) CafeStationPlan(CafeStation.wirtin, order),
    if (schul.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, schul),
  ]);
}

/// Weg 2 (Spec §2.2): nach Sprosse. Sprosse ≤2 mit letztem Ergebnis
/// again/hard → Wirtin, sonst Schulmädchen; Sprosse 3 → Schulmädchen.
/// Plan A: Sprosse 4/5 ebenfalls Schulmädchen (Stationen 3/4 kommen in
/// Plan B und übernehmen dann). Höchstens [maxItems], die am längsten
/// fälligen zuerst. [lastResultById] ist `LearnItem.id → review_log.result`.
CafeVisitPlan planFreeVisit(
  List<LearnItem> due,
  Map<String, String?> lastResultById, {
  int maxItems = 12,
}) {
  final sorted = [...due]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  final picked = sorted.take(maxItems);
  final wirtin = <String>[];
  final schul = <String>[];
  for (final item in picked) {
    final last = lastResultById[item.id];
    final shaky = last == 'again' || last == 'hard';
    if (item.masteryRung <= 2 && shaky) {
      wirtin.add(item.refId);
    } else {
      schul.add(item.refId);
    }
  }
  return CafeVisitPlan([
    if (wirtin.isNotEmpty) CafeStationPlan(CafeStation.wirtin, wirtin),
    if (schul.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, schul),
  ]);
}

/// Freiwillige Runde, wenn nichts fällig ist (Spec §2): das Schulmädchen
/// fragt bis zu [max] bekannte Wörter (Sprosse ≥ 1) ab, deterministisch
/// gemischt — der Aufrufer gibt als [seed] z. B. den Tag des Monats.
CafeVisitPlan planPracticeAnyway(List<LearnItem> all,
    {int max = 6, required int seed}) {
  final known = all.where((i) => i.masteryRung >= 1).toList()
    ..shuffle(Random(seed));
  final ids = known.take(max).map((i) => i.refId).toList();
  return CafeVisitPlan([
    if (ids.isNotEmpty) CafeStationPlan(CafeStation.schulmaedchen, ids),
  ]);
}
```

Imports: `dart:math` (Random) und `RefType` aus `package:nihongo_app/core/ladder/rung_defs.dart` (so wie `cafe_debrief.dart` ihn nutzt).

`StoryProgressStore` — ans Ende der Klasse:

```dart
  static const _cafePosPrefix = 'cafe_visit_pos_';
  static const _cafeDonePrefix = 'cafe_visit_done_';

  /// „Später weiter" (Spec §2): Station und Item, bei denen der Besuch
  /// [visitId] (Folgen-ID oder `free`) abgebrochen wurde.
  Future<({int station, int item})?> cafeVisitPosition(String visitId) async {
    final raw = _prefs.getString('$_cafePosPrefix$visitId');
    if (raw == null) return null;
    final parts = raw.split(':');
    return (station: int.parse(parts[0]), item: int.parse(parts[1]));
  }

  Future<void> saveCafeVisitPosition(String visitId, int station, int item) =>
      _prefs.setString('$_cafePosPrefix$visitId', '$station:$item');

  Future<void> clearCafeVisitPosition(String visitId) async {
    await _prefs.remove('$_cafePosPrefix$visitId');
  }

  /// Weg 1 ist für diese Folge einmal zu Ende gegangen. Kein Fortschritt im
  /// Sinne von INV-10 — die Endkarte lädt nur nicht zweimal ein.
  Future<void> markCafeVisitDone(String episodeId) =>
      _prefs.setBool('$_cafeDonePrefix$episodeId', true);

  Future<bool> isCafeVisitPending(String episodeId) async =>
      await isCompleted(episodeId) &&
      !(_prefs.getBool('$_cafeDonePrefix$episodeId') ?? false);
```

`LearningDb` — nach `getLearnItem`:

```dart
  /// Letztes Ergebnis eines Items (`again|hard|good|easy`), null ohne Log.
  Future<String?> lastReviewResult(String learnItemId) async {
    final row = await (select(reviewLog)
          ..where((t) => t.learnItemId.equals(learnItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.ts)])
          ..limit(1))
        .getSingleOrNull();
    return row?.result;
  }

  /// Alle Items einer Sprache (freiwillige Runde im leeren Café, Spec §2).
  Future<List<LearnItem>> learnItemsFor(String langId) =>
      (select(learnItems)..where((t) => t.languageId.equals(langId))).get();
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_visit_test.dart test/features/story/story_progress_store_cafe_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_visit.dart lib/features/story/story_progress_store.dart lib/core/db/learning_db.dart \
  test/features/cafe/cafe_visit_test.dart test/features/story/story_progress_store_cafe_test.dart
git commit -m "feat(cafe): Besuchs-Planer (nach Folge / frei), Fortsetzen, letztes Ergebnis je Item"
```

---

### Task 5: Abschlusstext der Wirtin

**Files:**
- Create: `lib/features/cafe/cafe_summary.dart`
- Test: `test/features/cafe/cafe_summary_test.dart`

**Interfaces:**
- Consumes: `CafeOutcome` (`cafe_turn.dart`).
- Produces: `class VisitRecord { final String itemId; final String writtenForm; final CafeOutcome outcome; final bool firstTry; final DateTime? dueAt; }`, `List<String> summaryLines(List<VisitRecord> records, {required DateTime now})`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_summary.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';

void main() {
  final now = DateTime(2026, 10, 10, 20);
  VisitRecord r(String form, CafeOutcome o, {bool first = true, int dueInDays = 1}) =>
      VisitRecord(itemId: form, writtenForm: form, outcome: o, firstTry: first,
          dueAt: now.add(Duration(days: dueInDays)));

  test('sitzt = beim ersten Versuch richtig; Rest kommt wieder, mit Zeitwort', () {
    final lines = summaryLines([
      r('かさ', CafeOutcome.correct),
      r('どうぞ', CafeOutcome.correct),
      r('こわれた', CafeOutcome.correct, first: false, dueInDays: 1),
      r('いくら', CafeOutcome.wrong, dueInDays: 0),
    ], now: now);
    expect(lines, [
      'かさ und どうぞ sitzen.',
      'こわれた und いくら kommen morgen wieder.',
    ]);
  });

  test('in ein paar Tagen ab 3 Tagen; nur ein Wort ohne „und"', () {
    final lines = summaryLines([
      r('あめ', CafeOutcome.correct, first: false, dueInDays: 4),
    ], now: now);
    expect(lines, ['あめ kommt in ein paar Tagen wieder.']);
  });

  test('ohne Bewertungen: nur die Wirtin', () {
    expect(summaryLines(const [], now: now), ['Das war es für heute.']);
  });

  test('keine Zahlen im Text (INV-10) — auch bei vielen Wörtern', () {
    final lines = summaryLines([
      for (var i = 0; i < 12; i++) r('w$i', CafeOutcome.correct),
    ], now: now);
    // Die Testwörter heißen w0…w11; nur der Text drumherum zählt.
    expect(lines.join().replaceAll(RegExp(r'w\d+'), ''),
        isNot(matches(RegExp(r'\d'))));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_summary_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'cafe_turn.dart';

/// Ein bewertetes Item dieses Besuchs (Schulmädchen; ab Plan B auch alter
/// Mann). [firstTry] = beim ersten Versuch richtig.
class VisitRecord {
  final String itemId;
  final String writtenForm;
  final CafeOutcome outcome;
  final bool firstTry;
  final DateTime? dueAt;
  const VisitRecord({
    required this.itemId,
    required this.writtenForm,
    required this.outcome,
    required this.firstTry,
    this.dueAt,
  });
}

String _join(List<String> words) {
  if (words.length == 1) return words.single;
  return '${words.sublist(0, words.length - 1).join(', ')} und ${words.last}';
}

/// Abschluss in Worten (Spec §4): „sitzen" = beim ersten Versuch richtig;
/// alles andere „kommt wieder" — morgen / in ein paar Tagen (≥ 3 Tage).
/// Nie Zahlen, nie Häkchen (INV-10); hier wird nichts gezählt.
List<String> summaryLines(List<VisitRecord> records, {required DateTime now}) {
  if (records.isEmpty) return const ['Das war es für heute.'];
  final sitzen = <String>[];
  final morgen = <String>[];
  final tage = <String>[];
  for (final r in records) {
    if (r.outcome == CafeOutcome.correct && r.firstTry) {
      sitzen.add(r.writtenForm);
      continue;
    }
    final days = r.dueAt == null ? 1 : r.dueAt!.difference(now).inDays;
    (days >= 3 ? tage : morgen).add(r.writtenForm);
  }
  final lines = <String>[];
  if (sitzen.isNotEmpty) {
    lines.add('${_join(sitzen)} ${sitzen.length == 1 ? 'sitzt' : 'sitzen'}.');
  }
  if (morgen.isNotEmpty) {
    lines.add('${_join(morgen)} ${morgen.length == 1 ? 'kommt' : 'kommen'} morgen wieder.');
  }
  if (tage.isNotEmpty) {
    lines.add('${_join(tage)} ${tage.length == 1 ? 'kommt' : 'kommen'} in ein paar Tagen wieder.');
  }
  return lines;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_summary_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_summary.dart test/features/cafe/cafe_summary_test.dart
git commit -m "feat(cafe): Abschluss der Wirtin in Worten — sitzt / kommt morgen wieder"
```

---

### Task 6: Stationsrahmen und Wirtin-Station

**Files:**
- Create: `lib/features/cafe/stations/station_frame.dart`
- Create: `lib/features/cafe/stations/wirtin_station.dart`
- Test: `test/features/cafe/wirtin_station_test.dart`

**Interfaces:**
- Consumes: `decompose`, `PanelWithBubble`/`BubbleOverlayMode.highlight`, `firstAppearancePanel`, `loadLexemeWithConcept`, `meaningForConcept`, `Episode.debrief[itemId]` (`DebriefNote.usage`), `SpeakEvaluator`, `sceneAsset(stammplatzOf(CafeGuest.wirtin), light)`.
- Produces:
  - `typedef Speak = Future<void> Function(String text);`
  - `class StationFrame extends StatelessWidget { StationFrame({required CafeStation station, required CafeLight light, required String voiceLine, required Widget child, required VoidCallback? onNext, String nextLabel = 'Weiter', VoidCallback? onLater}) }` — Kopfbild (`cafe-station-scene`), Titel je Station (`Die Wirtin`, `Das Schulmädchen`, `Der alte Mann`, `Die Gleichaltrige`), Stimme (`cafe-station-voice`), Inhalt, unten `Weiter` (`cafe-station-next`) und `Später weiter` (`cafe-station-later`).
  - `class WirtinStation extends StatefulWidget { WirtinStation({required LearningDb db, required Episode? episode, required List<String> itemIds, required int startIndex, required Speak speak, required Speak speakSlow, required SpeakEvaluator evaluator, required Map<String, String> grammarNotes, required CafeLight light, required void Function(int nextIndex) onPosition, required void Function(Set<String> wobbly) onDone, required VoidCallback onLater}) }`.
  - Keys: `wirtin-word`, `wirtin-kanji`, `wirtin-tile-<i>`, `wirtin-meaning`, `wirtin-usage`, `wirtin-grammar`, `wirtin-mic`, `wirtin-feedback`, `wirtin-panel`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/stations/wirtin_station.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

class _FakeEvaluator implements SpeakEvaluator {
  final List<double> scores;
  int calls = 0;
  _FakeEvaluator(this.scores);
  @override
  Future<double> evaluate(String target) async => scores[calls++ % scores.length];
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_eki', 'refType': 'lexeme'},
          {'id': 'lex_ja_ghost', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {'usage': 'Regen. Das Wort vom Zettel.', 'variants': []},
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'assets/story/folge01/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！',
                  'hitArea': [{'x': 0.1, 'y': 0.1}, {'x': 0.5, 'y': 0.1}, {'x': 0.5, 'y': 0.2}, {'x': 0.1, 'y': 0.2}],
                  'tokens': [{'surface': 'あめ', 'itemId': 'lex_ja_ame'}],
                },
                {
                  'speakerId': 'signage', 'text': '駅',
                  'hitArea': [{'x': 0.1, 'y': 0.3}, {'x': 0.5, 'y': 0.3}, {'x': 0.5, 'y': 0.4}, {'x': 0.1, 'y': 0.4}],
                  'tokens': [{'surface': '駅', 'itemId': 'lex_ja_eki'}],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain', glossKey: 'rain', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame', languageId: 'lang_ja', conceptId: 'concept_rain',
        writtenForm: 'あめ', reading: 'あめ'));
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_station', glossKey: 'station', partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_eki', languageId: 'lang_ja', conceptId: 'concept_station',
        writtenForm: '駅', reading: 'えき'));
  });
  tearDown(() => db.close());

  Future<({List<String> spoken, List<String> slow, Set<String>? wobbly, List<int> positions})>
      pump(WidgetTester tester, _FakeEvaluator ev, List<String> ids) async {
    final spoken = <String>[], slow = <String>[], positions = <int>[];
    Set<String>? wobbly;
    await tester.pumpWidget(MaterialApp(
      home: WirtinStation(
        db: db,
        episode: _episode(),
        itemIds: ids,
        startIndex: 0,
        speak: (t) async => spoken.add(t),
        speakSlow: (t) async => slow.add(t),
        evaluator: ev,
        grammarNotes: const {'lex_ja_ame': 'Keine Form, nur das Wort.'},
        light: CafeLight.tag,
        onPosition: positions.add,
        onDone: (w) => wobbly = w,
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();
    return (spoken: spoken, slow: slow, wobbly: wobbly, positions: positions);
  }

  testWidgets('zeigt Wort, Kacheln mit Laut, Bedeutung, Erklärung, Grammatik; '
      'liest beim Öffnen ganz und langsam vor', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    expect(find.byKey(const ValueKey('wirtin-word')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-kanji')), findsNothing);
    expect(find.byKey(const ValueKey('wirtin-tile-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-tile-1')), findsOneWidget);
    expect(find.text('a'), findsOneWidget);
    expect(find.text('me'), findsOneWidget);
    expect(find.text('Regen'), findsOneWidget);
    expect(find.text('Regen. Das Wort vom Zettel.'), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-grammar')), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-panel')), findsOneWidget);
    expect(r.spoken, ['あめ']);
    expect(r.slow, ['あめ']);
  });

  testWidgets('Tipp auf eine Kachel spricht nur diesen Laut', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    await tester.tap(find.byKey(const ValueKey('wirtin-tile-1')));
    await tester.pump();
    expect(r.spoken.last, 'め');
  });

  testWidgets('Kanji-Wort: Kanji groß, Kana darunter, Kacheln aus der Lesung',
      (tester) async {
    await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_eki']);
    expect(find.byKey(const ValueKey('wirtin-kanji')), findsOneWidget);
    expect(find.text('えき'), findsWidgets);
    expect(find.text('e'), findsOneWidget);
    expect(find.text('ki'), findsOneWidget);
  });

  testWidgets('Nachsprechen: geschafft → Weiter frei; zweimal nicht → Wort '
      'wackelig, es geht trotzdem weiter', (tester) async {
    final r = await pump(tester, _FakeEvaluator([0.2, 0.2]), ['lex_ja_ame']);
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    expect(r.slow.length, 2); // einmal beim Öffnen, einmal nach dem Fehlversuch
    await tester.tap(find.byKey(const ValueKey('wirtin-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(r.wobbly, {'lex_ja_ame'});
  });

  testWidgets('Item ohne Lexem wird übersprungen, Position wird gemeldet',
      (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ghost', 'lex_ja_ame']);
    expect(find.text('Regen'), findsOneWidget); // direkt beim zweiten
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(r.positions, contains(2));
    expect(r.wobbly, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/wirtin_station_test.dart`
Expected: FAIL — Symbole nicht definiert.

- [ ] **Step 3: Write minimal implementation**

`lib/features/cafe/stations/station_frame.dart`:

```dart
import 'package:flutter/material.dart';

import '../cafe_occupancy.dart';
import '../cafe_scenes.dart';
import '../cafe_visit.dart';

typedef Speak = Future<void> Function(String text);

const stationTitles = {
  CafeStation.wirtin: 'Die Wirtin',
  CafeStation.schulmaedchen: 'Das Schulmädchen',
  CafeStation.vielredner: 'Der alte Mann',
  CafeStation.gleichaltrige: 'Die Gleichaltrige',
};

CafeGuest guestOf(CafeStation s) => switch (s) {
      CafeStation.wirtin => CafeGuest.wirtin,
      CafeStation.schulmaedchen => CafeGuest.schulkind,
      CafeStation.vielredner => CafeGuest.vielredner,
      CafeStation.gleichaltrige => CafeGuest.gleichaltrige,
    };

/// Gemeinsamer Rahmen aller Stationen (Spec §3): Kopfbild des Gastes,
/// eine Zeile in seiner Stimme, der Inhalt, unten „Weiter" und „Später
/// weiter". Keine Zähler (INV-10).
class StationFrame extends StatelessWidget {
  final CafeStation station;
  final CafeLight light;
  final String voiceLine;
  final Widget child;
  final VoidCallback? onNext;
  final String nextLabel;
  final VoidCallback? onLater;

  const StationFrame({
    super.key,
    required this.station,
    required this.light,
    required this.voiceLine,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Weiter',
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stationTitles[station]!)),
      body: Column(
        children: [
          Image.asset(
            sceneAsset(stammplatzOf(guestOf(station)), light),
            key: const ValueKey('cafe-station-scene'),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                Container(height: 120, color: const Color(0xFF2A3035)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(voiceLine,
                  key: const ValueKey('cafe-station-voice'),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ),
          Expanded(child: SingleChildScrollView(child: child)),
          SafeArea(
            top: false,
            child: Row(
              children: [
                if (onLater != null)
                  TextButton(
                    key: const ValueKey('cafe-station-later'),
                    onPressed: onLater,
                    child: const Text('Später weiter'),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    key: const ValueKey('cafe-station-next'),
                    onPressed: onNext,
                    child: Text(nextLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

`lib/features/cafe/stations/wirtin_station.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/db/learning_db.dart';
import '../../../core/db/lexeme_lookup.dart';
import '../../../core/i18n/concept_meaning.dart';
import '../../story/episode.dart';
import '../../story/speak_evaluator.dart';
import '../bubble_overlay.dart';
import '../cafe_debrief.dart';
import '../cafe_scenes.dart';
import '../cafe_visit.dart';
import '../word_decomposition.dart';
import 'station_frame.dart';

/// Ein geladenes Wort der Wirtin-Station.
class _WirtinWord {
  final String itemId;
  final String writtenForm;
  final String reading;
  final String meaning;
  final List<SoundUnit> units;
  final StoryPanel? panel;
  final StoryBubble? bubble;
  final String? usage;
  final String? grammar;
  const _WirtinWord({
    required this.itemId, required this.writtenForm, required this.reading,
    required this.meaning, required this.units, this.panel, this.bubble,
    this.usage, this.grammar,
  });
  bool get hasKanji => writtenForm != reading;
}

/// Station 1 „Auflösen" (Spec §3.1). Pro Wort: Panel mit hervorgehobener
/// Blase, Wort groß (Kanji + Kana), Laut-Kacheln mit Vorlesen, Bedeutung,
/// „warum sagt man das", Grammatiknotiz, Nachsprechen (2 Versuche, danach
/// immer weiter). Bewertet nichts; meldet am Ende die wackeligen Wörter.
class WirtinStation extends StatefulWidget {
  final LearningDb db;
  final Episode? episode;
  final List<String> itemIds;
  final int startIndex;
  final Speak speak;
  final Speak speakSlow;
  final SpeakEvaluator evaluator;
  final Map<String, String> grammarNotes;
  final CafeLight light;
  final void Function(int nextIndex) onPosition;
  final void Function(Set<String> wobbly) onDone;
  final VoidCallback onLater;
  final double threshold;

  const WirtinStation({
    super.key,
    required this.db,
    required this.episode,
    required this.itemIds,
    required this.startIndex,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    required this.grammarNotes,
    required this.light,
    required this.onPosition,
    required this.onDone,
    required this.onLater,
    this.threshold = 0.6,
  });

  @override
  State<WirtinStation> createState() => _WirtinStationState();
}

class _WirtinStationState extends State<WirtinStation> {
  int _index = 0;
  _WirtinWord? _word;
  int _attempts = 0;
  String? _feedback;
  bool _succeeded = false;
  final _wobbly = <String>{};

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _loadCurrent();
  }

  Future<_WirtinWord?> _load(String itemId) async {
    final found = await loadLexemeWithConcept(widget.db, itemId);
    if (found == null) return null;
    final ep = widget.episode;
    final panel = ep == null ? null : firstAppearancePanel(ep, itemId);
    StoryBubble? bubble;
    if (panel != null) {
      for (final b in panel.bubbles) {
        if (b.tokens.any((t) => t.itemId == itemId)) {
          bubble = b;
          break;
        }
      }
    }
    return _WirtinWord(
      itemId: itemId,
      writtenForm: found.lexeme.writtenForm,
      reading: found.lexeme.reading,
      meaning: meaningForConcept(found.concept.id, fallback: found.concept.glossKey),
      units: decompose(found.lexeme.reading),
      panel: panel,
      bubble: bubble,
      usage: ep?.debrief[itemId]?.usage,
      grammar: widget.grammarNotes[itemId],
    );
  }

  Future<void> _loadCurrent() async {
    while (_index < widget.itemIds.length) {
      final w = await _load(widget.itemIds[_index]);
      if (w != null) {
        if (!mounted) return;
        setState(() {
          _word = w;
          _attempts = 0;
          _feedback = null;
          _succeeded = false;
        });
        await widget.speak(w.reading);
        await widget.speakSlow(w.reading);
        return;
      }
      _index++; // Item ohne Lexem: überspringen (Review Focus 4)
    }
    widget.onDone(_wobbly);
  }

  Future<void> _attempt() async {
    final w = _word!;
    final score = await widget.evaluator.evaluate(w.reading);
    if (!mounted) return;
    _attempts++;
    if (score >= widget.threshold) {
      setState(() {
        _succeeded = true;
        _feedback = 'Genau so.';
      });
      return;
    }
    if (_attempts == 1) {
      setState(() => _feedback = 'Fast. Hör noch einmal, ich sage es langsam.');
      await widget.speakSlow(w.reading);
    } else {
      setState(() => _feedback = 'Das nehmen wir später noch einmal.');
    }
  }

  void _next() {
    final w = _word!;
    if (!_succeeded) _wobbly.add(w.itemId);
    _index++;
    widget.onPosition(_index);
    setState(() => _word = null);
    _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    if (w == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final surface = w.bubble?.tokens
            .firstWhere((t) => t.itemId == w.itemId)
            .surface ??
        w.writtenForm;
    return StationFrame(
      station: CafeStation.wirtin,
      light: widget.light,
      voiceLine: 'Setz dich. Das hier hattest du in der Folge:',
      onNext: _next,
      onLater: widget.onLater,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (w.panel != null && w.bubble != null)
              SizedBox(
                key: const ValueKey('wirtin-panel'),
                height: 260,
                child: PanelWithBubble(
                  panel: w.panel!,
                  bubble: w.bubble!,
                  targetSurface: surface,
                  mode: BubbleOverlayMode.highlight,
                ),
              ),
            const SizedBox(height: 16),
            if (w.hasKanji)
              Text(w.writtenForm,
                  key: const ValueKey('wirtin-kanji'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 56)),
            GestureDetector(
              onTap: () => widget.speak(w.reading),
              child: Text(w.reading,
                  key: const ValueKey('wirtin-word'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w.hasKanji ? 28 : 44)),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (var i = 0; i < w.units.length; i++)
                  OutlinedButton(
                    key: ValueKey('wirtin-tile-$i'),
                    onPressed: () => widget.speak(w.units[i].text),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(w.units[i].text, style: const TextStyle(fontSize: 28)),
                        Text(w.units[i].romaji, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(w.meaning,
                key: const ValueKey('wirtin-meaning'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20)),
            if (w.usage != null) ...[
              const SizedBox(height: 12),
              Text(w.usage!, key: const ValueKey('wirtin-usage')),
            ],
            if (w.grammar != null) ...[
              const SizedBox(height: 8),
              Text(w.grammar!,
                  key: const ValueKey('wirtin-grammar'),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('wirtin-mic'),
                  icon: const Icon(Icons.mic),
                  label: const Text('nachsprechen'),
                  onPressed: _succeeded || _attempts >= 2 ? null : _attempt,
                ),
                const SizedBox(width: 12),
                if (_feedback != null)
                  Expanded(
                    child: Text(_feedback!,
                        key: const ValueKey('wirtin-feedback')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/wirtin_station_test.dart`
Expected: PASS (5 Tests). Beim Kanji-Test findet `find.text('えき')` ggf. Wort und Kachel-Text — deshalb `findsWidgets`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/stations/station_frame.dart lib/features/cafe/stations/wirtin_station.dart test/features/cafe/wirtin_station_test.dart
git commit -m "feat(cafe): Wirtin-Station — Wort auflösen, Laut-Kacheln, Nachsprechen"
```

---

### Task 7: Schulmädchen-Station

**Files:**
- Create: `lib/features/cafe/stations/schulmaedchen_station.dart`
- Test: `test/features/cafe/schulmaedchen_station_test.dart`

**Interfaces:**
- Consumes: `KanaKeyboard`, `normalizeKana`, `PanelWithBubble`/`BubbleOverlayMode.blank`, `decompose` (Zerlegung nach Fehlversuch), `LadderReview.submit(item, ReviewResult)`, `LearningDb.getLearnItem('$languageId:lexeme:$id')`, `VisitRecord`, `StationFrame`.
- Produces: `class SchulmaedchenStation extends StatefulWidget { SchulmaedchenStation({required LearningDb db, KnowledgeBridge? bridge, required String languageId, required Episode? episode, required List<String> itemIds, required int startIndex, required Speak speak, required SpeakEvaluator evaluator, required CafeLight light, required void Function(int nextIndex) onPosition, required void Function(List<VisitRecord> records) onDone, required VoidCallback onLater}) }`.
- Keys: `schul-hear-write`, `schul-see-speak`, `schul-listen`, `schul-submit`, `schul-mic`, `schul-write-instead`, `schul-feedback`, `schul-tiles`, `schul-panel`.
- Offline-Ausweg (Spec §8): bei Sehen→Sprechen gibt es „lieber schreiben" (`schul-write-instead`) — das Panel mit ausgeblendetem Wort bleibt, darunter erscheint die Kana-Tastatur; Bewertung wie beim Schreiben. So bleibt die Station ohne Spracherkennung benutzbar, und ein Fehlschlag der Erkennung zwingt nie zu `again`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_summary.dart';
import 'package:nihongo_app/features/cafe/cafe_turn.dart';
import 'package:nihongo_app/features/cafe/stations/schulmaedchen_station.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

class _FakeEvaluator implements SpeakEvaluator {
  final List<double> scores;
  int calls = 0;
  _FakeEvaluator(this.scores);
  @override
  Future<double> evaluate(String target) async => scores[calls++ % scores.length];
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'assets/story/folge01/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！かさ！',
                  'hitArea': [{'x': 0.1, 'y': 0.1}, {'x': 0.5, 'y': 0.1}, {'x': 0.5, 'y': 0.2}, {'x': 0.1, 'y': 0.2}],
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  late LearningDb db;
  setUp(() async {
    db = LearningDb.forTesting();
    for (final (id, concept, gloss, form) in [
      ('lex_ja_ame', 'concept_rain', 'rain', 'あめ'),
      ('lex_ja_kasa', 'concept_umbrella', 'umbrella', 'かさ'),
    ]) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: concept, glossKey: gloss, partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: id, languageId: 'lang_ja', conceptId: concept,
          writtenForm: form, reading: form));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 1);
    }
  });
  tearDown(() => db.close());

  Future<List<String>> results() async =>
      (await db.select(db.reviewLog).get()).map((r) => r.result).toList();

  Future<({List<String> spoken, List<VisitRecord>? records})> pump(
      WidgetTester tester, _FakeEvaluator ev, List<String> ids) async {
    final spoken = <String>[];
    List<VisitRecord>? records;
    await tester.pumpWidget(MaterialApp(
      home: SchulmaedchenStation(
        db: db,
        languageId: 'lang_ja',
        episode: _episode(),
        itemIds: ids,
        startIndex: 0,
        speak: (t) async => spoken.add(t),
        evaluator: ev,
        light: CafeLight.tag,
        onPosition: (_) {},
        onDone: (r) => records = r,
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();
    return (spoken: spoken, records: records);
  }

  Future<void> typeKana(WidgetTester tester, String kana) async {
    for (final c in kana.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
  }

  testWidgets('Position 0 = Hören→Schreiben: Wort wird gesprochen, nicht '
      'gezeigt; richtig getippt → good', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame']);
    expect(find.byKey(const ValueKey('schul-hear-write')), findsOneWidget);
    expect(r.spoken, ['あめ']);
    expect(find.text('あめ'), findsNothing);
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['good']);
    expect(find.byKey(const ValueKey('schul-feedback')), findsOneWidget);
  });

  testWidgets('falsch → nochmal gesprochen + Kacheln; zweiter Versuch richtig '
      '→ hard; zweimal falsch → again, ein Log-Eintrag', (tester) async {
    final r = await pump(tester, _FakeEvaluator([1.0]), ['lex_ja_ame', 'lex_ja_kasa']);
    await typeKana(tester, 'あき');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(r.spoken, ['あめ', 'あめ']);
    expect(find.byKey(const ValueKey('schul-tiles')), findsOneWidget);
    expect(await results(), isEmpty);
    // Eingabe ist geleert; zweiter Versuch
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['hard']);
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    // Position 1 = Sehen→Sprechen für かさ: zweimal nicht erkannt
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    expect(find.text('あめ！___！'), findsOneWidget);
  });

  testWidgets('Sehen→Sprechen: zweimal nicht erkannt → again, es geht weiter; '
      'onDone liefert Records', (tester) async {
    final r = await pump(tester, _FakeEvaluator([0.1, 0.1]), ['lex_ja_kasa', 'lex_ja_ame']);
    // Position 0 ist Hören→Schreiben (かさ): richtig
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), ['good']); // noch nicht bewertet
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'again']);
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(r.records!.map((x) => x.outcome),
        [CafeOutcome.correct, CafeOutcome.wrong]);
    expect(r.records!.first.firstTry, isTrue);
  });

  testWidgets('Sehen→Sprechen: „lieber schreiben" blendet die Tastatur ein; '
      'richtig getippt → good, kein Mikro nötig', (tester) async {
    await pump(tester, _FakeEvaluator([0.0]), ['lex_ja_kasa', 'lex_ja_ame']);
    await typeKana(tester, 'かさ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-see-speak')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schul-write-instead')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schul-panel')), findsOneWidget); // Panel bleibt
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    expect(await results(), ['good', 'good']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/schulmaedchen_station_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

import '../../../core/db/learning_db.dart';
import '../../../core/db/lexeme_lookup.dart';
import '../../../core/ladder/ladder_review.dart';
import '../../../core/pipeline/knowledge_bridge.dart';
import '../../../core/srs/scheduler.dart';
import '../../story/episode.dart';
import '../../story/speak_evaluator.dart';
import '../bubble_overlay.dart';
import '../cafe_debrief.dart';
import '../cafe_scenes.dart';
import '../cafe_summary.dart';
import '../cafe_turn.dart';
import '../cafe_visit.dart';
import '../kana_keyboard.dart';
import '../word_decomposition.dart';
import 'station_frame.dart';

enum _Kind { hearWrite, seeSpeak }

class _Word {
  final String itemId;
  final LearnItem learn;
  final String writtenForm;
  final String reading;
  final StoryPanel? panel;
  final StoryBubble? bubble;
  final String surface;
  const _Word(this.itemId, this.learn, this.writtenForm, this.reading,
      this.panel, this.bubble, this.surface);
}

/// Station 2 „Abfrage" (Spec §3.2). Gerade Position: Hören→Schreiben auf der
/// Kana-Tastatur; ungerade: Sehen→Sprechen mit ausgeblendetem Wort in der
/// Blase. Zwei Versuche; Bewertung 1. Versuch richtig good, 2. hard, sonst
/// again — genau ein `LadderReview.submit` je Wort (Spec §7). Keine Auswahl,
/// kein Selbsteinschätzen (I1).
class SchulmaedchenStation extends StatefulWidget {
  final LearningDb db;
  final KnowledgeBridge? bridge;
  final String languageId;
  final Episode? episode;
  final List<String> itemIds;
  final int startIndex;
  final Speak speak;
  final SpeakEvaluator evaluator;
  final CafeLight light;
  final void Function(int nextIndex) onPosition;
  final void Function(List<VisitRecord> records) onDone;
  final VoidCallback onLater;
  final double threshold;

  const SchulmaedchenStation({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required this.episode,
    required this.itemIds,
    required this.startIndex,
    required this.speak,
    required this.evaluator,
    required this.light,
    required this.onPosition,
    required this.onDone,
    required this.onLater,
    this.threshold = 0.6,
  });

  @override
  State<SchulmaedchenStation> createState() => _SchulmaedchenStationState();
}

class _SchulmaedchenStationState extends State<SchulmaedchenStation> {
  late final LadderReview _ladder =
      LadderReview(widget.db, bridge: widget.bridge);
  int _index = 0;
  _Word? _word;
  String _typed = '';
  int _attempts = 0;
  bool _graded = false;
  String? _feedback;
  bool _showTiles = false;
  bool _writeInstead = false; // Sehen→Sprechen ohne Mikro: Tastatur statt Mikro
  final _records = <VisitRecord>[];

  _Kind get _kind => _index.isEven ? _Kind.hearWrite : _Kind.seeSpeak;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _loadCurrent();
  }

  Future<_Word?> _load(String id) async {
    final found = await loadLexemeWithConcept(widget.db, id);
    final learn = await widget.db.getLearnItem('${widget.languageId}:lexeme:$id');
    if (found == null || learn == null) return null;
    final ep = widget.episode;
    final panel = ep == null ? null : firstAppearancePanel(ep, id);
    StoryBubble? bubble;
    var surface = found.lexeme.writtenForm;
    if (panel != null) {
      for (final b in panel.bubbles) {
        for (final t in b.tokens) {
          if (t.itemId == id) {
            bubble = b;
            surface = t.surface;
            break;
          }
        }
        if (bubble != null) break;
      }
    }
    return _Word(id, learn, found.lexeme.writtenForm, found.lexeme.reading,
        panel, bubble, surface);
  }

  Future<void> _loadCurrent() async {
    while (_index < widget.itemIds.length) {
      final w = await _load(widget.itemIds[_index]);
      if (w != null) {
        if (!mounted) return;
        setState(() {
          _word = w;
          _typed = '';
          _attempts = 0;
          _graded = false;
          _feedback = null;
          _showTiles = false;
          _writeInstead = false;
        });
        if (_kind == _Kind.hearWrite) await widget.speak(w.reading);
        return;
      }
      _index++;
    }
    widget.onDone(List.unmodifiable(_records));
  }

  Future<void> _grade(bool correct) async {
    final w = _word!;
    _attempts++;
    if (correct) {
      final result = _attempts == 1 ? ReviewResult.good : ReviewResult.hard;
      final res = await _ladder.submit(w.learn, result);
      _records.add(VisitRecord(
          itemId: w.itemId, writtenForm: w.writtenForm,
          outcome: CafeOutcome.correct, firstTry: _attempts == 1,
          dueAt: res.scheduleOutput.dueAt));
      if (!mounted) return;
      setState(() {
        _graded = true;
        _feedback = _attempts == 1 ? 'Ha, gewusst!' : 'Siehst du, geht doch.';
      });
      return;
    }
    if (_attempts == 1) {
      setState(() {
        _feedback = 'Nee. Nochmal — aber richtig diesmal.';
        _showTiles = true;
        _typed = '';
      });
      await widget.speak(w.reading);
      return;
    }
    final res = await _ladder.submit(w.learn, ReviewResult.again);
    _records.add(VisitRecord(
        itemId: w.itemId, writtenForm: w.writtenForm,
        outcome: CafeOutcome.wrong, firstTry: false,
        dueAt: res.scheduleOutput.dueAt));
    if (!mounted) return;
    setState(() {
      _graded = true;
      _feedback = 'Das heißt ${w.reading}. Kommt wieder dran.';
    });
  }

  void _submitTyped() {
    final w = _word!;
    _grade(normalizeKana(_typed) == normalizeKana(w.reading));
  }

  Future<void> _attemptSpeak() async {
    final score = await widget.evaluator.evaluate(_word!.reading);
    if (!mounted) return;
    await _grade(score >= widget.threshold);
  }

  void _next() {
    _index++;
    widget.onPosition(_index);
    setState(() => _word = null);
    _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    if (w == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hearWrite = _kind == _Kind.hearWrite;
    return StationFrame(
      station: CafeStation.schulmaedchen,
      light: widget.light,
      voiceLine: hearWrite ? 'Hör zu und schreib es. Schnell!' : 'Was steht da? Sag es. Los.',
      onNext: _graded ? _next : null,
      onLater: widget.onLater,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hearWrite) ...[
              Row(
                key: const ValueKey('schul-hear-write'),
                children: [
                  TextButton.icon(
                    key: const ValueKey('schul-listen'),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('nochmal hören'),
                    onPressed: () => widget.speak(w.reading),
                  ),
                ],
              ),
              if (!_graded) ...[
                KanaKeyboard(value: _typed, onChanged: (v) => setState(() => _typed = v)),
                FilledButton(
                  key: const ValueKey('schul-submit'),
                  onPressed: _typed.isEmpty ? null : _submitTyped,
                  child: const Text('So heißt es'),
                ),
              ],
            ] else ...[
              if (w.panel != null && w.bubble != null)
                SizedBox(
                  key: const ValueKey('schul-panel'),
                  height: 260,
                  child: PanelWithBubble(
                    panel: w.panel!,
                    bubble: w.bubble!,
                    targetSurface: w.surface,
                    mode: BubbleOverlayMode.blank,
                  ),
                ),
              Row(
                key: const ValueKey('schul-see-speak'),
                children: [
                  FilledButton.tonalIcon(
                    key: const ValueKey('schul-mic'),
                    icon: const Icon(Icons.mic),
                    label: const Text('sagen'),
                    onPressed: _graded || _writeInstead ? null : _attemptSpeak,
                  ),
                  const SizedBox(width: 8),
                  if (!_graded && !_writeInstead)
                    TextButton(
                      key: const ValueKey('schul-write-instead'),
                      onPressed: () => setState(() => _writeInstead = true),
                      child: const Text('lieber schreiben'),
                    ),
                ],
              ),
              if (_writeInstead && !_graded) ...[
                KanaKeyboard(value: _typed, onChanged: (v) => setState(() => _typed = v)),
                FilledButton(
                  key: const ValueKey('schul-submit'),
                  onPressed: _typed.isEmpty ? null : _submitTyped,
                  child: const Text('So heißt es'),
                ),
              ],
            ],
            if (_showTiles && !_graded)
              Wrap(
                key: const ValueKey('schul-tiles'),
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final u in decompose(w.reading))
                    Chip(label: Text('${u.text} ${u.romaji}')),
                ],
              ),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_feedback!, key: const ValueKey('schul-feedback')),
              ),
          ],
        ),
      ),
    );
  }
}
```

Hinweis zum zweiten Test: Nach dem ersten Fehlversuch zeigt die Station die Kacheln; die Kacheln enthalten `あ a`, `め me` — nicht `あめ` als Ganzes. `find.text('あめ')` bleibt also leer (Antwort nie verraten, INV-9). Beim Fehlversuch-Feedback nach zwei Fehlern wird das Wort genannt — dann ist schon bewertet.

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/schulmaedchen_station_test.dart`
Expected: PASS (4 Tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/stations/schulmaedchen_station.dart test/features/cafe/schulmaedchen_station_test.dart
git commit -m "feat(cafe): Schulmädchen-Station — Hören→Schreiben, Sehen→Sprechen, zwei Versuche"
```

---

### Task 8: Besuchs-Bildschirm (Raum, Leiste, Ablauf, Fortsetzen, Abschluss)

**Files:**
- Create: `lib/features/cafe/cafe_visit_screen.dart`
- Test: `test/features/cafe/cafe_visit_screen_test.dart`

**Interfaces:**
- Consumes: `planAfterEpisode`, `planFreeVisit`, `StoryProgressStore` (Task 4), `WirtinStation`, `SchulmaedchenStation`, `summaryLines`, `LearningDb.getDueItems/lastReviewResult`, `sceneAsset`, `stammplatzOf`, `CafeMotif.leer`.
- Produces: `class CafeVisitScreen extends StatefulWidget { CafeVisitScreen.afterEpisode({required LearningDb db, KnowledgeBridge? bridge, required String languageId, required Episode episode, required StoryProgressStore store, required Speak speak, required Speak speakSlow, required SpeakEvaluator evaluator, CafeLight? light}); CafeVisitScreen.free({… required List<Episode> episodes, …}) }`.
- Keys: `cafe-visit-room`, `cafe-visit-guest-<station>` (aktiv: Opacity 1, sonst 0.4), `cafe-visit-start`, `cafe-visit-resume`, `cafe-visit-restart`, `cafe-visit-empty`, `cafe-visit-practice-anyway` (nur wenn `planPracticeAnyway` Items liefert), `cafe-visit-summary`, `cafe-visit-summary-line-<i>`, `cafe-visit-leave`.

Ablauf: Raum → (Fortsetzen? „Weitermachen bei der Wirtin?" Ja/Von vorn) → Station für Station (Navigator.push mit eigenem Scaffold) → Abschluss → `markCafeVisitDone` (Weg 1) + `clearCafeVisitPosition`. „Später weiter" in einer Station: Position ist schon über `onPosition` gespeichert; pop zurück in den Raum und Scaffold-Pop (zurück zum Aufrufer).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/cafe_visit_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Always implements SpeakEvaluator {
  final double score;
  _Always(this.score);
  @override
  Future<double> evaluate(String target) async => score;
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0, 'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'x', 'text': 'あめ！かさ！', 'hitArea': [],
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [], 'interactions': [],
            },
          ],
        },
      ],
    });

void main() {
  late LearningDb db;
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    for (final (id, concept, gloss, form) in [
      ('lex_ja_ame', 'concept_rain', 'rain', 'あめ'),
      ('lex_ja_kasa', 'concept_umbrella', 'umbrella', 'かさ'),
    ]) {
      await db.into(db.concepts).insert(ConceptsCompanion.insert(
          id: concept, glossKey: gloss, partOfSpeech: 'noun',
          defaultAssetType: const Value('image')));
      await db.into(db.lexemes).insert(LexemesCompanion.insert(
          id: id, languageId: 'lang_ja', conceptId: concept,
          writtenForm: form, reading: form));
      await db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: 0);
    }
    await store.markCompleted('ep_t');
  });
  tearDown(() => db.close());

  Widget afterEpisode() => MaterialApp(
        home: CafeVisitScreen.afterEpisode(
          db: db, languageId: 'lang_ja', episode: _episode(), store: store,
          speak: (_) async {}, speakSlow: (_) async {},
          evaluator: _Always(1.0), light: CafeLight.tag,
        ),
      );

  Future<void> typeKana(WidgetTester tester, String kana) async {
    for (final c in kana.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
  }

  testWidgets('Raum zeigt vier Gäste, Wirtin aktiv; Start öffnet die Wirtin',
      (tester) async {
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
    for (final g in ['wirtin', 'schulmaedchen', 'vielredner', 'gleichaltrige']) {
      expect(find.byKey(ValueKey('cafe-visit-guest-$g')), findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    expect(find.text('Die Wirtin'), findsOneWidget);
    expect(find.byKey(const ValueKey('wirtin-word')), findsOneWidget);
  });

  testWidgets('Später weiter speichert die Position; Fortsetzen springt dorthin',
      (tester) async {
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next'))); // あめ fertig
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-later')));
    await tester.pumpAndSettle();
    expect(await store.cafeVisitPosition('ep_t'), (station: 0, item: 1));

    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-resume')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-visit-resume')));
    await tester.pumpAndSettle();
    expect(find.text('かさ'), findsWidgets); // zweites Wort, nicht wieder あめ
  });

  testWidgets('ganzer Weg 1: Wirtin → Schulmädchen → Abschluss; Besuch erledigt',
      (tester) async {
    await tester.pumpWidget(afterEpisode());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-visit-start')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
      await tester.pumpAndSettle();
    }
    // Schulmädchen: あめ Hören→Schreiben, かさ Sehen→Sprechen (Always 1.0)
    expect(find.text('Das Schulmädchen'), findsOneWidget);
    await typeKana(tester, 'あめ');
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schul-mic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-station-next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-summary')), findsOneWidget);
    expect(find.text('あめ und かさ sitzen.'), findsOneWidget);
    expect((await db.select(db.reviewLog).get()).length, 2); // beide bewertet
    expect(await store.isCafeVisitPending('ep_t'), isFalse);
    expect(await store.cafeVisitPosition('ep_t'), isNull);
  });

  testWidgets('freier Besuch ohne fällige Items: Wirtin wischt den Tresen, '
      'kein Start-Knopf', (tester) async {
    final empty = LearningDb.forTesting();
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.free(
        db: empty, languageId: 'lang_ja', episodes: [_episode()], store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    expect(find.text('Die Wirtin wischt den Tresen und nickt dir zu.'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-start')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-visit-practice-anyway')), findsNothing);
    await empty.close();
  });

  testWidgets('freier Besuch, nichts fällig, aber bekannte Wörter: freiwillige '
      'Runde beim Schulmädchen', (tester) async {
    // Beide Items kennen wir schon (Sprosse 2) und sie sind erst morgen fällig.
    for (final id in ['lex_ja_ame', 'lex_ja_kasa']) {
      final item = (await db.getLearnItem('lang_ja:lexeme:$id'))!;
      await db.update(db.learnItems).replace(item.copyWith(
          masteryRung: 2, dueAt: DateTime.now().add(const Duration(days: 1))));
    }
    await tester.pumpWidget(MaterialApp(
      home: CafeVisitScreen.free(
        db: db, languageId: 'lang_ja', episodes: [_episode()], store: store,
        speak: (_) async {}, speakSlow: (_) async {},
        evaluator: _Always(1.0), light: CafeLight.tag,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cafe-visit-practice-anyway')));
    await tester.pumpAndSettle();
    expect(find.text('Das Schulmädchen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_visit_screen_test.dart`
Expected: FAIL.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import '../story/speak_evaluator.dart';
import '../story/story_progress_store.dart';
import 'cafe_debrief.dart';
import 'cafe_scenes.dart';
import 'cafe_summary.dart';
import 'cafe_visit.dart';
import 'stations/schulmaedchen_station.dart';
import 'stations/station_frame.dart';
import 'stations/wirtin_station.dart';

/// Der Café-Besuch (Spec §2): ein Raum mit den vier Gästen und einer Leiste,
/// dann Station für Station. Weg 1 (`afterEpisode`) nimmt die Wörter der
/// Folge, Weg 2 (`free`) die fälligen Items. „Später weiter" speichert
/// Station und Item; der nächste Einstieg fragt nach Fortsetzen. Am Ende der
/// Abschluss der Wirtin in Worten — kein Zähler (INV-10).
class CafeVisitScreen extends StatefulWidget {
  final LearningDb db;
  final KnowledgeBridge? bridge;
  final String languageId;
  final Episode? episode; // Weg 1
  final List<Episode> episodes; // Weg 2: Panel-Kontext je Wort
  final StoryProgressStore store;
  final Speak speak;
  final Speak speakSlow;
  final SpeakEvaluator evaluator;
  final CafeLight? light;
  final Map<String, String> grammarNotes;

  const CafeVisitScreen.afterEpisode({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required Episode this.episode,
    required this.store,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    this.light,
    this.grammarNotes = const {},
  }) : episodes = const [];

  const CafeVisitScreen.free({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required this.episodes,
    required this.store,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    this.light,
    this.grammarNotes = const {},
  }) : episode = null;

  String get visitId => episode?.id ?? 'free';

  @override
  State<CafeVisitScreen> createState() => _CafeVisitScreenState();
}

class _CafeVisitScreenState extends State<CafeVisitScreen> {
  CafeVisitPlan? _plan;
  CafeVisitPlan? _practice; // freiwillige Runde, wenn nichts fällig ist
  ({int station, int item})? _resume;
  late CafeLight _light;
  final _records = <VisitRecord>[];
  Set<String> _wobbly = const {};
  List<String>? _summary;

  @override
  void initState() {
    super.initState();
    _light = widget.light ?? lightFor(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    final ep = widget.episode;
    CafeVisitPlan plan;
    CafeVisitPlan? practice;
    if (ep != null) {
      plan = planAfterEpisode(ep, wobbly: _wobbly);
    } else {
      final due = await widget.db.getDueItems(widget.languageId, limit: 500);
      final last = <String, String?>{
        for (final i in due) i.id: await widget.db.lastReviewResult(i.id),
      };
      plan = planFreeVisit(due, last);
      if (plan.stations.isEmpty) {
        final all = await widget.db.learnItemsFor(widget.languageId);
        final p = planPracticeAnyway(all, seed: DateTime.now().day);
        if (p.stations.isNotEmpty) practice = p;
      }
    }
    final resume = await widget.store.cafeVisitPosition(widget.visitId);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _practice = practice;
      _resume = resume != null && resume.station < plan.stations.length ? resume : null;
    });
  }

  /// Die Folge, aus der ein Wort stammt (Weg 2) — für Panel und Erklärung.
  Episode? _episodeFor(String itemId) =>
      widget.episode ?? episodeIntroducing(widget.episodes, itemId);

  Future<void> _run({required int fromStation, required int fromItem}) async {
    final plan = _plan!;
    var left = false;
    for (var s = fromStation; s < plan.stations.length && !left; s++) {
      final sp = plan.stations[s];
      // Stationen 3/4 baut Plan B; bis dahin stehen sie nie im Plan — und
      // falls doch, werden sie übersprungen statt eine leere Seite zu zeigen.
      if (sp.station == CafeStation.vielredner ||
          sp.station == CafeStation.gleichaltrige) {
        continue;
      }
      final start = s == fromStation ? fromItem : 0;
      // Plan A: Wörter einer Station kommen aus einer Folge (Weg 1) oder
      // je Wort aus seiner Folge (Weg 2, erste Folge des ersten Worts).
      final episode = widget.episode ??
          (sp.itemIds.isEmpty ? null : _episodeFor(sp.itemIds.first));
      final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => switch (sp.station) {
          CafeStation.wirtin => WirtinStation(
              db: widget.db,
              episode: episode,
              itemIds: sp.itemIds,
              startIndex: start,
              speak: widget.speak,
              speakSlow: widget.speakSlow,
              evaluator: widget.evaluator,
              grammarNotes: widget.grammarNotes,
              light: _light,
              onPosition: (i) => widget.store.saveCafeVisitPosition(widget.visitId, s, i),
              onDone: (w) {
                _wobbly = w;
                Navigator.of(context).pop(true);
              },
              onLater: () => Navigator.of(context).pop(false),
            ),
          CafeStation.schulmaedchen => SchulmaedchenStation(
              db: widget.db,
              bridge: widget.bridge,
              languageId: widget.languageId,
              episode: episode,
              itemIds: sp.itemIds,
              startIndex: start,
              speak: widget.speak,
              evaluator: widget.evaluator,
              light: _light,
              onPosition: (i) => widget.store.saveCafeVisitPosition(widget.visitId, s, i),
              onDone: (r) {
                _records.addAll(r);
                Navigator.of(context).pop(true);
              },
              onLater: () => Navigator.of(context).pop(false),
            ),
          // oben übersprungen; der Switch muss trotzdem vollständig sein
          CafeStation.vielredner || CafeStation.gleichaltrige => const SizedBox(),
        },
      ));
      if (done != true) {
        left = true;
        break;
      }
      if (s + 1 < plan.stations.length) {
        await widget.store.saveCafeVisitPosition(widget.visitId, s + 1, 0);
      }
      // Weg 1: nach der Wirtin die Schulmädchen-Liste neu nach „wackelig" ordnen.
      if (widget.episode != null && sp.station == CafeStation.wirtin) {
        _plan = planAfterEpisode(widget.episode!, wobbly: _wobbly);
      }
    }
    if (!mounted) return;
    if (left) {
      // „Später weiter": zurück zum Aufrufer (Lesen-Tab bzw. Café-Tab-Shell).
      // maybePop, weil die Shell-Route des Café-Tabs die einzige sein kann.
      await Navigator.of(context).maybePop();
      return;
    }
    await widget.store.clearCafeVisitPosition(widget.visitId);
    if (widget.episode != null) await widget.store.markCafeVisitDone(widget.episode!.id);
    if (!mounted) return;
    setState(() => _summary = summaryLines(_records, now: DateTime.now()));
  }

  Widget _guest(CafeStation s, {required bool active}) => Opacity(
        key: ValueKey('cafe-visit-guest-${s.name}'),
        opacity: active ? 1 : 0.4,
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Image.asset(
                sceneAsset(stammplatzOf(guestOf(s)), _light),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF2A3035)),
              ),
            ),
            const SizedBox(height: 4),
            Text(stationTitles[s]!, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final summary = _summary;
    if (summary != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Die Wirtin')),
        body: ListView(
          key: const ValueKey('cafe-visit-summary'),
          padding: const EdgeInsets.all(24),
          children: [
            for (var i = 0; i < summary.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(summary[i],
                    key: ValueKey('cafe-visit-summary-line-$i'),
                    style: const TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('cafe-visit-leave'),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(widget.episode != null ? 'Zurück zur Folge' : 'Café verlassen'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Café')),
      body: plan == null
          ? const Center(child: CircularProgressIndicator())
          : plan.stations.isEmpty
              ? ListView(
                  key: const ValueKey('cafe-visit-empty'),
                  children: [
                    Image.asset(sceneAsset(CafeMotif.wirtinTresen, _light),
                        height: 200, width: double.infinity, fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            Container(height: 200, color: const Color(0xFF2A3035))),
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Die Wirtin wischt den Tresen und nickt dir zu.',
                          textAlign: TextAlign.center),
                    ),
                    if (_practice != null)
                      Center(
                        child: TextButton(
                          key: const ValueKey('cafe-visit-practice-anyway'),
                          onPressed: () {
                            _plan = _practice;
                            _run(fromStation: 0, fromItem: 0);
                          },
                          child: const Text('Trotzdem eine Runde mit dem Schulmädchen'),
                        ),
                      ),
                  ],
                )
              : ListView(
                  key: const ValueKey('cafe-visit-room'),
                  children: [
                    Image.asset(sceneAsset(CafeMotif.leer, _light),
                        height: 200, width: double.infinity, fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            Container(height: 200, color: const Color(0xFF2A3035))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final s in CafeStation.values)
                            _guest(s,
                                active: s == (_resume == null
                                    ? plan.stations.first.station
                                    : plan.stations[_resume!.station].station)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.episode != null
                            ? 'Es geht reihum: erst die Wirtin, dann die anderen.'
                            : 'Heute sitzen die da, bei denen etwas liegt.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_resume != null) ...[
                      Center(
                        child: FilledButton(
                          key: const ValueKey('cafe-visit-resume'),
                          onPressed: () => _run(
                              fromStation: _resume!.station, fromItem: _resume!.item),
                          child: Text(
                              'Weitermachen bei ${stationTitles[plan.stations[_resume!.station].station]!.toLowerCase().replaceFirst(RegExp('^(die|das|der) '), '')}'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          key: const ValueKey('cafe-visit-restart'),
                          onPressed: () => _run(fromStation: 0, fromItem: 0),
                          child: const Text('Von vorn'),
                        ),
                      ),
                    ] else
                      Center(
                        child: FilledButton(
                          key: const ValueKey('cafe-visit-start'),
                          onPressed: () => _run(fromStation: 0, fromItem: 0),
                          child: const Text('Setz dich'),
                        ),
                      ),
                  ],
                ),
    );
  }
}
```

Der Fortsetzen-Knopf sagt „Weitermachen bei Wirtin" / „… Schulmädchen" — die Artikel werden entfernt, damit es natürlich klingt.

- [ ] **Step 4: Run test to verify it passes**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_visit_screen_test.dart`
Expected: PASS (5 Tests). Für den Fortsetzen-Test: `find.text('かさ')` findet Wort und ggf. Kachel; deshalb `findsWidgets`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_visit_screen.dart test/features/cafe/cafe_visit_screen_test.dart
git commit -m "feat(cafe): Besuchs-Bildschirm — Raum, Stationen reihum, Später weiter, Abschluss"
```

---

### Task 9: Einstiege verdrahten, altes Café abreißen

**Files:**
- Modify: `lib/features/cafe/cafe_route.dart` (ganze Datei ersetzen)
- Modify: `lib/features/story/story_route.dart:123-125` (Kommentar + Aufruf bleiben; `CafeRoute(debriefEpisodeId: episode.id)` → `CafeRoute(episodeId: episode.id)`)
- Modify: `lib/features/story/story_progress_store.dart` — die Methoden `debriefIndex`, `saveDebriefIndex`, `markDebriefDone`, `isDebriefDone`, `isDebriefPending` entfernen
- Delete: `lib/features/cafe/cafe_screen.dart`, `cafe_debrief_screen.dart`, `cafe_debrief_card.dart`, `cafe_turn_screen.dart`, `cafe_speaker_plan.dart`
- Delete: `test/features/cafe/cafe_screen_test.dart`, `cafe_screen_debrief_test.dart`, `cafe_debrief_screen_test.dart`, `cafe_debrief_screen_scene_test.dart`, `cafe_debrief_screen_voices_test.dart`, `cafe_debrief_card_test.dart`, `cafe_turn_screen_test.dart`, `cafe_turn_screen_explain_test.dart`, `cafe_turn_screen_queue_test.dart`, `cafe_turn_screen_scenes_test.dart`, `cafe_turn_screen_voices_test.dart`, `cafe_speaker_plan_test.dart`, `cafe_route_debrief_test.dart`
- Modify: `test/features/cafe/cafe_route_test.dart` (neu schreiben), `test/features/cafe/cafe_debrief_test.dart` (nur Tests zu `loadDebriefCard`/`DebriefCardContent` entfernen, falls diese Symbole mit der Karte fallen — `debriefOrder`, `firstAppearancePanel`, `episodeIntroducing`, `debriefItemsFor` bleiben), `test/features/cafe/cafe_guest_script_test.dart` und `cafe_inv9_test.dart` (prüfen, ob sie `CafeExerciseKind`/`kindForRung` brauchen — die bleiben in `cafe_turn.dart`, nichts zu ändern)
- Modify: `lib/features/cafe/cafe_debrief.dart` — `DebriefCardContent` + `loadDebriefCard` entfernen (einzige Nutzer waren die Karte)
- Test: `test/features/cafe/cafe_route_test.dart`

**Interfaces:**
- Produces: `class CafeRoute extends ConsumerWidget { const CafeRoute({String? episodeId}) }` — mit `episodeId` und `isCafeVisitPending(episodeId)` → `CafeVisitScreen.afterEpisode`, sonst `CafeVisitScreen.free`. Dienste: `speak: TtsService.instance.speak`, `speakSlow: TtsService.instance.speakSlow`, `evaluator: SttSpeakEvaluator()`.

- [ ] **Step 1: Write the failing test**

`test/features/cafe/cafe_route_test.dart` (ersetzt die alte Datei):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';
import 'package:nihongo_app/features/story/episode_registry.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningDb db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = LearningDb.forTesting();
  });
  tearDown(() => db.close());

  Widget app(Widget child) => ProviderScope(
        overrides: [learningDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: child),
      );

  testWidgets('ohne Folge: freier Besuch (hier leer)', (tester) async {
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
  });

  testWidgets('mit beendeter Folge: Weg 1 mit dem Raum der vier Gäste',
      (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await tester.pumpWidget(app(CafeRoute(episodeId: episode.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
  });

  testWidgets('mit Folge, aber Besuch schon erledigt: freier Besuch',
      (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await store.markCafeVisitDone(episode.id);
    await tester.pumpWidget(app(CafeRoute(episodeId: episode.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
  });
}
```

Falls `storyEpisodesProvider` nicht ohne weitere Overrides lesbar ist (prüfen in `episode_registry.dart`), die Folge über `loadFolge01()` bzw. den dort verwendeten Loader holen.

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/cafe/cafe_route_test.dart`
Expected: FAIL — `episodeId` unbekannt / alte Screens.

- [ ] **Step 3: Write minimal implementation**

`lib/features/cafe/cafe_route.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/tts_service.dart';
import '../story/episode.dart';
import '../story/episode_registry.dart';
import '../story/speak_evaluator.dart';
import '../story/story_progress_store.dart';
import 'cafe_visit_screen.dart';

/// Was die Route wissen muss: der Fortschritts-Store und ob für
/// [episodeId] ein Besuch nach der Folge offen ist (Spec §2, Weg 1).
final cafeVisitProvider = FutureProvider.autoDispose
    .family<({StoryProgressStore store, Episode? pending}), String?>(
        (ref, episodeId) async {
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  if (episodeId == null) return (store: store, pending: null);
  final episodes = ref.watch(storyEpisodesProvider);
  for (final e in episodes) {
    if (e.id == episodeId && await store.isCafeVisitPending(e.id)) {
      return (store: store, pending: e);
    }
  }
  return (store: store, pending: null);
});

/// Einstieg ins Café: mit [episodeId] (Endkarte „Ins Café") Weg 1, wenn der
/// Besuch dieser Folge noch offen ist; sonst Weg 2 (Café-Tab, freier
/// Besuch). Dienste: TTS, Spracherkennung — die Stationen laufen ohne sie
/// weiter, nur ohne Ton bzw. ohne Erkennung.
class CafeRoute extends ConsumerWidget {
  final String? episodeId;
  const CafeRoute({super.key, this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final episodes = ref.watch(storyEpisodesProvider);
    final deps = ref.watch(cafeVisitProvider(episodeId));
    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Café nicht verfügbar:\n$e', textAlign: TextAlign.center)),
      ),
      data: (d) {
        final pending = d.pending;
        if (pending != null) {
          return CafeVisitScreen.afterEpisode(
            db: db,
            bridge: bridge,
            languageId: 'lang_ja',
            episode: pending,
            store: d.store,
            speak: (t) => TtsService.instance.speak(t),
            speakSlow: (t) => TtsService.instance.speakSlow(t),
            evaluator: SttSpeakEvaluator(),
          );
        }
        return CafeVisitScreen.free(
          db: db,
          bridge: bridge,
          languageId: 'lang_ja',
          episodes: episodes,
          store: d.store,
          speak: (t) => TtsService.instance.speak(t),
          speakSlow: (t) => TtsService.instance.speakSlow(t),
          evaluator: SttSpeakEvaluator(),
        );
      },
    );
  }
}
```

`story_route.dart` Zeile 124: `CafeRoute(episodeId: episode.id)`; den Kommentar davor auf „Besuch nach der Folge" umformulieren (`debriefEpisodeId` kommt nicht mehr vor).

`grammarNotes` bleibt in Plan A leer (`const {}`, Standard in `CafeVisitScreen`); die Notizen je Wort kommen mit `CafeContent` in Plan B (Spec §5.2/§5.3). Die Wirtin zeigt den Grammatik-Block nur, wenn eine Notiz da ist.

Dann die Dateien löschen (`git rm`), `DebriefCardContent`/`loadDebriefCard` aus `cafe_debrief.dart` entfernen, die Debrief-Methoden aus `StoryProgressStore` entfernen und die davon abhängigen Tests in `cafe_debrief_test.dart` löschen. Danach: `~/flutter/bin/flutter analyze` — jede verbliebene Referenz auf gelöschte Symbole beheben (nicht zurückbauen).

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter analyze --no-fatal-infos | grep -E "error •" ; ~/flutter/bin/flutter test test/features/cafe/ test/features/story/`
Expected: keine `error •`; alle Tests grün.

- [ ] **Step 5: Commit**

```bash
git add -u lib/features/cafe lib/features/story/story_route.dart lib/features/story/story_progress_store.dart test/features/cafe test/features/story
git commit -m "feat(cafe): Einstiege Weg 1/Weg 2 auf den Besuch umgestellt; alte Nachbesprechung und Abfrage entfernt"
```

(`git add -u` nimmt nur bereits verfolgte Dateien unter den genannten Pfaden — `android/gradle.properties` bleibt draußen, weil es nicht genannt ist.)

---

### Task 10: Vollsuite, Emulator, S23, Draft-PR

**Files:** keine neuen. `docs/superpowers/specs/2026-10-08-cafe-uebungsraum-design.md` §10: Vermerk „Plan A gebaut <Datum>".

- [ ] **Step 1: Vollsuite und Analyzer auf dem NUC**

```bash
~/flutter/bin/flutter analyze --no-fatal-infos | tail -3
~/flutter/bin/flutter test --reporter compact 2>&1 | tail -3
```

Expected: 0 `error •`; „+N −8" mit den 8 bekannten unter `test/mining_packs/ja/`.

- [ ] **Step 2: Emulator auf dem NUC** (Notiz „Android-Build + Emulator auf dem NUC"): `~/bin/emu-nuc.sh`, `~/flutter/bin/flutter build apk --debug --build-number=2011`, `adb -e install -r build/app/outputs/flutter-apk/app-debug.apk`, `adb -e shell pm clear com.softbrew.nihongo_app`. Weg: 2× Continue (539,2150) → „starting from zero" (539,1182) → Lesen (230,2170) → „Folge 1: Regen" (820,1950) → Titelkarte → bis Endkarte → „Ins Café" (540,1243). Screenshots: Raum, Wirtin (あめ, 傘), Kacheln-Tipp, Schulmädchen Hören→Schreiben mit Tastatur, Sehen→Sprechen mit ausgeblendetem Wort, Abschluss; dann Café-Tab (freier Besuch). Bogen nach `~/cafe-a-emulator.png` und Galerie-Seite aktualisieren.

Prüfen: keine Zahl in der Leiste; „Später weiter" mitten im Schulmädchen → Café-Tab → „Weitermachen bei Schulmädchen" springt zum richtigen Wort.

- [ ] **Step 3: S23** — APK per `scp` auf den Laptop (`~/agent-test-checkouts/nihongo-cafe-a-2011.apk`), `ssh laptop adb -s RFCW220PB7W install -r …` auf `Success` prüfen. Prüfliste für Uli: Nachsprechen bei der Wirtin (echtes Mikro), Sehen→Sprechen beim Schulmädchen, Kana-Tastatur mit Daumen.

- [ ] **Step 4: Draft-PR**

```bash
git push -u origin impl/cafe-uebungsraum-a
gh pr create --draft --base design/cafe-uebungsraum --title "feat(cafe): Übungsraum Plan A — Raum, Wirtin (Auflösen), Schulmädchen (Abfrage)" --body-file <datei>
```

Inhalt der Body-Datei: Überschrift „Plan A der Spec Café als Übungsraum (#61)"; Abschnitt „Was drin ist" mit je einer Zeile zu Raum und Stationsleiste, Wirtin (Auflösen, Laut-Kacheln, Nachsprechen), Schulmädchen (Hören→Schreiben mit Kana-Tastatur, Sehen→Sprechen, „lieber schreiben"), Fortsetzen, Abschluss in Worten, freiwillige Runde, Abriss der alten Nachbesprechung; Abschnitt „Prüfung" mit Vollsuite-Zahl „+N −8", Analyzer, Emulator-Bogen `~/cafe-a-emulator.png`, S23-Build-Nummer; Abschnitt „Offen" mit „Plan B: alter Mann, Gleichaltrige, Folge-01-Inhalte, Grammatiknotizen"; Fußzeile `🤖 Generated with [Claude Code](https://claude.com/claude-code)` und die Session-URL aus den Global Constraints.
