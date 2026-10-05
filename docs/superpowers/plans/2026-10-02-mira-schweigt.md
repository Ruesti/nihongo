# Mira schweigt — Implementation Plan (Plan 1 von 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mira spricht in Folge 01 kein Japanisch mehr; vier stumme Momente („…“-Blasen) ersetzen ihre Zeilen, die Nebenfiguren tragen die Wort-Dichte, der Validator erzwingt die Mira-Regel für alle Folgen.

**Architecture:** Zwei neue Validator-Regeln (INV-18/19) und eine neue Interaktionsart `silent` im Episodenschema. Folge 01 bekommt die Daten aus Drehbuch V3; die Bilder werden nur neu gelettert (Layout-Datei → `letter_folge01.py` → `gen_layout_dart.py`), nicht neu gerendert. Der Reader lässt die „…“-Blase inert.

**Tech Stack:** Flutter/Dart (`flutter_test`), Python 3 + Pillow (Lettering, NUC), Folgendaten als Dart-Map.

**Spec:** `docs/superpowers/specs/2026-10-02-mira-schweigt-erzaehl-mal-cafe-manga-design.md` (§3, §4, §7, §8, §13; §12 Plan 1)

**Basis:** frischer Branch `impl/mira-schweigt` von `origin/main` (08fd5a3 oder neuer). Die Spec liegt auf `design/mira-schweigt-cafe-manga` (PR #58); beim Start die Spec-Datei und diesen Plan per `git checkout origin/design/mira-schweigt-cafe-manga -- docs/superpowers/specs/2026-10-02-mira-schweigt-erzaehl-mal-cafe-manga-design.md docs/superpowers/plans/2026-10-02-mira-schweigt.md` mitnehmen.

## Global Constraints

- Mira = `speakerId: 'protagonist'`. Die stumme Blase hat exakt den Text `…` (U+2026) und keine Tokens.
- Kana/Kanji-Erkennung im Validator: Unicode-Bereiche `぀-ヿ` (Hiragana, Katakana) und `一-鿿` (CJK).
- Verstöße brechen den Content-Build (`validateEpisode` wirft `StoryValidationException`), nie die Laufzeit.
- Dichte Folge 01 V3: gehörte Tokens ≥ 44, gehörte Tokens + Interaktionsziele ≥ 50, jedes Budget-Wort ≥ 2.
- Panels werden NICHT neu gerendert. Ungeletterte Master: auf der GPU-Box unter `~/comfy_f01/final/*.jpg` (22 Dateien). Vor Task 5 nach `build/f01_raw/` holen: `mkdir -p build/f01_raw && scp 'pc:~/comfy_f01/final/*.jpg' build/f01_raw/`. Gegenprobe: unverändertes Layout lettert alle 28 Dateien bytegleich zu `assets/story/folge01/` (am 2.10. so geprüft).
- Tests: einzelne Testdateien auf dem NUC mit `~/flutter/bin/flutter test <datei>`; die Vollsuite auf der GPU-Box (`ssh pc`, Flutter unter `~/development/flutter/bin`, Repo `~/projects/nihongo`). Grün heißt „+N −8“: die 8 Native-Tokenizer-Tests unter `test/mining_packs/ja/` sind vorbestehend rot.
- Deutsche Texte wie im Spec-Wortlaut; keine Zähler, keine Häkchen (INV-10).
- PR #59 (Notizbuch-Wörterkarte) baut den Blasen-Tipp im Reader um. Wer zuerst landet, ist egal: die „…“-Blase darf in KEINER Fassung eine Aktion auslösen (weder Vorlesen noch Wörterkarte). Landet #59 zuerst, gilt Task 3 sinngemäß für deren Tipp-Handler.

## Review Focus

1. **Tipp auf die „…“-Blase** — nichts passiert: kein Vorlesen von „…“, keine Wörterkarte, kein Fußzeilen-Eintrag; der Tipp fällt zum Weiterblättern durch. Test in Task 3.
2. **Lettering-Verstöße nach Textänderung** — längere Blasen (P3, P5) unterschreiten die Mindest-Schrift oder treffen ein Gesicht; das Lettering muss vorher abbrechen, nicht still verkleinern. Abgedeckt durch `validate()` in Task 5 (Abbruch bei jedem Verstoß).
3. **Layout und Folge laufen auseinander** (Blasenzahl/Reihenfolge je Panel) — Layout-Konsistenztest muss rot werden. Test in Task 5 (bestehender `folge_01_layout_test.dart` läuft mit).
4. **Spätere Folge lässt Mira ein Wort der eigenen Folge sagen** — Validator mit `priorItemIds` meldet INV-18. Test in Task 1.
5. **Sprechmoment für ein nie gehörtes Wort** — INV-19 meldet. Test in Task 1.

---

## File Structure

| Datei | Verantwortung | Task |
|---|---|---|
| `lib/features/story/episode.dart` | `InteractionType.silent`, `StoryBubble.isSilence` | 1 |
| `lib/features/story/episode_validator.dart` | INV-18, INV-19, Regeln für stumme Momente | 1, 2 |
| `test/features/story/episode_validator_mira_test.dart` (neu) | Negativ- und Positivfälle der neuen Regeln | 1, 2 |
| `lib/features/story/story_reader_screen.dart` | „…“-Blase inert | 3 |
| `test/features/story/story_reader_silence_test.dart` (neu) | Reader-Verhalten der „…“-Blase | 3 |
| `docs/story/DREHBUCH_FOLGE_01_V3.md` (neu), `docs/story/STAFFEL_1_DIE_ADRESSE.md` | Drehbuch V3, Format-Regel | 4 |
| `lib/features/story/episodes/folge_01_regen.dart` | Folge-01-Daten V3 | 4 |
| `test/features/story/folge_01_dichte_test.dart`, `folge_01_mira_test.dart` (neu) | Dichte-Bilanz V3, Mira-Regel an Folge 01 | 4 |
| `tool/comic/folge01_layout.json`, `lib/features/story/episodes/folge_01_layout.g.dart`, `assets/story/folge01/*.jpg` | Blasen und Lettering | 5 |

---

### Task 1: Schema `silent` + Validator INV-18/INV-19

**Files:**
- Modify: `lib/features/story/episode.dart` (enum `InteractionType`, Klasse `StoryBubble`)
- Modify: `lib/features/story/episode_validator.dart` (Signatur `validateEpisode`, neue Prüfblöcke vor `if (violations.isNotEmpty)`)
- Test: `test/features/story/episode_validator_mira_test.dart` (neu)

**Interfaces:**
- Produces: `enum InteractionType { reveal, listen, speak, trace, dictionary, silent }`; `bool StoryBubble.isSilence` (true ⇔ `tokens.isEmpty && text.trim() == '…'`); `void validateEpisode(Episode episode, {Set<String> priorItemIds = const {}})`; Konstante `const String kProtagonist = 'protagonist';` in `episode.dart`.

- [ ] **Step 1: Write the failing test**

`test/features/story/episode_validator_mira_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

/// Minimale Folge: zwei Wörter im Budget, jedes zweimal von anderen gehört.
Map<String, dynamic> _episode({
  List<Map<String, dynamic>> extraBubbles = const [],
  List<Map<String, dynamic>> interactions = const [],
}) =>
    {
      'id': 'ep_test',
      'locale': 'ja',
      'title': 'Test',
      'budget': {
        'items': [
          {'id': 'lex_a', 'refType': 'lexeme'},
          {'id': 'lex_b', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'x.jpg',
              'bubbles': [
                {
                  'speakerId': 'passant',
                  'text': 'あ、あ。い、い',
                  'hitArea': [],
                  'tokens': [
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'い', 'itemId': 'lex_b'},
                    {'surface': 'い', 'itemId': 'lex_b'},
                  ],
                },
                ...extraBubbles,
              ],
              'thoughts': [],
              'interactions': interactions,
              'notes': '',
            },
          ],
        },
      ],
    };

Matcher _violation(String fragment) => throwsA(isA<StoryValidationException>()
    .having((e) => e.violations.join('\n'), 'violations', contains(fragment)));

void main() {
  test('Grundfolge ist gültig', () {
    expect(() => validateEpisode(Episode.fromJson(_episode())), returnsNormally);
  });

  group('INV-18 Mira spricht nur, was sie schon kann', () {
    test('Mira-Token aus dem eigenen Budget ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': '…あ',
          'hitArea': [],
          'tokens': [
            {'surface': 'あ', 'itemId': 'lex_a'},
          ],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });

    test('Mira-Token aus einer früheren Folge ist erlaubt (auch für INV-3)',
        () {
      // Ein wiederverwendetes Wort steht nicht im Budget der neuen Folge
      // (Café-Spec §5.1); INV-3 und INV-18 akzeptieren es über priorItemIds.
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'う',
          'hitArea': [],
          'tokens': [
            {'surface': 'う', 'itemId': 'lex_alt'},
          ],
        },
      ]));
      expect(() => validateEpisode(ep, priorItemIds: {'lex_alt'}),
          returnsNormally);
      expect(() => validateEpisode(ep), _violation('INV-3'));
    });

    test('Kana außerhalb der Tokens ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'え？',
          'hitArea': [],
          'tokens': [],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });

    test('Token ohne itemId bei Mira ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        {
          'speakerId': 'protagonist',
          'text': 'え',
          'hitArea': [],
          'tokens': [
            {'surface': 'え', 'itemId': null},
          ],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('INV-18'));
    });
  });

  group('INV-19 Mira spricht nur nach, was sie gehört hat', () {
    test('Sprechziel, das niemand vorher sagt, ist ein Verstoß', () {
      final json = _episode(interactions: [
        {
          'type': 'speak',
          'diegetic': true,
          'target': 'う',
          'targetItemIds': ['lex_c'],
        },
      ]);
      (json['budget'] as Map)['items'] = [
        ...((json['budget'] as Map)['items'] as List),
        {'id': 'lex_c', 'refType': 'lexeme', 'singleton': true},
      ];
      expect(() => validateEpisode(Episode.fromJson(json)), _violation('INV-19'));
    });

    test('Sprechziel, das vorher eine andere Figur sagt, ist erlaubt', () {
      final ep = Episode.fromJson(_episode(interactions: [
        {
          'type': 'speak',
          'diegetic': true,
          'target': 'あ',
          'targetItemIds': ['lex_a'],
        },
      ]));
      expect(() => validateEpisode(ep), returnsNormally);
    });
  });

  test('InteractionType.silent wird aus JSON gelesen', () {
    final it = StoryInteraction.fromJson(
        {'type': 'silent', 'diegetic': true, 'target': 'あ'});
    expect(it.type, InteractionType.silent);
  });

  test('isSilence erkennt nur die tokenlose „…“-Blase', () {
    StoryBubble b(String text, List<Map<String, dynamic>> tokens) =>
        StoryBubble.fromJson(
            {'speakerId': 'protagonist', 'text': text, 'hitArea': [], 'tokens': tokens});
    expect(b('…', []).isSilence, isTrue);
    expect(b(' … ', []).isSilence, isTrue);
    expect(b('…あ', [{'surface': 'あ', 'itemId': 'lex_a'}]).isSilence, isFalse);
    expect(b('みなみまち駅', []).isSilence, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/story/episode_validator_mira_test.dart`
Expected: FAIL — Kompilierfehler `priorItemIds` / `isSilence` / `silent` unbekannt.

- [ ] **Step 3: Write minimal implementation**

In `lib/features/story/episode.dart`:

```dart
/// Sprecher-Id der Protagonistin Mira (Spec Mira schweigt §3.1).
const String kProtagonist = 'protagonist';

enum InteractionType { reveal, listen, speak, trace, dictionary, silent }
```

In `class StoryBubble` (nach `hitAreaFor`):

```dart
  /// Die stumme Blase eines stummen Moments: „…“, keine Tokens (Spec §4.2).
  /// Inert im Reader; das Café zeichnet später das Wort hinein.
  bool get isSilence => tokens.isEmpty && text.trim() == '…';
```

In `lib/features/story/episode_validator.dart`, Signatur:

```dart
void validateEpisode(Episode episode, {Set<String> priorItemIds = const {}}) {
```

Doc-Kommentar oben ergänzen: „INV-18/INV-19 (Spec Mira schweigt §3.1): `priorItemIds` sind die Budget-Ids aller früheren Folgen. Ein Token mit einer dieser Ids ist auch für INV-3 erlaubt (wiederverwendete Wörter stehen nicht im Budget der neuen Folge).“

In der INV-3-Prüfung die Bedingung erweitern:

```dart
        if (!budgetIds.contains(itemId) && !priorItemIds.contains(itemId)) {
```

und danach nur zählen, wenn es ein Budget-Item ist (INV-4 betrifft nur das eigene Budget):

```dart
        if (!budgetIds.contains(itemId)) continue; // früheres Wort: erlaubt, nicht gezählt
        budgetSurfaces.add(token.surface);
        occurrencesByItem[itemId] = (occurrencesByItem[itemId] ?? 0) + 1;
```

Vor `if (violations.isNotEmpty)` einfügen:

```dart
  // INV-18 (Spec Mira schweigt §3.1): Mira spricht nur Wörter früherer Folgen.
  final cjk = RegExp(r'[぀-ヿ一-鿿]');
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      if (bubble.speakerId != kProtagonist) continue;
      var rest = bubble.text;
      for (final token in bubble.tokens) {
        final id = token.itemId;
        if (id == null || !priorItemIds.contains(id)) {
          violations.add(
            'Panel ${panel.index}: Mira sagt „${token.surface}" — das Wort '
            'stammt nicht aus einer früheren Folge (INV-18).',
          );
        }
        rest = rest.replaceFirst(token.surface, '');
      }
      if (cjk.hasMatch(rest)) {
        violations.add(
          'Panel ${panel.index}: Miras Blase „${bubble.text}" enthält '
          'Japanisch außerhalb ihrer Wörter (INV-18).',
        );
      }
    }
  }

  // INV-19: Ein Sprechziel muss vorher von jemand anderem gesagt worden
  // sein — in einer früheren Folge, einem früheren Panel oder einer Blase
  // desselben Panels (Blasen werden vor der Interaktion gelesen).
  final heardSoFar = <String>{...priorItemIds};
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      if (bubble.speakerId == kProtagonist) continue;
      for (final t in bubble.tokens) {
        if (t.itemId != null) heardSoFar.add(t.itemId!);
      }
    }
    for (final it in panel.interactions) {
      if (it.type != InteractionType.speak) continue;
      for (final id in it.targetItemIds ?? const <String>[]) {
        if (!heardSoFar.contains(id)) {
          violations.add(
            'Panel ${panel.index}: Sprechmoment „${it.target}" — Mira hat das '
            'Wort vorher von niemandem gehört (INV-19).',
          );
        }
      }
    }
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/story/episode_validator_mira_test.dart test/features/story/episode_validator_test.dart test/features/story/episode_validator_debrief_test.dart`
Expected: neue Tests PASS. **`episode_validator_test.dart` „the pilot episode fixture is valid as written“ und `folge_01_regen_test.dart` werden jetzt ROT** (Folge 01 V2 verstößt gegen INV-18) — das ist erwartet und wird in Task 4 grün. Für den Commit dieses Tasks: in `lib/features/story/episodes/folge_01_regen.dart` vorübergehend NICHTS ändern; stattdessen den Commit mit dem Hinweis „Folge 01 rot bis Task 4“ machen. Wer streng grüne Commits will: Task 1 und Task 4 in einem Commit zusammenführen (Task 4 direkt anschließen, erst dann committen).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode.dart lib/features/story/episode_validator.dart test/features/story/episode_validator_mira_test.dart
git commit -m "feat(story): Mira-Regel INV-18/19 im Validator, Interaktion silent, stumme Blase"
```

---

### Task 2: Validator-Regeln für stumme Momente

**Files:**
- Modify: `lib/features/story/episode_validator.dart`
- Test: `test/features/story/episode_validator_mira_test.dart` (neue Gruppe)

**Interfaces:**
- Consumes: `InteractionType.silent`, `StoryBubble.isSilence`, `kProtagonist` (Task 1).
- Produces: Validator-Meldungen mit dem Marker `(stummer Moment)`.

- [ ] **Step 1: Write the failing test**

An `episode_validator_mira_test.dart` anhängen (in `main`):

```dart
  group('stumme Momente (Spec §4.2)', () {
    Map<String, dynamic> silence() => {
          'speakerId': 'protagonist',
          'text': '…',
          'hitArea': [],
          'tokens': [],
        };
    Map<String, dynamic> silent(String target, String id) => {
          'type': 'silent',
          'diegetic': true,
          'target': target,
          'targetItemIds': [id],
          'promptText': 'Was hättest du sagen können?',
        };

    test('gültig: eine „…“-Blase, ein Ziel aus dem Budget, irgendwo gehört', () {
      final ep = Episode.fromJson(_episode(
          extraBubbles: [silence()], interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep), returnsNormally);
    });

    test('silent ohne „…“-Blase ist ein Verstoß', () {
      final ep =
          Episode.fromJson(_episode(interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('zwei „…“-Blasen in einem Panel sind ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          extraBubbles: [silence(), silence()],
          interactions: [silent('あ', 'lex_a')]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('zwei silent in einem Panel sind ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          extraBubbles: [silence()],
          interactions: [silent('あ', 'lex_a'), silent('い', 'lex_b')]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('Ziel außerhalb des Budgets ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(
          extraBubbles: [silence()], interactions: [silent('う', 'lex_x')]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('Ziel, das niemand in der Folge sagt, ist ein Verstoß', () {
      final json = _episode(
          extraBubbles: [silence()], interactions: [silent('う', 'lex_c')]);
      (json['budget'] as Map)['items'] = [
        ...((json['budget'] as Map)['items'] as List),
        {'id': 'lex_c', 'refType': 'lexeme', 'singleton': true},
      ];
      expect(() => validateEpisode(Episode.fromJson(json)),
          _violation('stummer Moment'));
    });

    test('mehr als ein Ziel ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [
        silence()
      ], interactions: [
        {
          'type': 'silent',
          'diegetic': true,
          'target': 'あ',
          'targetItemIds': ['lex_a', 'lex_b'],
        },
      ]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });

    test('„…“-Blase ohne silent ist ein Verstoß', () {
      final ep = Episode.fromJson(_episode(extraBubbles: [silence()]));
      expect(() => validateEpisode(ep), _violation('stummer Moment'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/story/episode_validator_mira_test.dart`
Expected: FAIL in der Gruppe „stumme Momente“ (keine Meldung „stummer Moment“).

- [ ] **Step 3: Write minimal implementation**

In `episode_validator.dart` vor `if (violations.isNotEmpty)`:

```dart
  // Stumme Momente (Spec Mira schweigt §4.2): Mira wollte etwas sagen und
  // konnte nicht. Ein Panel mit `silent` hat genau eine „…“-Blase und genau
  // ein Ziel; das Ziel liegt im Budget dieser oder einer früheren Folge und
  // wird in der Folge von jemand anderem gesagt (auch nach dem Moment).
  final heardInEpisode = <String>{
    for (final p in episode.allPanels)
      for (final b in p.bubbles)
        if (b.speakerId != kProtagonist)
          for (final t in b.tokens)
            if (t.itemId != null) t.itemId!,
  };
  for (final panel in episode.allPanels) {
    final silents =
        panel.interactions.where((i) => i.type == InteractionType.silent).toList();
    final silences = panel.bubbles.where((b) => b.isSilence).length;
    if (silents.isEmpty) {
      if (silences > 0) {
        violations.add('Panel ${panel.index}: „…"-Blase ohne Interaktion '
            'silent (stummer Moment).');
      }
      continue;
    }
    if (silents.length > 1) {
      violations.add('Panel ${panel.index}: ${silents.length} stumme Momente; '
          'erlaubt ist einer je Panel (stummer Moment).');
    }
    if (silences != 1) {
      violations.add('Panel ${panel.index}: $silences „…"-Blasen; ein stummer '
          'Moment braucht genau eine (stummer Moment).');
    }
    for (final it in silents) {
      final ids = it.targetItemIds ?? const <String>[];
      if (ids.length != 1) {
        violations.add('Panel ${panel.index}: stummer Moment braucht genau ein '
            'Ziel, hat ${ids.length} (stummer Moment).');
        continue;
      }
      final id = ids.single;
      if (!budgetIds.contains(id) && !priorItemIds.contains(id)) {
        violations.add('Panel ${panel.index}: Ziel „$id" ist weder im Budget '
            'noch aus einer früheren Folge (stummer Moment).');
      }
      if (!heardInEpisode.contains(id)) {
        violations.add('Panel ${panel.index}: Ziel „$id" sagt in dieser Folge '
            'niemand (stummer Moment).');
      }
    }
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/story/episode_validator_mira_test.dart`
Expected: PASS (alle Gruppen).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode_validator.dart test/features/story/episode_validator_mira_test.dart
git commit -m "feat(story): Validator prüft stumme Momente (eine „…“-Blase, ein gehörtes Ziel)"
```

---

### Task 3: Reader — die „…“-Blase ist inert

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (Tippflächen-Schleife um Zeile 568: `for (var i = 0; i < panel.bubbles.length; i++) if (panel.bubbles[i].hitAreaFor(shown).points.isNotEmpty) ...`; Fußzeilen-Liste `footerBubbles` um Zeile 531)
- Test: `test/features/story/story_reader_silence_test.dart` (neu)

**Interfaces:**
- Consumes: `StoryBubble.isSilence` (Task 1).

- [ ] **Step 1: Write the failing test**

`test/features/story/story_reader_silence_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'story_reader_fullscreen_test.dart' show RecordingSystemUi;

const _hitA = [[0.1, 0.1], [0.3, 0.1], [0.3, 0.2], [0.1, 0.2]];
const _hitB = [[0.6, 0.6], [0.8, 0.6], [0.8, 0.7], [0.6, 0.7]];

Episode _silenceEpisode({required bool withHitAreas}) => Episode.fromJson({
      'id': 'ep_silence',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Stille',
      'locale': 'ja',
      'era': '1996',
      'budget': {
        'items': [
          {'id': 'lex_a', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'passant',
                  'text': 'あ、あ',
                  'hitArea': withHitAreas ? _hitA : [],
                  'tokens': [
                    {'surface': 'あ', 'itemId': 'lex_a'},
                    {'surface': 'あ', 'itemId': 'lex_a'},
                  ],
                },
                {
                  'speakerId': 'protagonist',
                  'text': '…',
                  'hitArea': withHitAreas ? _hitB : [],
                  'tokens': [],
                },
              ],
              'thoughts': [],
              'interactions': [
                {
                  'type': 'silent',
                  'diegetic': true,
                  'target': 'あ',
                  'targetItemIds': ['lex_a'],
                },
              ],
            },
            {
              'index': 2,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

Future<List<String>> _openReading(WidgetTester tester, Episode episode) async {
  SharedPreferences.setMockInitialValues({});
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  final spoken = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: StoryReaderScreen(
      episode: episode,
      progressStore: store,
      speak: (t) async => spoken.add(t),
      dictionaryEntries: const [],
      knownIds: const {},
      systemUi: RecordingSystemUi(),
    ),
  ));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('story-title-card')));
  await tester.pumpAndSettle();
  return spoken;
}

void main() {
  testWidgets('die „…“-Blase hat keine Tippfläche und liest nichts vor',
      (tester) async {
    final spoken =
        await _openReading(tester, _silenceEpisode(withHitAreas: true));

    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-bubble-hit-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pump();
    expect(spoken, ['あ、あ']);
  });

  testWidgets('die „…“-Blase landet nicht in der Fußzeile', (tester) async {
    await _openReading(tester, _silenceEpisode(withHitAreas: false));
    // Die gehörte Blase ohne Tippfläche steht in der Fußzeile, die „…“ nicht.
    expect(find.byKey(const ValueKey('story-bubble-footer')), findsOneWidget);
    expect(
      find.descendant(
          of: find.byKey(const ValueKey('story-bubble-footer')),
          matching: find.text('…')),
      findsNothing,
    );
  });
}
```

Hinweis: Wenn `story_reader_fullscreen_test.dart` `RecordingSystemUi` nicht als öffentliche Klasse exportiert (sie ist heute top-level und öffentlich), die vier Zeilen der Klasse in den neuen Test kopieren statt zu importieren.

- [ ] **Step 2: Run test to verify it fails**

Run: `~/flutter/bin/flutter test test/features/story/story_reader_silence_test.dart`
Expected: FAIL — `story-bubble-hit-1` gefunden bzw. Fußzeile vorhanden.

- [ ] **Step 3: Write minimal implementation**

In `story_reader_screen.dart`, Tippflächen-Schleife:

```dart
              for (var i = 0; i < panel.bubbles.length; i++)
                if (!panel.bubbles[i].isSilence &&
                    panel.bubbles[i].hitAreaFor(shown).points.isNotEmpty)
```

Fußzeilen-Liste:

```dart
          final footerBubbles = [
            for (final b in panel.bubbles)
              if (!b.isSilence && b.hitAreaFor(shown).points.isEmpty) b,
          ];
```

Kommentar an der Tippflächen-Schleife ergänzen: „Die „…“-Blase eines stummen Moments ist inert (Spec Mira schweigt §4.1): kein Vorlesen, keine Karte — der Tipp fällt zum Weiterblättern durch.“

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/story/story_reader_silence_test.dart test/features/story/story_reader_screen_test.dart test/features/story/story_reader_fullscreen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_silence_test.dart
git commit -m "feat(story): Reader lässt die „…“-Blase eines stummen Moments inert"
```

---

### Task 4: Drehbuch V3 — Doku und Folge-01-Daten

**Files:**
- Create: `docs/story/DREHBUCH_FOLGE_01_V3.md`
- Modify: `docs/story/STAFFEL_1_DIE_ADRESSE.md` (Format-Regeln)
- Modify: `lib/features/story/episodes/folge_01_regen.dart` (Panels index 2, 3, 4, 5, 6, 7, 8, 9)
- Modify: `test/features/story/folge_01_dichte_test.dart`
- Create: `test/features/story/folge_01_mira_test.dart`

**Interfaces:**
- Consumes: `silent`, `isSilence`, Validator (Tasks 1–2).
- Produces: Folge-01-Blasenreihenfolge je Panel, an die Task 5 die Layout-Datei angleicht (Tabelle unten ist verbindlich). Hit-Area-Konstanten heißen `f01Hit{Quer|Hoch}P{nn}B{i}`; sie werden in Task 5 neu erzeugt. **Bis Task 5 fertig ist, existieren einige Konstanten nicht (P05B3 bleibt, P07B4 fällt weg, …) — deshalb Task 4 und Task 5 ohne Zwischen-Commit oder Task 5 Step 1–3 vor Task 4 Step 3 ausführen.** Empfohlene Reihenfolge: Task 4 Step 1–2 (Tests), dann Task 5 Step 1–4 (Layout + Generierung), dann Task 4 Step 3–5.

**Verbindliche Blasenfolge V3** (Index = Reihenfolge in Daten und Layout):

| Panel (Datei) | B0 | B1 | B2 | B3 |
|---|---|---|---|---|
| p03 (index 2) | passant_a `すみません！あめ！あめ！` | passant_b `ありがとう！あめ、あめ… さむい、さむい` | | |
| p04 (index 3) | signage `傘` | protagonist `…` | | |
| p05 (index 4) | ladenbesitzer `ここ、ここ！` | ladenbesitzer `あめ、あめ！` | ladenbesitzer `これ？かさ？みせ！みせ！` | ladenbesitzer `えき？ひとり？ひとり…` |
| p06 (index 5) | ladenbesitzer `これ、こわれた` | ladenbesitzer `はい、こわれた、こわれた。だめ、だめ` | protagonist `…` | |
| p07 (index 6) | ladenbesitzer `はい。かさ。どうぞ` | protagonist `…` | ladenbesitzer `いくら？いいえ、いいえ。どうぞ、どうぞ。かさ！` | ladenbesitzer `ほんとう、ほんとう。だいじょうぶ、だいじょうぶ` |
| p08 (index 7) | ladenbesitzer `はいはい` | | | |
| p09 (index 8) | signage `あめやどり` | | | |
| p10 (index 9) | protagonist `…` | | | |

p01, p02 unverändert.

- [ ] **Step 1: Write the failing tests**

`test/features/story/folge_01_dichte_test.dart` — Schwellen und Zählung ersetzen (gehört = nicht Mira):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('Folge 01 V3 erfüllt das Dichte-Soll (Spec Mira schweigt §4.3)', () {
    final episode = loadFolge01();
    final counts = <String, int>{};
    var heard = 0;
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        if (bubble.speakerId == kProtagonist) continue;
        for (final token in bubble.tokens) {
          final id = token.itemId;
          if (id == null) continue;
          heard++;
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
    }
    var targets = 0;
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      for (final id in it.targetItemIds ?? const <String>[]) {
        targets++;
        counts[id] = (counts[id] ?? 0) + 1;
      }
    }
    expect(heard, greaterThanOrEqualTo(44), reason: 'zu wenig gehörte Sprache');
    expect(heard + targets, greaterThanOrEqualTo(50));
    for (final ref in episode.budget.items) {
      expect(counts[ref.id] ?? 0, greaterThanOrEqualTo(2),
          reason: '${ref.id} kommt zu selten vor');
    }
    // Bilanz aus der Spec, Wort für Wort (gehört + Ziele).
    expect(counts, {
      'lex_ja_ame': 8, 'lex_ja_kasa': 4, 'lex_ja_hai': 4,
      'lex_ja_kowareta': 4, 'lex_ja_douzo': 3, 'lex_ja_sumimasen': 3,
      'lex_ja_eki': 2, 'lex_ja_koko': 2, 'lex_ja_kore': 2, 'lex_ja_samui': 2,
      'lex_ja_dame': 2, 'lex_ja_hitori': 2, 'lex_ja_hontou': 2,
      'lex_ja_iie': 2, 'lex_ja_daijoubu': 2, 'lex_ja_mise': 2,
      'lex_ja_ikura': 2, 'lex_ja_arigatou': 2,
    });
    expect(episode.allPanels.length, 10);
    expect(episode.intro, isNotNull);
    expect(episode.outro, isNotNull);
  });
}
```

`test/features/story/folge_01_mira_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  final episode = loadFolge01();

  test('Mira sagt in Folge 01 kein Wort Japanisch, nur „…“', () {
    for (final p in episode.allPanels) {
      for (final b in p.bubbles.where((b) => b.speakerId == kProtagonist)) {
        expect(b.isSilence, isTrue, reason: 'Panel ${p.index}: „${b.text}"');
      }
    }
  });

  test('vier stumme Momente: P4 あめ, P6 こわれた, P7 いくら, P10 すみません', () {
    final moments = [
      for (final p in episode.allPanels)
        for (final i in p.interactions)
          if (i.type == InteractionType.silent)
            (p.index, i.target, i.targetItemIds!.single, i.promptText),
    ];
    expect(moments.map((m) => (m.$1, m.$2, m.$3)).toList(), [
      (3, 'あめ', 'lex_ja_ame'),
      (5, 'こわれた', 'lex_ja_kowareta'),
      (6, 'いくら', 'lex_ja_ikura'),
      (9, 'すみません', 'lex_ja_sumimasen'),
    ]);
    for (final m in moments) {
      expect(m.$4, isNotNull, reason: 'Wirtin-Frage fehlt (Panel ${m.$1})');
      expect(m.$4, isNot(contains(m.$2)),
          reason: 'die Frage verrät das Wort (Panel ${m.$1})');
    }
  });

  test('die beiden Sprechmomente bleiben', () {
    final speaks = [
      for (final p in episode.allPanels)
        for (final i in p.interactions)
          if (i.type == InteractionType.speak) (p.index, i.target),
    ];
    expect(speaks, [(4, 'すみません'), (7, 'ありがとう')]);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `~/flutter/bin/flutter test test/features/story/folge_01_dichte_test.dart test/features/story/folge_01_mira_test.dart`
Expected: FAIL — `loadFolge01()` wirft `StoryValidationException` (INV-18 in V2).

- [ ] **Step 3: Write the V3 data**

(Erst Task 5 Step 1–4 ausführen, damit die Hit-Area-Konstanten der neuen Blasenfolge existieren.)

In `folge_01_regen.dart` die Panels gemäß Tabelle ändern. Vollständige neue Blöcke:

**p03 (index 2)** — `bubbles`:

```dart
            {
              'speakerId': 'passant_a',
              'text': 'すみません！あめ！あめ！',
              'hitArea': f01HitQuerP03B0,
              'hitAreaPortrait': f01HitHochP03B0,
              'tokens': [
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'passant_b',
              'text': 'ありがとう！あめ、あめ… さむい、さむい',
              'hitArea': f01HitQuerP03B1,
              'hitAreaPortrait': f01HitHochP03B1,
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
                {'surface': 'さむい', 'itemId': 'lex_ja_samui'},
              ],
            },
```

`notes`: `'Leere Straße, sie geht; zwei Passanten flüchten unter ein Vordach. Passant A drängelt vorbei: 「すみません！あめ！あめ！」 Passantin B, unterm Vordach, lachend: 「ありがとう！あめ、あめ… さむい、さむい」.'`

**p04 (index 3)** — zweite Blase und Interaktion:

```dart
            {
              'speakerId': 'protagonist',
              'text': '…',
              'hitArea': f01HitQuerP04B1,
              'hitAreaPortrait': f01HitHochP04B1,
              'tokens': [],
            },
```

```dart
          'interactions': [
            {
              'type': 'silent',
              'diegetic': true,
              'target': 'あめ',
              'targetItemIds': ['lex_ja_ame'],
              'promptText':
                  'Unter dem Dach, als du das Schild gesehen hast und das Wort '
                  'von der Straße noch im Ohr hattest. Was hättest du leise '
                  'sagen können?',
            },
          ],
```

**p05 (index 4)** — `bubbles` komplett ersetzen:

```dart
            {
              'speakerId': 'ladenbesitzer',
              'text': 'ここ、ここ！',
              'hitArea': f01HitQuerP05B0,
              'hitAreaPortrait': f01HitHochP05B0,
              'tokens': [
                {'surface': 'ここ', 'itemId': 'lex_ja_koko'},
                {'surface': 'ここ', 'itemId': 'lex_ja_koko'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'あめ、あめ！',
              'hitArea': f01HitQuerP05B1,
              'hitAreaPortrait': f01HitHochP05B1,
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ？かさ？みせ！みせ！',
              'hitArea': f01HitQuerP05B2,
              'hitAreaPortrait': f01HitHochP05B2,
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
                {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'えき？ひとり？ひとり…',
              'hitArea': f01HitQuerP05B3,
              'hitAreaPortrait': f01HitHochP05B3,
              'tokens': [
                {'surface': 'えき', 'itemId': 'lex_ja_eki'},
                {'surface': 'ひとり', 'itemId': 'lex_ja_hitori'},
                {'surface': 'ひとり', 'itemId': 'lex_ja_hitori'},
              ],
            },
```

Zweiter Gedanke in p05: `'„Sag irgendwas. Das Wort, das der Mann eben im Regen gesagt hat — sag es."'`. `notes` um „Mira nickt (keine Blase).“ ergänzen und Miras alte Zeile streichen. Die `speak`-Interaktion bleibt unverändert.

**p06 (index 5)** — dritte Blase:

```dart
            {
              'speakerId': 'protagonist',
              'text': '…',
              'hitArea': f01HitQuerP06B2,
              'hitAreaPortrait': f01HitHochP06B2,
              'tokens': [],
            },
```

```dart
          'interactions': [
            {
              'type': 'silent',
              'diegetic': true,
              'target': 'こわれた',
              'targetItemIds': ['lex_ja_kowareta'],
              'promptText':
                  'Er hat dir den Schirm gezeigt und es dreimal gesagt. Was '
                  'hättest du nachsprechen können?',
            },
          ],
```

`notes`: „Mira (leise): 「…こわれた…？」“ ersetzen durch „Mira will etwas sagen — „…““.

**p07 (index 6)** — `bubbles` komplett ersetzen:

```dart
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい。かさ。どうぞ',
              'hitArea': f01HitQuerP07B0,
              'hitAreaPortrait': f01HitHochP07B0,
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
              ],
            },
            {
              'speakerId': 'protagonist',
              'text': '…',
              'hitArea': f01HitQuerP07B1,
              'hitAreaPortrait': f01HitHochP07B1,
              'tokens': [],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'いくら？いいえ、いいえ。どうぞ、どうぞ。かさ！',
              'hitArea': f01HitQuerP07B2,
              'hitAreaPortrait': f01HitHochP07B2,
              'tokens': [
                {'surface': 'いくら', 'itemId': 'lex_ja_ikura'},
                {'surface': 'いいえ', 'itemId': 'lex_ja_iie'},
                {'surface': 'いいえ', 'itemId': 'lex_ja_iie'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
            {
              'speakerId': 'ladenbesitzer',
              'text': 'ほんとう、ほんとう。だいじょうぶ、だいじょうぶ',
              'hitArea': f01HitQuerP07B3,
              'hitAreaPortrait': f01HitHochP07B3,
              'tokens': [
                {'surface': 'ほんとう', 'itemId': 'lex_ja_hontou'},
                {'surface': 'ほんとう', 'itemId': 'lex_ja_hontou'},
                {'surface': 'だいじょうぶ', 'itemId': 'lex_ja_daijoubu'},
                {'surface': 'だいじょうぶ', 'itemId': 'lex_ja_daijoubu'},
              ],
            },
```

Gedanke vor dem bestehenden einfügen: `{'text': '„Was kostet der? Wie fragt man das?"'}`. Interaktion:

```dart
          'interactions': [
            {
              'type': 'silent',
              'diegetic': true,
              'target': 'いくら',
              'targetItemIds': ['lex_ja_ikura'],
              'promptText':
                  'Als du zum Geldbeutel gegriffen hast. Was hättest du '
                  'fragen können?',
            },
          ],
```

`notes`: „Mira greift zum Geldbeutel: „…“. Er sieht es: 「いくら？いいえ、いいえ。どうぞ、どうぞ。かさ！」 Dann: 「ほんとう、ほんとう。だいじょうぶ、だいじょうぶ」“.

**p08 (index 7)** — Miras Blase (B1) streichen. Gedanke nach dem bestehenden anhängen: `{'text': 'Acht Wörter heute. Sie zählt sie an den Fingern ab, auf dem Weg die Straße hinunter.'}`. `notes`: Miras Übungs-Zeile streichen. Die `speak`-Interaktion bleibt.

**p09 (index 8)** — Miras Blase (B1) streichen. Gedanke als ersten einfügen: `{'text': 'Sie liest, Zeichen für Zeichen. Das zweite kennt sie.'}`.

**p10 (index 9)** — Blase ersetzen:

```dart
            {
              'speakerId': 'protagonist',
              'text': '…',
              'hitArea': f01HitQuerP10B0,
              'hitAreaPortrait': f01HitHochP10B0,
              'tokens': [],
            },
```

Gedanke als ersten einfügen: `{'text': '„Was sagt man, wenn man irgendwo hereinkommt?"'}`. Interaktion:

```dart
          'interactions': [
            {
              'type': 'silent',
              'diegetic': true,
              'target': 'すみません',
              'targetItemIds': ['lex_ja_sumimasen'],
              'promptText':
                  'Und dann standest du vor meiner Tür, die Hand am Griff. Was '
                  'sagt man, wenn man irgendwo hereinkommt?',
            },
          ],
```

Doc-Kommentar über `pilot01RegenJson`: „V2“ → „V3 nach docs/story/DREHBUCH_FOLGE_01_V3.md (Mira schweigt)“.

`docs/story/DREHBUCH_FOLGE_01_V3.md`: Kopie von V2 mit (a) Kopfabsatz „Warum V3“ (Ulis Befund 2.10., Mira-Regel INV-18/19, Verweis auf die Spec), (b) Format-Regel „Sprachdichte“ neu: *gezählt werden gehörte Vorkommen plus Sprech- und Stumm-Ziele; Mira zählt erst, wenn sie sprechen darf*, Folge 01 = 44 + 6 = 50, (c) P3–P10 nach der Tabelle oben mit den Gedanken und Wirtin-Fragen, (d) Dichte-Bilanz aus Spec §4.3. V2 bleibt unverändert als Protokoll.

`docs/story/STAFFEL_1_DIE_ADRESSE.md`: unter den Format-Regeln eine Zeile: „**Mira-Regel (INV-18/19, ab 2.10.):** Mira spricht in Folge N nur Wörter aus Folgen vor N; wo sie etwas sagen will und nicht kann, steht ein stummer Moment („…“), den das Café nachbereitet.“

- [ ] **Step 4: Run tests to verify they pass**

Run: `~/flutter/bin/flutter test test/features/story/`
Expected: PASS, inklusive `episode_validator_test.dart`, `folge_01_regen_test.dart`, `folge_01_layout_test.dart`, Café-Nachbesprechungs-Tests unter `test/features/cafe/` separat: `~/flutter/bin/flutter test test/features/cafe/` → PASS.

- [ ] **Step 5: Commit** (zusammen mit Task 5, siehe dort)

---

### Task 5: Layout, Tippflächen, Lettering

**Files:**
- Modify: `tool/comic/folge01_layout.json` (panels p03, p04, p05, p06, p07, p08, p09, p10; je `quer` und `hoch`)
- Regenerate: `lib/features/story/episodes/folge_01_layout.g.dart` (`python3 tool/comic/gen_layout_dart.py`)
- Regenerate: `assets/story/folge01/p03*.jpg … p10*.jpg` inkl. `p05_reaction*`, `p08_reaction*` (`python3 tool/comic/letter_folge01.py`)
- Test: `test/features/story/folge_01_layout_test.dart` (unverändert, muss grün sein)

**Interfaces:**
- Consumes: Blasenfolge-Tabelle aus Task 4.
- Produces: `f01Hit{Quer|Hoch}P{03..10}B{i}` passend zur Tabelle.

- [ ] **Step 1: Master holen und Ausgangslage prüfen**

```bash
mkdir -p build/f01_raw && scp 'pc:~/comfy_f01/final/*.jpg' build/f01_raw/
ls build/f01_raw | wc -l     # 22
python3 tool/comic/letter_preview.py faces   # Ausgangsbild: build/letter_preview_{quer,hoch}.png
```

(Box schläft? `wakegpu`, dann bis zu 2 Minuten warten; während der Arbeit `ssh pc touch ~/.no-idle-suspend`, danach `ssh pc rm ~/.no-idle-suspend`.)

- [ ] **Step 2: Layout-Datei nach der Tabelle ändern** (beide Formate je Panel)

Regeln, damit die Rechtecke nicht frei erfunden werden:
- **Ersetzen:** Wird Miras Blase zu „…“ (p04 B1, p06 B2, p07 B1, p10 B0), bleibt der Mittelpunkt ihres alten `rect`; Breite auf 45 % der alten Breite, mindestens 0.08, Höhe unverändert. `rect` ist `[x, y, w, h]`, normiert.
- **Streichen:** p07 alte B3 (`…ほんとう？`), p08 B1 (Murmeln), p09 B1 (`ここ…？…`) aus `bubbles` entfernen; die Reihenfolge der übrigen bleibt.
- **Text tauschen:** p03 B0/B1, p05 B2/B3 (alt `これ？かさ？みせ！`/`ひとり？`), p07 B2/B3 bekommen den neuen Text; das Rechteck bleibt zunächst gleich.
- **Neu:** p05 B0 `ここ、ここ！` vor die bisherigen Blasen. Startrechteck: Breite und Höhe wie p05 alt B0 (`あめ、あめ！`), Platz frei von `faces` und `nogo` im selben Panel/Format; in der Vorschau (`faces`) suchen.
- p05 alt B3 (Miras `…はい。ひとり`) entfällt; ihr Rechteck kann für `えき？ひとり？ひとり…` dienen, wenn das alte `ひとり？`-Rechteck zu klein ist.

- [ ] **Step 3: Prüfen, bis keine Verstöße mehr gemeldet werden**

```bash
python3 tool/comic/check_layout.py
python3 -c "import json,sys; sys.path.insert(0,'tool/comic'); import letter_folge01 as L; print('\n'.join(L.validate(json.load(open(L.LAYOUT,encoding='utf-8')))) or 'OK')"
python3 tool/comic/letter_preview.py faces
```

Bei `KLEINSCHRIFT`: Blase größer machen (nie die Schrift kleiner, steht im Skript-Kopf). Bei `GESICHT VERDECKT` / `ÜBERLAGERUNG` / `SICHERE ZONE`: Rechteck verschieben. Ziel: Ausgabe `OK`, und in `build/letter_preview_{quer,hoch}.png` sitzt jede Blase neben der sprechenden Figur (die „…“-Blase neben Mira).

- [ ] **Step 4: Tippflächen erzeugen und lettern**

```bash
python3 tool/comic/gen_layout_dart.py      # schreibt + formatiert folge_01_layout.g.dart
python3 tool/comic/letter_folge01.py       # „OK: 28 Dateien nach assets/story/folge01"
git status --short assets/story/folge01    # geändert: p03,p04,p05(+reaction),p06,p07,p08(+reaction),p09,p10 je quer+hoch
```

- [ ] **Step 5: Sichtbogen für Uli**

`build/letter_preview_quer.png` und `build/letter_preview_hoch.png` nach `~/f01-v3-lettering-quer.png` / `~/f01-v3-lettering-hoch.png` kopieren und im Chat zeigen (Uli liest gegen: Texte, Blasenlage, „…“ an Mira). Nicht auf Ulis Antwort warten, um weiterzumachen; seine Korrekturen kommen als Nachzug.

- [ ] **Step 6: Run tests (nach Task 4 Step 3)**

Run: `~/flutter/bin/flutter test test/features/story/ test/features/cafe/`
Expected: PASS.

- [ ] **Step 7: Commit (Tasks 4 + 5 zusammen)**

```bash
git add docs/story/DREHBUCH_FOLGE_01_V3.md docs/story/STAFFEL_1_DIE_ADRESSE.md \
  lib/features/story/episodes/folge_01_regen.dart lib/features/story/episodes/folge_01_layout.g.dart \
  tool/comic/folge01_layout.json assets/story/folge01/ \
  test/features/story/folge_01_dichte_test.dart test/features/story/folge_01_mira_test.dart
git commit -m "feat(story): Folge 01 V3 — Mira schweigt, vier stumme Momente, neu gelettert"
```

---

### Task 6: Vollsuite, Emulator, Gerätetest, PR

**Files:** keine neuen; `tool/comic/README.md` Abschnitt 9 um einen Satz ergänzen: „Stumme Blase: Text `…`, keine Tokens; Platz neben Mira, Breite ≥ 0.08 (Spec Mira schweigt §4.2).“

- [ ] **Step 1: Vollsuite auf der GPU-Box**

```bash
git push -u origin impl/mira-schweigt
ssh pc 'cd ~/projects/nihongo && git fetch -q origin && git checkout -q -B impl/mira-schweigt origin/impl/mira-schweigt && export PATH=$HOME/development/flutter/bin:$PATH && flutter pub get >/dev/null && flutter analyze --no-fatal-infos | tail -3 && flutter test --reporter compact 2>&1 | tail -5'
```

Expected: Analyzer ohne `error •`; Tests „+N −8“, die 8 nur unter `test/mining_packs/ja/`. Danach auf der Box `git checkout -q main` (den Klon nicht auf dem Branch stehen lassen).

- [ ] **Step 2: Emulator-Sicht** (Skill `cross-machine-test-deploy`; Fahrweg in der Notiz „Android-Emulator auf der GPU-Box“: AVD `s23` headless, `emu.sh`). Screenshots hoch und quer von P4, P5, P7, P10 in der Lesephase; Prüfung: „…“ an Mira, Tipp darauf blättert weiter, Tipp auf P5 `ここ、ここ！` liest vor. Bogen nach `~/f01-v3-emulator.png`.

- [ ] **Step 3: S23-Gerätetest** — APK auf dem LAPTOP bauen (`--build-number` größer als die zuletzt installierte, mindestens 2005), Installation auf „Success“ prüfen. Prüfliste für Uli: Folge 01 ganz lesen; Mira hat kein Japanisch; vier „…“; beide Sprechmomente gehen; Drehen in P5 und P7 zeigt dieselbe Szene (Plan H, bisher ungetestet); Wörterbuch/Wörterkarte (je nach #59-Stand) geht; Endkarte → Café läuft wie bisher.

- [ ] **Step 4: Draft-PR**

```bash
git add tool/comic/README.md && git commit -m "docs(comic): stumme Blase im Lettering-Abschnitt"
git push
gh pr create --draft --base main --title "feat(story): Mira schweigt — Folge 01 V3, stumme Momente, Mira-Regel" --body "<Zusammenfassung: Regel, Daten, Lettering, Testergebnis, Prüfliste S23; Plan 1 von 4 aus Spec #58>"
```
