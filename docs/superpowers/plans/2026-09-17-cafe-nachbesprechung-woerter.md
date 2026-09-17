# Café-Nachbesprechung (Wörter) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nach dem Ende von Folge 01 geht es ins Café: Die Endkarte bietet „Ins Café", die Wirtin erklärt die 18 Wörter der Folge (Bedeutung, Stelle in der Folge, Gebrauch, „man kann auch sagen …") und fragt sie danach ab; im normalen Besuch gibt es „Erklär's mir nochmal" und die Sprosse-0-Karte vor dem ersten Turn.

**Architecture:** Spec: `docs/superpowers/specs/2026-09-15-cafe-nachbesprechung-design.md` (Schritte 1 + 2 aus §11; Zeichen, Grammatik und P11 sind eigene Folgepläne). Das Café bekommt eine **zweite Item-Quelle** (`debriefItemsFor` = Folgen-Manifest ∩ `learn_items`, nur über `getLearnItem`), einen **Nachbesprechungs-Ablauf** (`CafeDebriefScreen`: Akt 1 Erklärungskarten → Akt 2 bestehende Turns mit vorgegebener Warteschlange) und eine **Erklärungskarte** (`DebriefCardView` = bestehende `EncounterView` + Café-Zusatz). Der Erklärungsblock lebt als optionales Feld `Episode.debrief` im Episoden-JSON, vom `EpisodeValidator` geprüft. Offene Nachbesprechungen merkt der `StoryProgressStore` (SharedPreferences); die Belegung macht die Wirtin anwesend. Die Reader-Endkarte bekommt „Ins Café"/„Später", `StoryRoute` öffnet `CafeRoute(debriefEpisodeId: …)`.

**Tech Stack:** Flutter/Dart, Riverpod (nur Routen/Provider), Drift/SQLite (`LearningDb`, nur Lesen bestehender Tabellen — **kein Schema-Bump**), `shared_preferences`, bestehende l10n (`AppLocalizations`, nur `encounterNext` = „Verstanden").

**Spec:** `docs/superpowers/specs/2026-09-15-cafe-nachbesprechung-design.md` — liegt auf diesem Branch (Kopie von PR #47 mit der Stand-Korrektur vom 17.9.).

## Global Constraints

- **Branch/Worktree:** `impl/cafe-nachbesprechung` (Basis `feat/reader-erleben`, PR #45), Worktree `/home/uli/projects/nihongo/.claude/worktrees/design-cafe-nachbesprechung`. Alle Kommandos von dort.
- **Deutsch ist Bediensprache** — alle neuen UI-Strings wörtlich: Endkarte `Ins Café` / `Später` (bestehend bleibt `Zurück zum Lesen`, wenn kein Café-Weg gesetzt ist); Turn `Erklär's mir nochmal`; Karte `Hier hast du es zum ersten Mal gehört:` und `Man kann auch sagen:`; Nachbesprechungs-AppBar `Die Wirtin`; Leerzustand `Die Wirtin nickt. Über diese Folge gibt es noch nichts zu erzählen.`; Einladung `Wollen wir über die Folge reden?`; Rückweg `Zurück ins Café`.
- **Invarianten unangetastet:** kein Gate (INV-1: „Später" immer da, Folge gilt als gelesen); Reader zeigt weiter nur Audio + Kana (INV-2, keine Änderung an Panels/Blasen); Item-Quelle der Nachbesprechung ist **ausschließlich** `learn_items` via `LearningDb.getLearnItem` (INV-8/INV-9/INV-11 — kein Budget-Item ohne Übergabe erscheint); keine Zahlen, Zähler, Häkchen in Wirtin-Texten oder Zuständen (INV-10); **Variante ≠ Item**: `DebriefVariant` erzeugt nie ein `learn_item`, wird nie abgefragt, höchstens zwei je Wort.
- **Nur Lexeme in diesem Plan.** `character`-/`grammar`-Items werden von `debriefItemsFor` bewusst übersprungen (Spec §11 Schritte 3/4). Die Übergabe am Folgen-Ende (`EpisodeSrsHandoff`) bleibt unverändert (führt nur `budget.items` ein).
- **IDs/Konventionen:** Pack-ID `'lang_ja'`, BCP-47 für die Brücke `widget.languageId.replaceFirst('lang_', '')` (= `'ja'`), `learn_items.id` = `'$languageId:${refType.name}:$refId'`. Deutsche Bedeutung via `meaningForConcept(concept.id, fallback: concept.glossKey)`.
- **Widget-Keys (wörtlich):** `story-end-cafe`, `story-end-done` (bestehend), `cafe-debrief-screen`, `cafe-debrief-line`, `cafe-debrief-empty`, `cafe-debrief-card`, `cafe-debrief-panel`, `cafe-debrief-usage`, `cafe-debrief-variants-title`, `cafe-debrief-variant-<i>`, `cafe-debrief-invite`, `cafe-turn-encounter`, `cafe-turn-explain`, `cafe-turn-explain-sheet`, `cafe-turn-done-line`, `encounter-next` (bestehend, der „Verstanden"-Knopf).
- **Keine neuen Dependencies, kein `build_runner`, keine neuen l10n-Schlüssel** (Café-Strings sind wie heute hartkodiert deutsch; nur `EncounterView` nutzt l10n → Widget-Tests, die eine Karte rendern, brauchen den l10n-Wrapper aus `test/features/encounter/encounter_view_test.dart`).
- **Tests:** `flutter test <datei>` je Task, `flutter analyze` sauber. „Grün" für die Full-Suite heißt: Fehler sind ausschließlich die 8 vorbestehenden in `test/mining_packs/ja/` (fehlende native `.so`, rot auch auf main). Der NUC hat wenig RAM — bricht `flutter test` mit OOM ab, die Suite auf der GPU-Box `pc` laufen lassen (Skill `cross-machine-test-deploy`), nie „Flakiness" ohne isolierte Verifikation akzeptieren.
- **Commits:** `feat(cafe): … (Nachbesprechung)` bzw. `feat(story): …`, `test(...)`, `docs(...)`; Trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

---

### Task 1: Schema — `DebriefVariant`, `DebriefNote`, `Episode.debrief`

**Files:**
- Modify: `lib/features/story/episode.dart` (neue Klassen vor `class Episode`; `Episode`: Feld nach `outro`, Konstruktor, `fromJson`)
- Test: `test/features/story/episode_debrief_test.dart` (neu)

**Interfaces:**
- Consumes: bestehendes `Episode.fromJson`.
- Produces: `class DebriefVariant { String form; String reading; String meaning; String? note; }`, `class DebriefNote { String usage; List<DebriefVariant> variants; }` (beide mit `fromJson`), `Episode.debrief: Map<String, DebriefNote>` (Default `const {}`, JSON-Schlüssel `debrief` → `{ itemId: { usage, variants: [{form, reading?, meaning, note?}] } }`).

- [ ] **Step 1: Failing Test schreiben** — `test/features/story/episode_debrief_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';

Map<String, dynamic> _base() => {
      'id': 'ep_x',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [],
    };

void main() {
  test('Episode.debrief parst Gebrauch und Varianten je Item', () {
    final episode = Episode.fromJson({
      ..._base(),
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {
              'form': 'おおあめ',
              'reading': 'おおあめ',
              'meaning': 'starker Regen',
              'note': 'wenn es schüttet',
            },
          ],
        },
      },
    });
    final note = episode.debrief['lex_ja_ame']!;
    expect(note.usage, 'Regen. Das Wort vom Zettel.');
    expect(note.variants, hasLength(1));
    expect(note.variants.single.form, 'おおあめ');
    expect(note.variants.single.meaning, 'starker Regen');
    expect(note.variants.single.note, 'wenn es schüttet');
  });

  test('fehlender debrief-Block → leere Map; fehlende Varianten → leere '
      'Liste; fehlende Lesung → Form', () {
    expect(Episode.fromJson(_base()).debrief, isEmpty);
    final note = DebriefNote.fromJson({'usage': 'x'});
    expect(note.variants, isEmpty);
    final v = DebriefVariant.fromJson({'form': 'どうも', 'meaning': 'danke, kurz'});
    expect(v.reading, 'どうも');
    expect(v.note, isNull);
  });
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/story/episode_debrief_test.dart`
Expected: FAIL — `DebriefNote`/`DebriefVariant` nicht definiert, `debrief` kein Getter.

- [ ] **Step 3: Implementieren** — in `lib/features/story/episode.dart` direkt vor `class Episode {` einfügen:

```dart
/// „Man kann auch sagen …" — eine Variante, die die Wirtin in der
/// Nachbesprechung nennt (Spec Café-Nachbesprechung §3.3/§4). Wissen am
/// eingeführten Wort, NIE ein eigenes Item: keine Karteikarte, nie abgefragt.
class DebriefVariant {
  final String form;
  final String reading;
  final String meaning;
  final String? note;

  const DebriefVariant({
    required this.form,
    required this.reading,
    required this.meaning,
    this.note,
  });

  factory DebriefVariant.fromJson(Map<String, dynamic> j) => DebriefVariant(
        form: j['form'] as String,
        reading: j['reading'] as String? ?? j['form'] as String,
        meaning: j['meaning'] as String,
        note: j['note'] as String?,
      );
}

/// Der Erklärungsblock der Wirtin zu einem Budget-Item (Spec §5.1):
/// Gebrauch in ein bis zwei Sätzen plus höchstens zwei Varianten.
class DebriefNote {
  final String usage;
  final List<DebriefVariant> variants;

  const DebriefNote({required this.usage, this.variants = const []});

  factory DebriefNote.fromJson(Map<String, dynamic> j) => DebriefNote(
        usage: j['usage'] as String,
        variants: [
          for (final v in (j['variants'] as List? ?? const []))
            DebriefVariant.fromJson(v as Map<String, dynamic>),
        ],
      );
}
```

In `class Episode` nach `final String? outro;`:

```dart
  /// Erklärungsblöcke der Wirtin je Budget-Item-Id (Spec Café-Nachbesprechung
  /// §5.1). Optional: fehlt der Block, zeigt die Karte nur Wort, Lesung,
  /// Bedeutung und die Stelle in der Folge.
  final Map<String, DebriefNote> debrief;
```

Im Konstruktor nach `this.outro,`: `this.debrief = const {},`. In `fromJson` nach `outro: j['outro'] as String?,`:

```dart
        debrief: {
          for (final e in ((j['debrief'] as Map?) ?? const {}).entries)
            e.key as String:
                DebriefNote.fromJson(e.value as Map<String, dynamic>),
        },
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/episode_debrief_test.dart test/features/story/episode_test.dart`
Expected: PASS (bestehende Episode-Tests unverändert grün).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode.dart test/features/story/episode_debrief_test.dart
git commit -m "feat(story): Episodenschema — Erklärungsblock debrief (Gebrauch + Varianten) (Nachbesprechung)"
```

---

### Task 2: Validator — Nachbesprechungs-Regeln (Spec §5.6)

**Files:**
- Modify: `lib/features/story/episode_validator.dart` (`validateEpisode`: Sammlung der Budget-Oberflächen in der Token-Schleife; neuer Block vor `if (violations.isNotEmpty)`)
- Test: `test/features/story/episode_validator_debrief_test.dart` (neu)

**Interfaces:**
- Consumes: `Episode.debrief` (Task 1), `Episode.budget.items`, Tokens.
- Produces: drei neue Verstoß-Klassen in `StoryValidationException.violations`: Debrief für Nicht-Budget-Item; > 2 Varianten; Varianten-Form = Token-Oberfläche eines Budget-Items derselben Folge.

- [ ] **Step 1: Failing Tests schreiben** — `test/features/story/episode_validator_debrief_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

Map<String, dynamic> _panel(int index, List<Map<String, dynamic>> tokens) => {
      'index': index,
      'asset': 'assets/story/p0$index.jpg',
      'bubbles': [
        {
          'speakerId': 'x',
          'text': tokens.map((t) => t['surface']).join(),
          'tokens': tokens,
        },
      ],
      'thoughts': [],
      'interactions': [],
    };

Map<String, dynamic> _episode({Map<String, dynamic>? debrief}) => {
      'id': 'ep_v',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_hai', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      if (debrief != null) 'debrief': debrief,
      'pages': [
        {
          'index': 0,
          'panels': [
            _panel(0, [
              {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              {'surface': 'はい', 'itemId': 'lex_ja_hai'},
            ]),
            _panel(1, [
              {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              {'surface': 'はい', 'itemId': 'lex_ja_hai'},
            ]),
          ],
        },
      ],
    };

List<String> _violations(Map<String, dynamic> json) {
  try {
    validateEpisode(Episode.fromJson(json));
    return const [];
  } on StoryValidationException catch (e) {
    return e.violations;
  }
}

void main() {
  test('ein gültiger Erklärungsblock (Budget-Item, ≤2 Varianten, fremde '
      'Formen) passiert', () {
    expect(
        _violations(_episode(debrief: {
          'lex_ja_ame': {
            'usage': 'Regen.',
            'variants': [
              {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
              {'form': 'あまぐも', 'reading': 'あまぐも', 'meaning': 'Regenwolke'},
            ],
          },
        })),
        isEmpty);
  });

  test('Debrief für ein Item außerhalb des Budgets ist ein Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_himitsu': {'usage': 'geheim'},
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('lex_ja_himitsu'));
    expect(v.single, contains('nicht im Budget'));
  });

  test('mehr als zwei Varianten sind ein Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_ame': {
        'usage': 'Regen.',
        'variants': [
          {'form': 'a', 'meaning': '1'},
          {'form': 'b', 'meaning': '2'},
          {'form': 'c', 'meaning': '3'},
        ],
      },
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('3 Varianten'));
  });

  test('eine Variante, die selbst Budget-Item dieser Folge ist, ist ein '
      'Verstoß', () {
    final v = _violations(_episode(debrief: {
      'lex_ja_ame': {
        'usage': 'Regen.',
        'variants': [
          {'form': 'はい', 'meaning': 'ja'},
        ],
      },
    }));
    expect(v, hasLength(1));
    expect(v.single, contains('"はい"'));
    expect(v.single, contains('Budget-Item'));
  });
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/story/episode_validator_debrief_test.dart`
Expected: FAIL — die drei Negativ-Tests finden keine Verstöße (`v` ist leer).

- [ ] **Step 3: Implementieren** — in `lib/features/story/episode_validator.dart`:

Nach `final occurrencesByItem = <String, int>{};` einfügen:

```dart
  // Oberflächen aller Budget-Items, wie sie in der Folge stehen — die Menge,
  // gegen die Varianten der Nachbesprechung geprüft werden (§5.6).
  final budgetSurfaces = <String>{};
```

In der Token-Schleife nach dem INV-3-`continue;` und vor `occurrencesByItem[itemId] = …`:

```dart
        budgetSurfaces.add(token.surface);
```

Nach der INV-4-Schleife (vor `if (violations.isNotEmpty)`):

```dart
  // Nachbesprechung (Spec Café-Nachbesprechung §5.6): Die Wirtin erklärt nur
  // Budget-Items; Varianten („man kann auch sagen") sind Wissen am Item, keine
  // Items — höchstens zwei, und keine Variante darf selbst ein Budget-Item
  // dieser Folge sein (dann gehört sie ins Budget, nicht in die Randnotiz).
  for (final entry in episode.debrief.entries) {
    final itemId = entry.key;
    final note = entry.value;
    if (!budgetIds.contains(itemId)) {
      violations.add(
        'Debrief "$itemId" erklärt ein Item, das nicht im Budget dieser Folge '
        'steht (Nachbesprechung erklärt nur Eingeführtes, INV-8/INV-11).',
      );
    }
    if (note.variants.length > 2) {
      violations.add(
        'Debrief "$itemId" nennt ${note.variants.length} Varianten; erlaubt '
        'sind höchstens 2 (keine Varianten-Kaskade).',
      );
    }
    for (final v in note.variants) {
      if (budgetSurfaces.contains(v.form)) {
        violations.add(
          'Debrief "$itemId": Variante "${v.form}" ist selbst ein Budget-Item '
          'dieser Folge — dann gehört sie ins Budget, nicht in „man kann auch '
          'sagen".',
        );
      }
    }
  }
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/episode_validator_debrief_test.dart test/features/story/episode_validator_test.dart test/features/story/folge_01_regen_test.dart`
Expected: PASS (Folge 01 hat noch keinen `debrief`-Block → keine neuen Verstöße).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode_validator.dart test/features/story/episode_validator_debrief_test.dart
git commit -m "feat(story): Validator prüft Erklärungsblöcke — nur Budget-Items, ≤2 Varianten, Variante ≠ Item (Nachbesprechung)"
```

---

### Task 3: Progress-Store — Stand der Nachbesprechung

**Files:**
- Modify: `lib/features/story/story_progress_store.dart` (Klasse erweitern)
- Test: `test/features/story/story_progress_store_test.dart` (zwei Tests anhängen)

**Interfaces:**
- Consumes: bestehende `isCompleted(episodeId)`.
- Produces: `Future<int> debriefIndex(String episodeId)` (Default 0), `Future<void> saveDebriefIndex(String episodeId, int index)`, `Future<void> markDebriefDone(String episodeId)`, `Future<bool> isDebriefDone(String episodeId)`, `Future<bool> isDebriefPending(String episodeId)` (= completed && !done). Prefs-Schlüssel `story_debrief_index_<id>`, `story_debrief_done_<id>`.

- [ ] **Step 1: Failing Tests anhängen** — an `test/features/story/story_progress_store_test.dart` (innerhalb `main`, ans Ende):

```dart
  test('debriefIndex startet bei 0 und wird pro Folge gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    expect(await store.debriefIndex('ep_a'), 0);
    await store.saveDebriefIndex('ep_a', 5);
    expect(await store.debriefIndex('ep_a'), 5);
    expect(await store.debriefIndex('ep_b'), 0);
  });

  test('isDebriefPending: nur nach Folgen-Ende und vor markDebriefDone',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    // Nicht gelesen → nie offen (INV-11).
    expect(await store.isDebriefPending('ep_a'), isFalse);
    await store.markCompleted('ep_a');
    expect(await store.isDebriefPending('ep_a'), isTrue);
    await store.markDebriefDone('ep_a');
    expect(await store.isDebriefDone('ep_a'), isTrue);
    expect(await store.isDebriefPending('ep_a'), isFalse);
  });
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/story/story_progress_store_test.dart`
Expected: FAIL — Methoden nicht definiert.

- [ ] **Step 3: Implementieren** — in `StoryProgressStore` nach `isCompleted` einfügen:

```dart
  static const _debriefIndexPrefix = 'story_debrief_index_';
  static const _debriefDonePrefix = 'story_debrief_done_';

  /// Nachbesprechung, Akt 1: Index der nächsten noch nicht erklärten Karte
  /// (Spec Café-Nachbesprechung §3.6 — Abbruch setzt beim ersten offenen
  /// Item fort). 0, wenn noch nichts erklärt wurde.
  Future<int> debriefIndex(String episodeId) async =>
      _prefs.getInt('$_debriefIndexPrefix$episodeId') ?? 0;

  Future<void> saveDebriefIndex(String episodeId, int index) async =>
      await _prefs.setInt('$_debriefIndexPrefix$episodeId', index);

  /// Akt 1 vollständig gesehen. Kein Fortschritt im Sinne von INV-10: schaltet
  /// nichts frei, wird nirgends gezählt — die Wirtin erklärt nur nicht zweimal.
  Future<void> markDebriefDone(String episodeId) async =>
      await _prefs.setBool('$_debriefDonePrefix$episodeId', true);

  Future<bool> isDebriefDone(String episodeId) async =>
      _prefs.getBool('$_debriefDonePrefix$episodeId') ?? false;

  /// Offen = Folge zu Ende gelesen UND Akt 1 noch nicht vollständig gesehen
  /// (§3.6). Vor dem Folgen-Ende ist eine Nachbesprechung nie offen (INV-11).
  Future<bool> isDebriefPending(String episodeId) async =>
      await isCompleted(episodeId) && !await isDebriefDone(episodeId);
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/story_progress_store_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_progress_store.dart test/features/story/story_progress_store_test.dart
git commit -m "feat(story): ProgressStore merkt Stand und Abschluss der Nachbesprechung (Nachbesprechung)"
```

---

### Task 4: Café-Quelle — `debriefItemsFor`, `firstAppearancePanel`, `loadDebriefCard`

**Files:**
- Create: `lib/features/cafe/cafe_debrief.dart`
- Test: `test/features/cafe/cafe_debrief_test.dart` (neu); `test/features/cafe/cafe_inv9_test.dart` (ein Test anhängen)

**Interfaces:**
- Consumes: `LearningDb.getLearnItem(id)`, Tabellen `lexemes`/`concepts`/`assets`, `meaningForConcept` (`lib/core/i18n/concept_meaning.dart`), `LexemeEncounter` (`lib/core/ladder/encounter.dart`), `Episode`/`StoryPanel`/`DebriefNote` (Task 1).
- Produces:
  - `List<String> debriefOrder(Episode episode)` — Budget-Item-Ids in Reihenfolge des ersten Token-Auftritts, Rest in Budget-Reihenfolge.
  - `StoryPanel? firstAppearancePanel(Episode episode, String itemId)`.
  - `Episode? episodeIntroducing(List<Episode> episodes, String itemId)`.
  - `Future<List<LearnItem>> debriefItemsFor(LearningDb db, Episode episode, String languageId)` — nur Lexeme, nur mit `learn_item`.
  - `class DebriefCardContent { LexemeEncounter encounter; StoryPanel? firstPanel; DebriefNote? note; }`.
  - `Future<DebriefCardContent?> loadDebriefCard(LearningDb db, LearnItem item, {Episode? episode})`.

- [ ] **Step 1: Failing Tests schreiben** — `test/features/cafe/cafe_debrief_test.dart`:

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief.dart';
import 'package:nihongo_app/features/story/episode.dart';

/// Drei Panels: かさ zuerst (P0), あめ ab P1; はい nur über targetItemIds.
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_debrief',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_hai', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
          ],
        },
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'かさ',
                  'tokens': [
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ、かさ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true, 'targetItemIds': ['lex_ja_hai']},
              ],
            },
            {
              'index': 2,
              'asset': 'assets/story/p03.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [
                {'type': 'speak', 'diegetic': true, 'targetItemIds': ['lex_ja_hai']},
              ],
            },
          ],
        },
      ],
    };

Future<void> _seedLexeme(LearningDb db, String id, String concept,
    String form, String gloss) async {
  await db.into(db.concepts).insert(ConceptsCompanion.insert(
      id: concept,
      glossKey: gloss,
      partOfSpeech: 'noun',
      defaultAssetType: const Value('image')));
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
      id: id,
      languageId: 'lang_ja',
      conceptId: concept,
      writtenForm: form,
      reading: form));
}

void main() {
  late LearningDb db;
  late Episode episode;

  setUp(() async {
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    await _seedLexeme(db, 'lex_ja_ame', 'concept_rain', 'あめ', 'rain');
    await _seedLexeme(db, 'lex_ja_kasa', 'concept_umbrella', 'かさ', 'umbrella');
    await _seedLexeme(db, 'lex_ja_hai', 'concept_yes', 'はい', 'yes');
  });
  tearDown(() async => db.close());

  test('debriefOrder: Reihenfolge des ersten Token-Auftritts, Rest in '
      'Budget-Reihenfolge', () {
    expect(debriefOrder(episode), ['lex_ja_kasa', 'lex_ja_ame', 'lex_ja_hai']);
  });

  test('firstAppearancePanel liefert das erste Panel mit dem Token, sonst null',
      () {
    expect(firstAppearancePanel(episode, 'lex_ja_ame')!.index, 1);
    expect(firstAppearancePanel(episode, 'lex_ja_kasa')!.index, 0);
    expect(firstAppearancePanel(episode, 'lex_ja_hai'), isNull);
  });

  test('episodeIntroducing findet die Folge, deren Budget das Item führt', () {
    expect(episodeIntroducing([episode], 'lex_ja_ame'), same(episode));
    expect(episodeIntroducing([episode], 'lex_ja_ghost'), isNull);
    expect(episodeIntroducing(const [], 'lex_ja_ame'), isNull);
  });

  test('debriefItemsFor = Manifest ∩ Karteikasten: nur eingeführte Items, in '
      'Auftrittsreihenfolge (INV-11)', () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    // lex_ja_hai steht im Budget, wurde aber nie übergeben → erscheint nicht.
    final items = await debriefItemsFor(db, episode, 'lang_ja');
    expect(items.map((i) => i.refId), ['lex_ja_kasa', 'lex_ja_ame']);
  });

  test('debriefItemsFor ignoriert Nicht-Lexem-Items (Zeichen/Grammatik folgen '
      'in eigenen Schritten)', () async {
    final ep = Episode.fromJson({
      ..._episodeJson(),
      'budget': {
        'items': [
          {'id': 'char_ja_a', 'refType': 'character'},
        ],
        'glyphs': [],
      },
      'pages': [],
    });
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a', rung: 0);
    expect(await debriefItemsFor(db, ep, 'lang_ja'), isEmpty);
  });

  test('loadDebriefCard: Begegnung + Stelle in der Folge + Erklärungsblock',
      () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    final item = (await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!;
    final card = (await loadDebriefCard(db, item, episode: episode))!;
    expect(card.encounter.writtenForm, 'あめ');
    expect(card.encounter.meaning, 'Regen'); // deutsch via meaningForConcept
    expect(card.firstPanel!.index, 1);
    expect(card.note!.usage, 'Regen. Das Wort vom Zettel.');
    expect(card.note!.variants.single.form, 'おおあめ');
  });

  test('loadDebriefCard ohne Folge: nur die Begegnung; unbekanntes Lexem → null',
      () async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ghost', rung: 1);
    final kasa = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    final card = (await loadDebriefCard(db, kasa))!;
    expect(card.firstPanel, isNull);
    expect(card.note, isNull);
    expect(card.encounter.meaning, 'Schirm');
    final ghost = (await db.getLearnItem('lang_ja:lexeme:lex_ja_ghost'))!;
    expect(await loadDebriefCard(db, ghost), isNull);
  });
}
```

An `test/features/cafe/cafe_inv9_test.dart` anhängen (Imports ergänzen: `package:nihongo_app/features/cafe/cafe_debrief.dart`, `package:nihongo_app/features/story/episode.dart`):

```dart
  test('die Nachbesprechung hat dieselbe einzige Quelle: ein Budget-Item ohne '
      'learn_item erscheint auch dort nicht (INV-11)', () async {
    final episode = Episode.fromJson({
      'id': 'ep_inv',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_himitsu', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [],
    });
    expect(await debriefItemsFor(db, episode, 'lang_ja'), isEmpty);
    // Positiv-Kontrolle: erst die Übergabe (learn_item) legt es auf den Tisch.
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_himitsu',
        rung: 0);
    expect((await debriefItemsFor(db, episode, 'lang_ja')).single.refId,
        'lex_ja_himitsu');
  });
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_debrief_test.dart test/features/cafe/cafe_inv9_test.dart`
Expected: FAIL — `cafe_debrief.dart` existiert nicht.

- [ ] **Step 3: Implementieren** — `lib/features/cafe/cafe_debrief.dart`:

```dart
import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';
import '../../core/i18n/concept_meaning.dart';
import '../../core/ladder/encounter.dart';
import '../../core/ladder/rung_defs.dart';
import '../story/episode.dart';

/// Reihenfolge der Nachbesprechung (Spec Café-Nachbesprechung §3.3): die
/// Budget-Items nach ihrem ersten Auftritt als Token in der Folge; Items ohne
/// Token-Auftritt (z. B. nur über `targetItemIds` eines Sprechmoments) danach
/// in Budget-Reihenfolge.
List<String> debriefOrder(Episode episode) {
  final budgetIds = {for (final i in episode.budget.items) i.id};
  final order = <String>[];
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        final id = token.itemId;
        if (id != null && budgetIds.contains(id) && !order.contains(id)) {
          order.add(id);
        }
      }
    }
  }
  for (final item in episode.budget.items) {
    if (!order.contains(item.id)) order.add(item.id);
  }
  return order;
}

/// Das erste Panel, in dem [itemId] als Token vorkommt — „die Stelle in der
/// Folge" auf der Erklärungskarte. Null, wenn es nirgends als Token steht.
StoryPanel? firstAppearancePanel(Episode episode, String itemId) {
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        if (token.itemId == itemId) return panel;
      }
    }
  }
  return null;
}

/// Die Folge, die [itemId] eingeführt hat (im Budget führt), sonst null.
Episode? episodeIntroducing(List<Episode> episodes, String itemId) {
  for (final episode in episodes) {
    if (episode.budget.items.any((i) => i.id == itemId)) return episode;
  }
  return null;
}

/// Die zweite Item-Quelle des Cafés (Spec §4, INV-11): **Manifest ∩
/// Karteikasten.** Liest ausschließlich `learn_items` — ein Budget-Item ohne
/// Übergabe am Folgen-Ende erscheint nicht; die Nachbesprechung führt nichts
/// ein (INV-8). Reihenfolge: [debriefOrder].
///
/// Dieser Ausbauschritt bedient nur Lexeme; Zeichen (`character`) und
/// Grammatik folgen in eigenen Schritten (Spec §11, 3/4) und werden hier
/// bewusst übersprungen statt halb angezeigt.
Future<List<LearnItem>> debriefItemsFor(
    LearningDb db, Episode episode, String languageId) async {
  final byId = {for (final i in episode.budget.items) i.id: i};
  final items = <LearnItem>[];
  for (final id in debriefOrder(episode)) {
    final ref = byId[id]!;
    if (ref.refType != RefType.lexeme) continue;
    final row = await db.getLearnItem('$languageId:${ref.refType.name}:$id');
    if (row != null) items.add(row);
  }
  return items;
}

/// Inhalt einer Erklärungskarte (Spec §5.4): die Begegnung wie in der
/// Lektion plus das, was nur das Café weiß — die Stelle in der Folge und der
/// Erklärungsblock der Wirtin. Beides optional mit Fallback.
class DebriefCardContent {
  final LexemeEncounter encounter;
  final StoryPanel? firstPanel;
  final DebriefNote? note;

  const DebriefCardContent({
    required this.encounter,
    this.firstPanel,
    this.note,
  });
}

/// Baut die Karte aus Lexemes + Concepts (+ Assets) — dieselben Tabellen wie
/// `ExerciseLoader` und `CafeTurnContent.forItem`. Null, wenn das Lexem oder
/// sein Konzept fehlt (der Aufrufer überspringt das Item, kein Absturz).
/// [episode] optional: liefert Stelle-in-der-Folge und Erklärungsblock; im
/// normalen Besuch ohne Folgen-Kontext zeigt die Karte, was sie hat (§3.5).
Future<DebriefCardContent?> loadDebriefCard(
  LearningDb db,
  LearnItem item, {
  Episode? episode,
}) async {
  if (item.refType != RefType.lexeme.name) return null;
  final lex = await (db.select(db.lexemes)
        ..where((t) => t.id.equals(item.refId)))
      .getSingleOrNull();
  if (lex == null) return null;
  final concept = await (db.select(db.concepts)
        ..where((t) => t.id.equals(lex.conceptId)))
      .getSingleOrNull();
  if (concept == null) return null;
  final asset = await (db.select(db.assets)
        ..where((t) =>
            t.conceptId.equals(lex.conceptId) & t.type.equals('image')))
      .getSingleOrNull();
  return DebriefCardContent(
    encounter: LexemeEncounter(
      writtenForm: lex.writtenForm,
      reading: lex.reading,
      audioText: lex.writtenForm,
      meaning: meaningForConcept(concept.id, fallback: concept.glossKey),
      conceptImagePath: asset?.path,
    ),
    firstPanel:
        episode == null ? null : firstAppearancePanel(episode, item.refId),
    note: episode?.debrief[item.refId],
  );
}
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/cafe/cafe_debrief_test.dart test/features/cafe/cafe_inv9_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_debrief.dart test/features/cafe/cafe_debrief_test.dart test/features/cafe/cafe_inv9_test.dart
git commit -m "feat(cafe): zweite Item-Quelle — Manifest ∩ Karteikasten + Karteninhalt (Nachbesprechung)"
```

---

### Task 5: Erklärungskarte — `EncounterView.extras` + `DebriefCardView`

**Files:**
- Modify: `lib/features/encounter/encounter_view.dart` (neues optionales `extras`-Slot zwischen Begegnungs-Körper und „Verstanden")
- Create: `lib/features/cafe/cafe_debrief_card.dart`
- Test: `test/features/encounter/encounter_view_test.dart` (ein Test anhängen); `test/features/cafe/cafe_debrief_card_test.dart` (neu)

**Interfaces:**
- Consumes: `EncounterView`, `AudioButton` (`lib/widgets/audio_button.dart`), `DebriefCardContent` (Task 4), `DebriefNote`/`DebriefVariant` (Task 1).
- Produces: `EncounterView({…, Widget? extras})`; `DebriefCardView({required DebriefCardContent content, required VoidCallback onDone})` — Keys `cafe-debrief-card`, `cafe-debrief-panel`, `cafe-debrief-usage`, `cafe-debrief-variants-title`, `cafe-debrief-variant-<i>`; der „Verstanden"-Knopf bleibt `encounter-next`.

- [ ] **Step 1: Failing Tests schreiben** — an `test/features/encounter/encounter_view_test.dart` anhängen (nutzt dessen `_wrap`):

```dart
  testWidgets('extras werden zwischen Begegnung und Weiter-Knopf gezeigt',
      (tester) async {
    await tester.pumpWidget(_wrap(EncounterView(
      encounter: const LexemeEncounter(
          writtenForm: 'あめ', reading: 'あめ', audioText: 'あめ', meaning: 'Regen'),
      extras: const Text('Zusatz', key: ValueKey('extras')),
      onDone: () {},
    )));
    expect(find.byKey(const ValueKey('extras')), findsOneWidget);
    expect(find.byKey(const ValueKey('encounter-next')), findsOneWidget);
  });
```

`test/features/cafe/cafe_debrief_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/encounter.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_card.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

const _encounter = LexemeEncounter(
    writtenForm: 'ありがとう',
    reading: 'ありがとう',
    audioText: 'ありがとう',
    meaning: 'danke');

void main() {
  testWidgets('volle Karte: Wort, Bedeutung, Stelle in der Folge, Gebrauch, '
      'zwei Varianten, Verstanden', (tester) async {
    final panel = StoryPanel.fromJson({
      'index': 7,
      'asset': 'assets/story/p08.jpg',
      'bubbles': [],
      'thoughts': [],
      'interactions': [],
    });
    var done = false;
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: DebriefCardContent(
        encounter: _encounter,
        firstPanel: panel,
        note: const DebriefNote(usage: '„danke".', variants: [
          DebriefVariant(
              form: 'ありがとうございます',
              reading: 'ありがとうございます',
              meaning: 'vielen Dank',
              note: 'höflicher'),
          DebriefVariant(form: 'どうも', reading: 'どうも', meaning: 'danke, kurz'),
        ]),
      ),
      onDone: () => done = true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('ありがとう'), findsWidgets); // Form + Lesung
    expect(find.text('danke'), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-1')), findsOneWidget);
    expect(find.text('höflicher'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    expect(done, isTrue);
  });

  testWidgets('ohne Folge und ohne Erklärungsblock: nur die Begegnung, kein '
      'Zusatz', (tester) async {
    await tester.pumpWidget(_wrap(DebriefCardView(
      content: const DebriefCardContent(encounter: _encounter),
      onDone: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('ありがとう'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-debrief-variants-title')),
        findsNothing);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/encounter/encounter_view_test.dart test/features/cafe/cafe_debrief_card_test.dart`
Expected: FAIL — `extras` unbekannt; `cafe_debrief_card.dart` fehlt.

- [ ] **Step 3: `EncounterView` erweitern** — in `lib/features/encounter/encounter_view.dart`:

Feld + Konstruktor:

```dart
  final Encounter encounter;
  final VoidCallback onDone;

  /// Optionaler Zusatz zwischen Begegnung und „Verstanden" — das Café hängt
  /// hier Stelle-in-der-Folge, Gebrauch und Varianten an (Spec
  /// Café-Nachbesprechung §5.4). Null = Lektions-Begegnung wie bisher.
  final Widget? extras;

  const EncounterView({
    super.key,
    required this.encounter,
    required this.onDone,
    this.extras,
  });
```

In `build` nach dem `Padding` mit `_body(context)`:

```dart
        if (extras != null) extras!,
```

- [ ] **Step 4: `DebriefCardView` schreiben** — `lib/features/cafe/cafe_debrief_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../widgets/audio_button.dart';
import '../encounter/encounter_view.dart';
import '../story/episode.dart';
import 'cafe_debrief.dart';

/// Die Erklärungskarte der Wirtin (Spec Café-Nachbesprechung §3.3/§5.4): das
/// Begegnungs-Ritual ([EncounterView], unbenotet, nur „Verstanden") plus der
/// Café-Zusatz — die Stelle in der Folge, der Gebrauch und „man kann auch
/// sagen …". Deutsch, weil hier jemand hilft (Brief §4.4). Jeder Zusatz ist
/// optional; ohne Folge und ohne Erklärungsblock bleibt die nackte Begegnung.
class DebriefCardView extends StatelessWidget {
  final DebriefCardContent content;
  final VoidCallback onDone;

  const DebriefCardView({
    super.key,
    required this.content,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final panel = content.firstPanel;
    final note = content.note;
    final hasExtras = panel != null || note != null;
    return SingleChildScrollView(
      key: const ValueKey('cafe-debrief-card'),
      child: EncounterView(
        encounter: content.encounter,
        onDone: onDone,
        extras: !hasExtras
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (panel != null) ...[
                      Text('Hier hast du es zum ersten Mal gehört:',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.asset(
                          panel.asset,
                          key: const ValueKey('cafe-debrief-panel'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: const Color(0xFFEDEDED)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (note != null) ...[
                      Text(note.usage,
                          key: const ValueKey('cafe-debrief-usage')),
                      if (note.variants.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Man kann auch sagen:',
                            key: const ValueKey('cafe-debrief-variants-title'),
                            style: Theme.of(context).textTheme.labelMedium),
                        for (var i = 0; i < note.variants.length; i++)
                          _VariantRow(
                            key: ValueKey('cafe-debrief-variant-$i'),
                            variant: note.variants[i],
                          ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Eine Variante: Form (hörbar), Lesung falls abweichend, Bedeutung, Notiz.
/// Nur Anzeige — keine Karteikarte, kein Turn (Variante ≠ Item, Spec §4).
class _VariantRow extends StatelessWidget {
  final DebriefVariant variant;

  const _VariantRow({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant.form,
                    style: Theme.of(context).textTheme.titleMedium),
                if (variant.reading != variant.form)
                  Text(variant.reading,
                      style: Theme.of(context).textTheme.labelSmall),
                Text(variant.meaning),
                if (variant.note != null)
                  Text(variant.note!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          AudioButton(text: variant.form, size: 28),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/features/encounter/encounter_view_test.dart test/features/cafe/cafe_debrief_card_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/encounter/encounter_view.dart lib/features/cafe/cafe_debrief_card.dart test/features/encounter/encounter_view_test.dart test/features/cafe/cafe_debrief_card_test.dart
git commit -m "feat(cafe): Erklärungskarte — Begegnung + Stelle in der Folge + Gebrauch + Varianten (Nachbesprechung)"
```

---

### Task 6: `CafeTurnScreen` — vorgegebene Warteschlange + Schlusszeile

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart` (Widget-Felder + Konstruktor; `_load`; Done-Zustand in `build`)
- Test: `test/features/cafe/cafe_turn_screen_queue_test.dart` (neu)

**Interfaces:**
- Consumes: bestehende `CafeTurnScreen`.
- Produces: `CafeTurnScreen({…, List<LearnItem>? initialQueue, String? doneLine})` — `initialQueue` ersetzt die Fälligkeits-Abfrage; `doneLine` erscheint mit Key `cafe-turn-done-line` über „Zurück ins Café".

- [ ] **Step 1: Failing Tests schreiben** — `test/features/cafe/cafe_turn_screen_queue_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';

void main() {
  late LearningDb db;

  setUp(() async {
    db = LearningDb.forTesting();
    await db.into(db.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));
  });
  tearDown(() async => db.close());

  /// Ein Sprosse-1-Item, dessen erster Termin erst morgen ist — heute NICHT
  /// fällig.
  Future<LearnItem> notDueItem() async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 1);
    await (db.update(db.learnItems)
          ..where((t) => t.refId.equals('lex_ja_ame')))
        .write(LearnItemsCompanion(
            dueAt: Value(DateTime.now().add(const Duration(days: 1)))));
    return (await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!;
  }

  testWidgets('ohne initialQueue: ein nicht fälliges Item ergibt keinen Turn '
      '(wie bisher)', (tester) async {
    await notDueItem();
    await tester.pumpWidget(
        MaterialApp(home: CafeTurnScreen(db: db, guest: CafeGuest.wirtin)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsNothing);
  });

  testWidgets('mit initialQueue wird dasselbe Item sofort abgefragt; am Ende '
      'steht die Schlusszeile', (tester) async {
    final item = await notDueItem();
    await tester.pumpWidget(MaterialApp(
      home: CafeTurnScreen(
        db: db,
        guest: CafeGuest.wirtin,
        initialQueue: [item],
        doneLine: 'So, das war die Folge.',
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(find.text('あめ'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-turn-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(find.text('So, das war die Folge.'), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(1));
  });
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_turn_screen_queue_test.dart`
Expected: FAIL — `initialQueue`/`doneLine` unbekannt.

- [ ] **Step 3: Implementieren** — in `lib/features/cafe/cafe_turn_screen.dart`:

Felder nach `final KnowledgeBridge? bridge;`:

```dart
  /// Vorgegebene Warteschlange statt Fälligkeits-Abfrage — Akt 2 der
  /// Nachbesprechung fragt die Items der Folge sofort ab („unmittelbares
  /// Abrufen, aber nie kalt", Spec Café-Nachbesprechung §3.4), auch wenn ihr
  /// erster Termin erst morgen wäre. Null = wie bisher: was fällig ist.
  final List<LearnItem>? initialQueue;

  /// Schlusszeile der Wirtin, wenn die Warteschlange abgearbeitet ist
  /// (Nachbesprechung). Null = nur der Knopf zurück ins Café.
  final String? doneLine;
```

Konstruktor: `this.initialQueue,` und `this.doneLine,` ergänzen.

`_load` ersetzen:

```dart
  Future<void> _load() async {
    final queue = widget.initialQueue ?? await _dueForGuest();
    if (!mounted) return;
    setState(() {
      _queue = List.of(queue);
      _loading = false;
    });
    await _prepareTurn();
  }

  Future<List<LearnItem>> _dueForGuest() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    return due
        .where((i) => guestForRung(i.masteryRung) == widget.guest)
        .toList();
  }
```

Done-Zustand in `build` (der `Center(key: 'cafe-turn-done', …)`-Zweig) ersetzen:

```dart
              : Center(
                  key: const ValueKey('cafe-turn-done'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.doneLine != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(widget.doneLine!,
                              key: const ValueKey('cafe-turn-done-line'),
                              textAlign: TextAlign.center),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Zurück ins Café'),
                      ),
                    ],
                  ),
                )
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/cafe/`
Expected: PASS (alle bestehenden Café-Tests unverändert).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart test/features/cafe/cafe_turn_screen_queue_test.dart
git commit -m "feat(cafe): Turn-Screen nimmt eine vorgegebene Warteschlange und eine Schlusszeile (Nachbesprechung)"
```

---

### Task 7: Wirtin-Texte + `CafeDebriefScreen` (Akt 1 → Akt 2)

**Files:**
- Modify: `lib/features/cafe/cafe_prompts.dart` (drei Funktionen/Konstanten anhängen)
- Create: `lib/features/cafe/cafe_debrief_screen.dart`
- Test: `test/features/cafe/cafe_prompts_debrief_test.dart` (neu); `test/features/cafe/cafe_debrief_screen_test.dart` (neu)

**Interfaces:**
- Consumes: `debriefItemsFor`, `loadDebriefCard` (Task 4), `DebriefCardView` (Task 5), `CafeTurnScreen(initialQueue:, doneLine:)` (Task 6), `StoryProgressStore.debriefIndex/saveDebriefIndex/markDebriefDone` (Task 3), `LadderReview.markEncountered`.
- Produces: `const String wirtinDebriefInvite`, `String wirtinDebriefLine(int index)`, `String wirtinDebriefClosing(int index)`; `CafeDebriefScreen({required LearningDb db, required Episode episode, required StoryProgressStore progressStore, String languageId = 'lang_ja', KnowledgeBridge? bridge})` — Keys `cafe-debrief-screen`, `cafe-debrief-line`, `cafe-debrief-empty`.

- [ ] **Step 1: Failing Tests schreiben** — `test/features/cafe/cafe_prompts_debrief_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_prompts.dart';

void main() {
  test('Wirtin-Zeilen der Nachbesprechung rotieren über mindestens drei '
      'Varianten — ohne Zahlen (INV-10)', () {
    final lines = {for (var i = 0; i < 3; i++) wirtinDebriefLine(i)};
    final closings = {for (var i = 0; i < 3; i++) wirtinDebriefClosing(i)};
    expect(lines, hasLength(3));
    expect(closings, hasLength(3));
    expect(wirtinDebriefLine(3), wirtinDebriefLine(0));
    expect(wirtinDebriefClosing(4), wirtinDebriefClosing(1));
    for (final s in [...lines, ...closings, wirtinDebriefInvite]) {
      expect(RegExp(r'\d').hasMatch(s), isFalse, reason: s);
    }
  });
}
```

`test/features/cafe/cafe_debrief_screen_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_debrief_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

/// かさ zuerst (P0), あめ ab P1 — Auftrittsreihenfolge kasa, ame.
Map<String, dynamic> _episodeJson() => {
      'id': 'ep_test_debrief',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
          {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {
          'usage': 'Regen. Das Wort vom Zettel.',
          'variants': [
            {'form': 'おおあめ', 'reading': 'おおあめ', 'meaning': 'starker Regen'},
          ],
        },
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'かさ',
                  'tokens': [
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ、かさ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                    {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    };

Future<void> _seedLexeme(LearningDb db, String id, String concept,
    String form, String gloss) async {
  await db.into(db.concepts).insert(ConceptsCompanion.insert(
      id: concept,
      glossKey: gloss,
      partOfSpeech: 'noun',
      defaultAssetType: const Value('image')));
  await db.into(db.lexemes).insert(LexemesCompanion.insert(
      id: id,
      languageId: 'lang_ja',
      conceptId: concept,
      writtenForm: form,
      reading: form));
}

void main() {
  late LearningDb db;
  late Episode episode;
  late StoryProgressStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
    db = LearningDb.forTesting();
    episode = Episode.fromJson(_episodeJson());
    await _seedLexeme(db, 'lex_ja_ame', 'concept_rain', 'あめ', 'rain');
    await _seedLexeme(db, 'lex_ja_kasa', 'concept_umbrella', 'かさ', 'umbrella');
  });
  tearDown(() async => db.close());

  Future<int> rungOf(String id) async =>
      (await db.getLearnItem('lang_ja:lexeme:$id'))!.masteryRung;

  Widget screen() =>
      _wrap(CafeDebriefScreen(db: db, episode: episode, progressStore: store));

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('Akt 1 erklärt in Auftrittsreihenfolge, hebt Sprosse 0 → 1 und '
      'geht in Akt 2 über', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 0);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-line')), findsOneWidget);
    // Erste Karte: かさ (erstes Token der Folge), ohne Erklärungsblock.
    expect(find.text('かさ'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);

    await tapVerstanden(tester);
    expect(await rungOf('lex_ja_kasa'), 1);
    expect(await store.debriefIndex(episode.id), 1);
    // Zweite Karte: あめ mit Gebrauch und Variante.
    expect(find.text('あめ'), findsWidgets);
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-variant-0')), findsOneWidget);

    await tapVerstanden(tester);
    expect(await rungOf('lex_ja_ame'), 1);
    expect(await store.isDebriefDone(episode.id), isTrue);
    // Akt 2: die Wirtin fragt dieselben Items als Turns ab — sofort, obwohl
    // ihr erster Termin nach der Begegnung erst später wäre.
    expect(find.byKey(const ValueKey('cafe-turn-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });

  testWidgets('Akt 2 endet mit der Schlusszeile der Wirtin; Varianten wurden '
      'nie zu Items', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 0);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tapVerstanden(tester);
    await tapVerstanden(tester);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cafe-turn-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const ValueKey('cafe-turn-done-line')), findsOneWidget);
    expect(await db.select(db.reviewLog).get(), hasLength(2));
    // Variante ≠ Item (INV-8): genau die Manifest-Items sind Karteikarten.
    final ids = (await db.select(db.learnItems).get()).map((i) => i.refId).toSet();
    expect(ids, {'lex_ja_ame', 'lex_ja_kasa'});
  });

  testWidgets('Wiederkommen setzt beim ersten offenen Item fort', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    await store.saveDebriefIndex(episode.id, 1);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('あめ'), findsWidgets);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets('ein Item, das schon auf Sprosse 1 steht, bekommt die Karte, '
      'bleibt aber unberührt', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_kasa', rung: 1);
    final before = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('かさ'), findsWidgets);
    await tapVerstanden(tester);
    final after = (await db.getLearnItem('lang_ja:lexeme:lex_ja_kasa'))!;
    expect(after.masteryRung, 1);
    expect(after.dueAt, before.dueAt);
  });

  testWidgets('kein eingeführtes Item → die Wirtin nickt nur (leer, ohne Zahl)',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-empty')), findsOneWidget);
    expect(find.textContaining('0'), findsNothing);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_prompts_debrief_test.dart test/features/cafe/cafe_debrief_screen_test.dart`
Expected: FAIL — Funktionen/Datei fehlen.

- [ ] **Step 3: Wirtin-Texte** — an `lib/features/cafe/cafe_prompts.dart` anhängen:

```dart
/// Die Wirtin lädt zur Nachbesprechung ein (Belegung, Spec
/// Café-Nachbesprechung §3.6) — kein Zähler, keine Zahl, nur ein Satz.
const String wirtinDebriefInvite = 'Wollen wir über die Folge reden?';

/// Was die Wirtin vor einer Erklärungskarte sagt; rotiert nach Kartenindex.
String wirtinDebriefLine(int index) {
  const lines = [
    'Setz dich. Das hier hattest du in der Folge:',
    'Und dann war da noch das — erinnerst du dich?',
    'Das nächste. Lass dir Zeit.',
  ];
  return lines[index % lines.length];
}

/// Schlusszeile nach Akt 2 (mindestens drei, rotierend — Brief §4.5).
String wirtinDebriefClosing(int index) {
  const lines = [
    'So. Das war die Folge. Der Tee ist noch warm.',
    'Gut. Mehr muss es heute nicht sein.',
    'Das sitzt fürs Erste. Komm wieder, wenn dir etwas fällig ist.',
  ];
  return lines[index % lines.length];
}
```

- [ ] **Step 4: `CafeDebriefScreen`** — `lib/features/cafe/cafe_debrief_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import '../story/story_progress_store.dart';
import 'cafe_debrief.dart';
import 'cafe_debrief_card.dart';
import 'cafe_occupancy.dart';
import 'cafe_prompts.dart';
import 'cafe_turn_screen.dart';

/// Die Nachbesprechung einer Folge (Spec Café-Nachbesprechung §3.3–§3.6).
/// Akt 1: die Wirtin erklärt jedes Item der Folge (Erklärungskarte, nur
/// „Verstanden"; ein Sprosse-0-Item wird dabei begegnet → Sprosse 1). Akt 2:
/// dieselben Items als gewohnte Café-Turns ([CafeTurnScreen] mit
/// vorgegebener Warteschlange). Item-Quelle ist ausschließlich
/// [debriefItemsFor] (Manifest ∩ Karteikasten, INV-8/INV-11). Der Stand von
/// Akt 1 wird im [StoryProgressStore] gemerkt — Abbruch setzt beim ersten
/// offenen Item fort; kein Zähler, kein Häkchen (INV-10).
class CafeDebriefScreen extends StatefulWidget {
  final LearningDb db;
  final Episode episode;
  final StoryProgressStore progressStore;
  final String languageId;
  final KnowledgeBridge? bridge;

  const CafeDebriefScreen({
    super.key,
    required this.db,
    required this.episode,
    required this.progressStore,
    this.languageId = 'lang_ja',
    this.bridge,
  });

  @override
  State<CafeDebriefScreen> createState() => _CafeDebriefScreenState();
}

enum _DebriefPhase { loading, explain, empty }

class _CafeDebriefScreenState extends State<CafeDebriefScreen> {
  late final LadderReview _ladder =
      LadderReview(widget.db, bridge: widget.bridge);

  List<LearnItem> _items = [];
  int _index = 0;
  DebriefCardContent? _card;
  _DebriefPhase _phase = _DebriefPhase.loading;

  String get _languageCode => widget.languageId.replaceFirst('lang_', '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items =
        await debriefItemsFor(widget.db, widget.episode, widget.languageId);
    final start = await widget.progressStore.debriefIndex(widget.episode.id);
    if (!mounted) return;
    _items = items;
    _index = start.clamp(0, items.length);
    if (items.isEmpty) {
      setState(() => _phase = _DebriefPhase.empty);
      return;
    }
    await _prepareCard();
  }

  Future<void> _prepareCard() async {
    if (_index >= _items.length) {
      await _finishExplain();
      return;
    }
    final card = await loadDebriefCard(widget.db, _items[_index],
        episode: widget.episode);
    if (!mounted) return;
    if (card == null) {
      // Lexem/Konzept fehlt: überspringen, nicht abstürzen (Spec §5.3).
      _index++;
      await _prepareCard();
      return;
    }
    setState(() {
      _card = card;
      _phase = _DebriefPhase.explain;
    });
  }

  Future<void> _cardDone() async {
    final item = _items[_index];
    // Erst-Erklärung = Begegnung: Sprosse 0 → 1 wie in der Lektion. Items,
    // die ein diegetischer Moment schon auf Sprosse 1 gehoben hat, bleiben
    // unberührt — die Karte ist keine zweite Einführung (Spec §3.3).
    if (item.masteryRung == 0) {
      await _ladder.markEncountered(item, languageCode: _languageCode);
    }
    _index++;
    await widget.progressStore.saveDebriefIndex(widget.episode.id, _index);
    if (!mounted) return;
    await _prepareCard();
  }

  Future<void> _finishExplain() async {
    await widget.progressStore.markDebriefDone(widget.episode.id);
    // Akt 2 fragt dieselben Items ab — frisch aus der DB, denn Akt 1 hat
    // Sprosse und Termin verändert und `submit` rechnet mit den Zeilenwerten.
    final refreshed = <LearnItem>[];
    for (final item in _items) {
      final row = await widget.db.getLearnItem(item.id);
      if (row != null) refreshed.add(row);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => CafeTurnScreen(
        db: widget.db,
        guest: CafeGuest.wirtin,
        languageId: widget.languageId,
        bridge: widget.bridge,
        initialQueue: refreshed,
        doneLine: wirtinDebriefClosing(refreshed.length),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('cafe-debrief-screen'),
      appBar: AppBar(title: const Text('Die Wirtin')),
      body: switch (_phase) {
        _DebriefPhase.loading =>
          const Center(child: CircularProgressIndicator()),
        _DebriefPhase.empty => Center(
            key: const ValueKey('cafe-debrief-empty'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Die Wirtin nickt. Über diese Folge gibt es noch nichts '
                    'zu erzählen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zurück ins Café'),
                  ),
                ],
              ),
            ),
          ),
        _DebriefPhase.explain => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  wirtinDebriefLine(_index),
                  key: const ValueKey('cafe-debrief-line'),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              Expanded(
                child: DebriefCardView(content: _card!, onDone: _cardDone),
              ),
            ],
          ),
      },
    );
  }
}
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/features/cafe/cafe_prompts_debrief_test.dart test/features/cafe/cafe_debrief_screen_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_prompts.dart lib/features/cafe/cafe_debrief_screen.dart test/features/cafe/cafe_prompts_debrief_test.dart test/features/cafe/cafe_debrief_screen_test.dart
git commit -m "feat(cafe): Nachbesprechung — Akt 1 die Wirtin erklärt, Akt 2 fragt nach (Nachbesprechung)"
```

---

### Task 8: `CafeTurnScreen` — Sprosse-0-Karte zuerst + „Erklär's mir nochmal" + Folgen-Kontext

**Files:**
- Modify: `lib/features/cafe/cafe_turn_screen.dart` (Imports; Feld `episodes`; State `_encounterCard`; `_prepareTurn`; neue Methoden `_encounterDone`, `_explainAgain`; `build`/`_buildTurn`)
- Modify: `lib/features/cafe/cafe_debrief_screen.dart` (`_finishExplain`: `episodes: [widget.episode]` mitgeben)
- Test: `test/features/cafe/cafe_turn_screen_explain_test.dart` (neu)

**Interfaces:**
- Consumes: `loadDebriefCard`, `episodeIntroducing` (Task 4), `DebriefCardView` (Task 5), `LadderReview.markEncountered`, bestehendes `outcomeFor(hintUsed:)`.
- Produces: `CafeTurnScreen({…, List<Episode> episodes = const []})`; Keys `cafe-turn-encounter` (Karte vor dem ersten Turn eines Sprosse-0-Items), `cafe-turn-explain` (Knopf), `cafe-turn-explain-sheet` (Bottom-Sheet). „Erklär's mir nochmal" setzt `_hintUsed` → `CafeOutcome.hinted` → `hard`.

- [ ] **Step 1: Failing Tests schreiben** — `test/features/cafe/cafe_turn_screen_explain_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_turn_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

Episode _episode() => Episode.fromJson({
      'id': 'ep_t',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_ame', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'debrief': {
        'lex_ja_ame': {'usage': 'Regen. Das Wort vom Zettel.'},
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'bubbles': [
                {
                  'speakerId': 'x',
                  'text': 'あめ',
                  'tokens': [
                    {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
                  ],
                },
              ],
              'thoughts': [],
              'interactions': [],
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
        id: 'concept_rain',
        glossKey: 'rain',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_ame',
        languageId: 'lang_ja',
        conceptId: 'concept_rain',
        writtenForm: 'あめ',
        reading: 'あめ'));
  });
  tearDown(() async => db.close());

  Future<void> tapVerstanden(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('ein Sprosse-0-Item bekommt zuerst die Erklärungskarte, dann '
      'den Turn (nie kalt)', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 0);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.wirtin)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-encounter')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsNothing);

    await tapVerstanden(tester);
    expect((await db.getLearnItem('lang_ja:lexeme:lex_ja_ame'))!.masteryRung, 1);
    expect(find.byKey(const ValueKey('cafe-turn-encounter')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-turn-prompt')), findsOneWidget);
    // Der Turn bewertet mit der frischen Zeile (Sprosse 1), kein Absturz.
    await tester.tap(find.byKey(const ValueKey('cafe-turn-known')));
    await tester.pumpAndSettle();
    expect(await db.select(db.reviewLog).get(), hasLength(1));
  });

  testWidgets('„Erklär\'s mir nochmal" öffnet die Karte und zählt als '
      'Hinweis → hard', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 3);
    await tester.pumpWidget(
        _wrap(CafeTurnScreen(db: db, guest: CafeGuest.schulkind)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-turn-explain-sheet')), findsOneWidget);
    // Ohne Folgen-Kontext: die nackte Begegnung.
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsNothing);
    await tapVerstanden(tester);
    expect(find.byKey(const ValueKey('cafe-turn-explain-sheet')), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('cafe-turn-input')), 'あめ');
    await tester.tap(find.byKey(const ValueKey('cafe-turn-submit')));
    await tester.pumpAndSettle();
    expect((await db.select(db.reviewLog).get()).single.result, 'hard');
  });

  testWidgets('mit Folgen-Kontext zeigt die Karte Gebrauch und Stelle in der '
      'Folge', (tester) async {
    await db.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame', rung: 3);
    await tester.pumpWidget(_wrap(CafeTurnScreen(
        db: db, guest: CafeGuest.schulkind, episodes: [_episode()])));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-turn-explain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-usage')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-panel')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_turn_screen_explain_test.dart`
Expected: FAIL — `episodes` unbekannt, Keys nicht gefunden.

- [ ] **Step 3: Implementieren** — in `lib/features/cafe/cafe_turn_screen.dart`:

Imports ergänzen:

```dart
import '../story/episode.dart';
import 'cafe_debrief.dart';
import 'cafe_debrief_card.dart';
```

Feld nach `doneLine`:

```dart
  /// Folgen, aus denen die Erklärungskarte Stelle-in-der-Folge und
  /// Erklärungsblock ziehen darf (Nachbesprechung: die eine Folge; normaler
  /// Besuch: alle gebündelten). Leer = Karte zeigt, was sie hat (§3.5).
  final List<Episode> episodes;
```

Konstruktor: `this.episodes = const [],`.

State-Feld nach `String? _followUp;`:

```dart
  /// Sprosse 0 = noch nie erklärt: erst die Karte, dann der Turn — die Regel
  /// der Empfang-Spec („nie kalt"), jetzt auch im Café (Spec §3.5).
  DebriefCardContent? _encounterCard;
```

`_prepareTurn` — den Block ab `setState(() { _content = content; …` ersetzen:

```dart
    final item = _queue[_index];
    DebriefCardContent? encounterCard;
    if (item.masteryRung == 0) {
      encounterCard = await loadDebriefCard(widget.db, item,
          episode: episodeIntroducing(widget.episodes, item.refId));
      if (!mounted) return;
    }
    setState(() {
      _content = content;
      _encounterCard = encounterCard;
      _hintUsed = false;
      _revealed = false;
      _followUp = null;
      _input.clear();
    });
```

Neue Methoden nach `_useHint`:

```dart
  Future<void> _encounterDone() async {
    final item = _queue[_index];
    await _ladder.markEncountered(item,
        languageCode: widget.languageId.replaceFirst('lang_', ''));
    // `submit` rechnet mit den Zeilenwerten — nach der Begegnung frisch lesen.
    final refreshed = await widget.db.getLearnItem(item.id);
    if (!mounted) return;
    setState(() {
      if (refreshed != null) _queue[_index] = refreshed;
      _encounterCard = null;
    });
  }

  /// „Erklär's mir nochmal" (Spec §3.5): die volle Erklärungskarte — zählt
  /// als Hinweis (→ hinted → hard, Brief §4.4), nicht als Fehler, nicht
  /// folgenlos. Ohne Karte (Lexem fehlt) passiert nichts.
  Future<void> _explainAgain() async {
    final item = _queue[_index];
    final card = await loadDebriefCard(widget.db, item,
        episode: episodeIntroducing(widget.episodes, item.refId));
    if (card == null || !mounted) return;
    setState(() {
      _hintUsed = true;
      _revealed = true;
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        key: const ValueKey('cafe-turn-explain-sheet'),
        height: MediaQuery.of(sheetContext).size.height * 0.85,
        child: DebriefCardView(
          content: card,
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    );
  }
```

In `build`: `: _buildTurn(_content!)` ersetzen durch

```dart
              : _encounterCard != null
                  ? _buildEncounter(_encounterCard!)
                  : _buildTurn(_content!),
```

Neue Methode vor `_buildTurn`:

```dart
  Widget _buildEncounter(DebriefCardContent card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text('Das hier ist neu für dich — hör erst mal zu.',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
        Expanded(
          child: DebriefCardView(
            key: const ValueKey('cafe-turn-encounter'),
            content: card,
            onDone: _encounterDone,
          ),
        ),
      ],
    );
  }
```

In `_buildTurn`, in der `Column` nach `const SizedBox(height: 16),` (dem zweiten, direkt vor `if (followUp == null) ..._buildAnswerControls(content)`) einfügen:

```dart
          if (followUp == null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('cafe-turn-explain'),
                onPressed: _explainAgain,
                child: const Text("Erklär's mir nochmal"),
              ),
            ),
```

In `lib/features/cafe/cafe_debrief_screen.dart`, `_finishExplain`: dem `CafeTurnScreen(...)` die Zeile `episodes: [widget.episode],` mitgeben.

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/cafe/`
Expected: PASS — inklusive aller bestehenden Turn-Screen-Tests (sie starten bei Sprosse ≥ 1 und tippen nie `cafe-turn-explain`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/cafe/cafe_turn_screen.dart lib/features/cafe/cafe_debrief_screen.dart test/features/cafe/cafe_turn_screen_explain_test.dart
git commit -m "feat(cafe): Sprosse-0-Karte vor dem ersten Turn + „Erklär's mir nochmal" als Hinweis (Nachbesprechung)"
```

---

### Task 9: Belegung + `CafeScreen` — die Wirtin lädt ein, Auto-Öffnen

**Files:**
- Modify: `lib/features/cafe/cafe_occupancy.dart` (`CafeOccupancy`: Feld `pendingDebrief`, `fromDueItems(…, {pendingDebrief})`)
- Modify: `lib/features/cafe/cafe_screen.dart` (Felder `episodes`, `debriefEpisode`, `progressStore`, `openDebriefOnEntry`; `_load`; Wirtin-Kachel; `_openDebrief`)
- Test: `test/features/cafe/cafe_occupancy_test.dart` (ein Test anhängen, in der Gruppe `CafeOccupancy.fromDueItems`); `test/features/cafe/cafe_screen_debrief_test.dart` (neu)

**Interfaces:**
- Consumes: `CafeDebriefScreen` (Task 7), `StoryProgressStore.isDebriefPending` (Task 3), `wirtinDebriefInvite` (Task 7), `CafeTurnScreen(episodes:)` (Task 8).
- Produces: `CafeOccupancy(Set<CafeGuest> present, {bool pendingDebrief = false})`, `CafeOccupancy.fromDueItems(List<LearnItem>, {bool pendingDebrief = false})`; `CafeScreen({…, List<Episode> episodes = const [], Episode? debriefEpisode, StoryProgressStore? progressStore, bool openDebriefOnEntry = false})`; Key `cafe-debrief-invite` (Untertitel der Wirtin-Kachel).

- [ ] **Step 1: Failing Tests schreiben** — an `test/features/cafe/cafe_occupancy_test.dart` innerhalb der Gruppe `CafeOccupancy.fromDueItems (via a real due queue)` anhängen:

```dart
    test('offene Nachbesprechung → die Wirtin ist da, auch wenn nichts fällig '
        'ist; ohne bleibt der Leerzustand', () async {
      final due = await db.getDueItems('lang_ja', limit: 500);
      final occ = CafeOccupancy.fromDueItems(due, pendingDebrief: true);
      expect(occ.present, {CafeGuest.wirtin});
      expect(occ.pendingDebrief, isTrue);
      expect(occ.isEmpty, isFalse);
      expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
    });
```

`test/features/cafe/cafe_screen_debrief_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal-Folge ohne Panels: hier geht es um Belegung und Einladung, nicht
/// um den Ablauf der Nachbesprechung (cafe_debrief_screen_test.dart).
final _episode = Episode.fromJson({
  'id': 'ep_x',
  'seasonId': 's',
  'orderIndex': 1,
  'title': 'T',
  'locale': 'ja',
  'era': 'e',
  'budget': {'items': [], 'glyphs': []},
  'pages': [],
});

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  Future<StoryProgressStore> storeWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    return StoryProgressStore(await SharedPreferences.getInstance());
  }

  testWidgets('offene Nachbesprechung: die Wirtin ist da und lädt ein — ohne '
      'Zahl', (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-guest-wirtin')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsOneWidget);
    expect(find.textContaining('fällig'), findsNothing);
  });

  testWidgets('Tipp auf die einladende Wirtin öffnet die Nachbesprechung',
      (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-guest-wirtin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
  });

  testWidgets('erledigte Nachbesprechung: keine Einladung, Café leer wie zuvor',
      (tester) async {
    final store = await storeWith(
        {'story_completed_ep_x': true, 'story_debrief_done_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsNothing);
  });

  testWidgets('openDebriefOnEntry öffnet die Nachbesprechung von selbst; '
      'zurück → der normale Raum', (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(
            db: db,
            debriefEpisode: _episode,
            progressStore: store,
            openDebriefOnEntry: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    await tester.tap(find.text('Zurück ins Café'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_occupancy_test.dart test/features/cafe/cafe_screen_debrief_test.dart`
Expected: FAIL — Parameter unbekannt.

- [ ] **Step 3: `CafeOccupancy`** — in `lib/features/cafe/cafe_occupancy.dart` die Klasse ersetzen:

```dart
class CafeOccupancy {
  final Set<CafeGuest> present;

  /// Eine Nachbesprechung ist offen (Spec Café-Nachbesprechung §3.6): die
  /// Wirtin ist dann anwesend, auch wenn sonst nichts fällig ist, und lädt
  /// ein statt abzufragen. Belegung, kein Zähler (INV-10).
  final bool pendingDebrief;

  const CafeOccupancy(this.present, {this.pendingDebrief = false});

  bool get isEmpty => present.isEmpty;

  factory CafeOccupancy.fromDueItems(List<LearnItem> dueItems,
      {bool pendingDebrief = false}) {
    return CafeOccupancy({
      for (final item in dueItems) guestForRung(item.masteryRung),
      if (pendingDebrief) CafeGuest.wirtin,
    }, pendingDebrief: pendingDebrief);
  }
}
```

- [ ] **Step 4: `CafeScreen`** — in `lib/features/cafe/cafe_screen.dart`:

Imports ergänzen:

```dart
import '../story/episode.dart';
import '../story/story_progress_store.dart';
import 'cafe_debrief_screen.dart';
import 'cafe_prompts.dart';
```

Felder nach `final KnowledgeBridge? bridge;`:

```dart
  /// Alle gebündelten Folgen — Kontext für „Erklär's mir nochmal" im Turn.
  final List<Episode> episodes;

  /// Die Folge mit offener Nachbesprechung (von der Route ermittelt), sonst
  /// null. Zusammen mit [progressStore] macht sie die Wirtin anwesend und
  /// ihren Tisch zur Einladung (Spec Café-Nachbesprechung §3.6).
  final Episode? debriefEpisode;
  final StoryProgressStore? progressStore;

  /// True = die Nachbesprechung öffnet sich beim Betreten von selbst (Weg
  /// „Ins Café" von der Endkarte, §3.2). Danach: der normale Café-Raum.
  final bool openDebriefOnEntry;
```

Konstruktor: `this.episodes = const [], this.debriefEpisode, this.progressStore, this.openDebriefOnEntry = false,` ergänzen.

State: `_load` ersetzen und Hilfsmethoden ergänzen:

```dart
  CafeOccupancy? _occupancy;
  bool _debriefPending = false;
  bool _autoOpened = false;

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    final pending = await _isDebriefPending();
    if (!mounted) return;
    setState(() {
      _debriefPending = pending;
      _occupancy = CafeOccupancy.fromDueItems(due, pendingDebrief: pending);
    });
    if (pending && widget.openDebriefOnEntry && !_autoOpened) {
      _autoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDebrief();
      });
    }
  }

  Future<bool> _isDebriefPending() async {
    final episode = widget.debriefEpisode;
    final store = widget.progressStore;
    if (episode == null || store == null) return false;
    return store.isDebriefPending(episode.id);
  }

  Future<void> _openDebrief() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CafeDebriefScreen(
        db: widget.db,
        episode: widget.debriefEpisode!,
        progressStore: widget.progressStore!,
        languageId: widget.languageId,
        bridge: widget.bridge,
      ),
    ));
    if (mounted) _load();
  }
```

Die `ListTile` der Gäste ersetzen:

```dart
                        ListTile(
                          key: ValueKey(_keys[guest]!),
                          title: Text(_labels[guest]!),
                          subtitle: guest == CafeGuest.wirtin && _debriefPending
                              ? const Text(wirtinDebriefInvite,
                                  key: ValueKey('cafe-debrief-invite'))
                              : null,
                          onTap: () async {
                            if (guest == CafeGuest.wirtin && _debriefPending) {
                              await _openDebrief();
                              return;
                            }
                            await Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                              builder: (_) => CafeTurnScreen(
                                db: widget.db,
                                guest: guest,
                                languageId: widget.languageId,
                                bridge: widget.bridge,
                                episodes: widget.episodes,
                              ),
                            ));
                            // On return, the due state may have changed —
                            // recompute this session's occupancy (still
                            // once-per-visit, just refreshed after a turn
                            // set).
                            if (mounted) _load();
                          },
                        ),
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/features/cafe/`
Expected: PASS (bestehende `cafe_screen_test.dart`-Tests: ohne `debriefEpisode` unverändert).

- [ ] **Step 6: Commit**

```bash
git add lib/features/cafe/cafe_occupancy.dart lib/features/cafe/cafe_screen.dart test/features/cafe/cafe_occupancy_test.dart test/features/cafe/cafe_screen_debrief_test.dart
git commit -m "feat(cafe): offene Nachbesprechung macht die Wirtin anwesend — Einladung statt Zähler (Nachbesprechung)"
```

---

### Task 10: Folgen-Registry + `CafeRoute(debriefEpisodeId)`

**Files:**
- Create: `lib/features/story/episode_registry.dart`
- Modify: `lib/features/story/story_route.dart` (`storyEpisodeProvider` liest die Registry)
- Modify: `lib/features/cafe/cafe_route.dart` (Provider `cafeDebriefProvider`, Parameter `debriefEpisodeId`)
- Test: `test/features/cafe/cafe_route_test.dart` (Prefs-Mock ergänzen); `test/features/cafe/cafe_route_debrief_test.dart` (neu)

**Interfaces:**
- Consumes: `loadFolge01()`, `StoryProgressStore.isDebriefPending` (Task 3), `CafeScreen(episodes:, debriefEpisode:, progressStore:, openDebriefOnEntry:)` (Task 9).
- Produces: `final storyEpisodesProvider = Provider<List<Episode>>`; `final cafeDebriefProvider = FutureProvider.autoDispose<({StoryProgressStore store, Episode? pending})>`; `CafeRoute({String? debriefEpisodeId})` — `/review` bleibt `const CafeRoute()`.

- [ ] **Step 1: Failing Tests schreiben** — in `test/features/cafe/cafe_route_test.dart` den Import `package:shared_preferences/shared_preferences.dart` ergänzen und als erste Zeile des bestehenden Tests `SharedPreferences.setMockInitialValues({});` einfügen. Neu `test/features/cafe/cafe_route_debrief_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _folge01 = 'ep_ja_shotengai_01';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  Widget app(Widget home) => ProviderScope(
        overrides: [learningDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: home),
      );

  testWidgets('offene Nachbesprechung von Folge 01 → die Wirtin lädt im '
      'Café-Tab ein', (tester) async {
    SharedPreferences.setMockInitialValues({'story_completed_$_folge01': true});
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });

  testWidgets('debriefEpisodeId + offen → die Nachbesprechung öffnet sich von '
      'selbst', (tester) async {
    SharedPreferences.setMockInitialValues({'story_completed_$_folge01': true});
    await tester.pumpWidget(app(const CafeRoute(debriefEpisodeId: _folge01)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
  });

  testWidgets('debriefEpisodeId ohne offene Nachbesprechung → normaler Besuch',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(const CafeRoute(debriefEpisodeId: _folge01)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/cafe/cafe_route_debrief_test.dart`
Expected: FAIL — `debriefEpisodeId` unbekannt.

- [ ] **Step 3: Registry** — `lib/features/story/episode_registry.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'episode.dart';
import 'episodes/folge_01_regen.dart';

/// Alle gebündelten Folgen in Serienreihenfolge — die eine Stelle, die weiß,
/// welche Folgen es gibt (Reader, Café-Nachbesprechung). Heute: Folge 01.
/// Beim ersten Zugriff validiert: ein Schema-Verstoß wirft und erscheint
/// ehrlich als Fehler statt still falschen Inhalt zu zeigen.
final storyEpisodesProvider =
    Provider<List<Episode>>((ref) => [loadFolge01()]);
```

In `lib/features/story/story_route.dart`: Import `episode_registry.dart` ergänzen und

```dart
final storyEpisodeProvider = Provider<Episode>((ref) => loadFolge01());
```

ersetzen durch

```dart
/// Folge 01 — die erste Folge der Registry (W3 kennt genau eine Route).
final storyEpisodeProvider =
    Provider<Episode>((ref) => ref.watch(storyEpisodesProvider).first);
```

- [ ] **Step 4: `CafeRoute`** — `lib/features/cafe/cafe_route.dart` komplett ersetzen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../story/episode.dart';
import '../story/episode_registry.dart';
import '../story/story_progress_store.dart';
import 'cafe_screen.dart';

/// Was das Café über Folgen wissen muss: der Fortschritts-Store und die erste
/// Folge mit offener Nachbesprechung (Spec Café-Nachbesprechung §3.6), sonst
/// null. autoDispose: bei jedem Betreten frisch — nach einer erledigten
/// Nachbesprechung ist die Einladung beim nächsten Besuch weg.
final cafeDebriefProvider = FutureProvider.autoDispose<
    ({StoryProgressStore store, Episode? pending})>((ref) async {
  final episodes = ref.watch(storyEpisodesProvider);
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  for (final episode in episodes) {
    if (await store.isDebriefPending(episode.id)) {
      return (store: store, pending: episode);
    }
  }
  return (store: store, pending: null);
});

/// Routes the café into the app in place of the bare SRS review feed
/// (brief §4 — the café replaces the review screen entirely). Pulls the
/// on-ramp [LearningDb] and the optional knowledge bridge from providers and
/// hands them to [CafeScreen], so café reviews project into the shared mining
/// store exactly as the old ReviewScreen did.
class CafeRoute extends ConsumerWidget {
  /// Folge, deren Nachbesprechung beim Betreten von selbst aufgehen soll
  /// (Weg „Ins Café" von der Endkarte). Ist sie nicht offen — nicht zu Ende
  /// gelesen oder schon nachbesprochen —, ist es ein normaler Besuch.
  final String? debriefEpisodeId;

  const CafeRoute({super.key, this.debriefEpisodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final episodes = ref.watch(storyEpisodesProvider);
    final deps = ref.watch(cafeDebriefProvider);
    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Ohne Prefs (sollte nie passieren) bleibt das Café das Café — nur
      // ohne Einladung.
      error: (_, _) => CafeScreen(
          db: db, bridge: bridge, languageId: 'lang_ja', episodes: episodes),
      data: (d) => CafeScreen(
        db: db,
        bridge: bridge,
        languageId: 'lang_ja',
        episodes: episodes,
        debriefEpisode: d.pending,
        progressStore: d.store,
        openDebriefOnEntry:
            debriefEpisodeId != null && d.pending?.id == debriefEpisodeId,
      ),
    );
  }
}
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/features/cafe/ test/features/story/story_route_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/episode_registry.dart lib/features/story/story_route.dart lib/features/cafe/cafe_route.dart test/features/cafe/cafe_route_test.dart test/features/cafe/cafe_route_debrief_test.dart
git commit -m "feat(cafe): Folgen-Registry + CafeRoute öffnet eine offene Nachbesprechung (Nachbesprechung)"
```

---

### Task 11: Reader-Endkarte „Ins Café"/„Später" + `StoryRoute` → Café

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (Feld `onEnterCafe`; Endkarte in `build`)
- Modify: `lib/features/story/story_route.dart` (Import `../cafe/cafe_route.dart`; `onEnterCafe` verdrahten)
- Test: `test/features/story/story_reader_end_card_test.dart` (neu); `test/features/story/story_route_cafe_test.dart` (neu)

**Interfaces:**
- Consumes: `CafeRoute(debriefEpisodeId:)` (Task 10), `EpisodeSrsHandoff.introduceEpisode` (idempotent).
- Produces: `StoryReaderScreen({…, Future<void> Function()? onEnterCafe})`; Endkarte mit `story-end-cafe` („Ins Café", primär) + `story-end-done` („Später") wenn gesetzt, sonst `story-end-done` („Zurück zum Lesen") wie bisher.

- [ ] **Step 1: Failing Tests schreiben** — `test/features/story/story_reader_end_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Episode _twoPanels() => Episode.fromJson({
      'id': 'ep_end',
      'seasonId': 's',
      'orderIndex': 1,
      'title': 'T',
      'locale': 'ja',
      'era': 'e',
      'outro': 'Hinter dieser Tür fängt der Rest an.',
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            for (var i = 0; i < 2; i++)
              {
                'index': i,
                'asset': 'assets/comic/placeholder_page.png',
                'bubbles': [],
                'thoughts': [],
                'interactions': [],
              },
          ],
        },
      ],
    });

void main() {
  late StoryProgressStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = StoryProgressStore(await SharedPreferences.getInstance());
  });

  Widget reader({Future<void> Function()? onEnterCafe}) => MaterialApp(
        home: StoryReaderScreen(
          episode: _twoPanels(),
          progressStore: store,
          speak: (_) async {},
          dictionaryEntries: const [],
          knownIds: const {},
          onEnterCafe: onEnterCafe,
        ),
      );

  Future<void> readToEnd(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
  }

  testWidgets('mit onEnterCafe: „Ins Café" (ruft den Weg) und „Später"',
      (tester) async {
    var entered = false;
    await tester.pumpWidget(reader(onEnterCafe: () async => entered = true));
    await readToEnd(tester);
    expect(find.byKey(const ValueKey('story-end-cafe')), findsOneWidget);
    expect(find.text('Ins Café'), findsOneWidget);
    expect(find.byKey(const ValueKey('story-end-done')), findsOneWidget);
    expect(find.text('Später'), findsOneWidget);
    // Kein Gate: die Folge gilt schon als gelesen, egal was jetzt kommt.
    expect(await store.isCompleted('ep_end'), isTrue);
    await tester.tap(find.byKey(const ValueKey('story-end-cafe')));
    await tester.pump();
    expect(entered, isTrue);
  });

  testWidgets('ohne onEnterCafe bleibt „Zurück zum Lesen"', (tester) async {
    await tester.pumpWidget(reader());
    await readToEnd(tester);
    expect(find.byKey(const ValueKey('story-end-cafe')), findsNothing);
    expect(find.text('Zurück zum Lesen'), findsOneWidget);
  });
}
```

`test/features/story/story_route_cafe_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('„Ins Café" von der Endkarte landet in der Nachbesprechung, '
      'und jedes Budget-Wort liegt vorher im Karteikasten', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    await seedJaPack(learning);
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StoryRoute(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();

    // Folge 01 V3: 10 Panels → 9 Taps bis zum letzten, ein 10. auf die
    // Endkarte. Die Route hängt immer Speak-/Trace-Evaluatoren ein; jedes
    // Sheet wird per Tap oberhalb geschlossen (Muster story_route_test).
    const sheetKeys = [
      ValueKey('dictionary-sheet'),
      ValueKey('diegetic-speak-sheet'),
      ValueKey('diegetic-trace-sheet'),
    ];
    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      for (final key in sheetKeys) {
        if (find.byKey(key).evaluate().isNotEmpty) {
          await tester.tapAt(const Offset(400, 50));
          await tester.pumpAndSettle();
        }
      }
    }
    expect(find.byKey(const ValueKey('story-end-cafe')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-end-cafe')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-card')), findsOneWidget);
    final episode = loadFolge01();
    for (final ref in episode.budget.items) {
      final item = await learning
          .getLearnItem('lang_ja:${ref.refType.name}:${ref.id}');
      expect(item, isNotNull, reason: '${ref.id} lag nicht im Karteikasten');
    }
  });
}
```

- [ ] **Step 2: Tests laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/story/story_reader_end_card_test.dart test/features/story/story_route_cafe_test.dart`
Expected: FAIL — `onEnterCafe` unbekannt; `story-end-cafe` fehlt.

- [ ] **Step 3: Reader** — in `lib/features/story/story_reader_screen.dart`:

Feld nach `onDiegeticTraceSuccess`:

```dart
  /// Weg von der Endkarte ins Café (Spec Café-Nachbesprechung §3.2). Gesetzt
  /// → die Endkarte zeigt „Ins Café" (primär) und „Später" (zurück); null →
  /// „Zurück zum Lesen" wie bisher. Kein Gate: die Folge gilt in jedem Fall
  /// als gelesen (INV-1).
  final Future<void> Function()? onEnterCafe;
```

Konstruktor: `this.onEnterCafe,` ergänzen. In der Endkarte den `FilledButton(key: 'story-end-done', …)` ersetzen durch:

```dart
                if (widget.onEnterCafe != null) ...[
                  FilledButton(
                    key: const ValueKey('story-end-cafe'),
                    onPressed: () => widget.onEnterCafe!(),
                    child: const Text('Ins Café'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('story-end-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Später'),
                  ),
                ] else
                  FilledButton(
                    key: const ValueKey('story-end-done'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zurück zum Lesen'),
                  ),
```

- [ ] **Step 4: Route** — in `lib/features/story/story_route.dart` Import `../cafe/cafe_route.dart` ergänzen; im `StoryReaderScreen(...)`-Aufruf nach `onEpisodeComplete: …,`:

```dart
          onEnterCafe: () async {
            // Die Übergabe am Folgen-Ende läuft fire-and-forget; bevor die
            // Wirtin den Tisch deckt, muss jedes Budget-Item im Karteikasten
            // liegen. introduce() ist idempotent — ein zweiter Lauf kostet nur
            // Lookups und führt nichts Neues ein (INV-8: nur Manifest-Items).
            await handoff.introduceEpisode(episode);
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
              builder: (_) => CafeRoute(debriefEpisodeId: episode.id),
            ));
          },
```

- [ ] **Step 5: Tests laufen lassen**

Run: `flutter test test/features/story/`
Expected: PASS (bestehende Reader-Tests ohne `onEnterCafe` unverändert; `story-end-done` bleibt).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_reader_screen.dart lib/features/story/story_route.dart test/features/story/story_reader_end_card_test.dart test/features/story/story_route_cafe_test.dart
git commit -m "feat(story): Endkarte „Ins Café"/„Später" — nach der Folge geht es ins Café (Nachbesprechung)"
```

---

### Task 12: Content — Erklärungsblock der 18 Wörter von Folge 01

**Files:**
- Modify: `lib/features/story/episodes/folge_01_regen.dart` (`pilot01RegenJson`: Schlüssel `'debrief'` nach `'budget'`)
- Test: `test/features/story/folge_01_regen_test.dart` (ein Test anhängen)

**Interfaces:**
- Consumes: Schema (Task 1), Validator (Task 2) — `loadFolge01()` validiert beim Laden, die vier Regeln gelten also für diesen Content.
- Produces: `episode.debrief` mit genau den 18 Budget-Ids, Texte aus Spec §6 (Wirtin, warm, kurz; höchstens zwei Varianten; keine Variante ist ein Budget-Wort).

- [ ] **Step 1: Failing Test anhängen** — an `test/features/story/folge_01_regen_test.dart`:

```dart
  test('jedes Budget-Wort hat einen Erklärungsblock der Wirtin (Gebrauch, '
      '≤2 Varianten) — und nur Budget-Wörter haben einen', () {
    final episode = loadFolge01();
    for (final item in episode.budget.items) {
      final note = episode.debrief[item.id];
      expect(note, isNotNull, reason: '${item.id} ohne Erklärungsblock');
      expect(note!.usage.trim(), isNotEmpty);
      expect(note.variants.length, lessThanOrEqualTo(2));
    }
    expect(episode.debrief.keys.toSet(),
        {for (final i in episode.budget.items) i.id});
  });
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag prüfen**

Run: `flutter test test/features/story/folge_01_regen_test.dart`
Expected: FAIL — `debrief` ist leer.

- [ ] **Step 3: Content einfügen** — in `pilot01RegenJson` direkt nach dem `'budget': {...},`-Block:

```dart
  // Erklärungsblock der Wirtin (Spec Café-Nachbesprechung §6): Gebrauch in
  // ein bis zwei Sätzen, höchstens zwei Varianten. Varianten sind Wissen am
  // Wort, keine Items — der Validator hält sie vom Budget fern.
  'debrief': {
    'lex_ja_eki': {
      'usage': '„Bahnhof". Auf dem Schild steht es als Kanji 駅, gesprochen '
          'えき — Miras erstes Schild in dieser Stadt.',
      'variants': [],
    },
    'lex_ja_samui': {
      'usage': '„kalt" — fürs Wetter und fürs Frösteln, nicht für kaltes '
          'Wasser.',
      'variants': [
        {
          'form': 'つめたい',
          'reading': 'つめたい',
          'meaning': 'kalt zum Anfassen',
          'note': 'Wasser, Hände, ein Getränk',
        },
        {
          'form': 'さむいですね',
          'reading': 'さむいですね',
          'meaning': 'kalt, nicht wahr?',
          'note': 'der Smalltalk-Satz',
        },
      ],
    },
    'lex_ja_ame': {
      'usage': '„Regen". Das Wort vom Zettel, das erste, das Mira selbst '
          'gelesen hat. Vorsicht: mit anderer Betonung heißt あめ auch '
          '„Bonbon" — man hört den Unterschied.',
      'variants': [],
    },
    'lex_ja_sumimasen': {
      'usage': '„Entschuldigung" — aber genauso „Hallo, darf ich mal?". Mira '
          'benutzt es, um jemanden anzusprechen, nicht nur zum Entschuldigen.',
      'variants': [
        {
          'form': 'ごめんなさい',
          'reading': 'ごめんなさい',
          'meaning': 'tut mir leid',
          'note': 'persönlicher, für eigene Fehler',
        },
        {
          'form': 'すみませんでした',
          'reading': 'すみませんでした',
          'meaning': 'Entschuldigung',
          'note': 'für etwas, das schon passiert ist',
        },
      ],
    },
    'lex_ja_koko': {
      'usage': '„hier" — der Ort bei mir.',
      'variants': [
        {'form': 'そこ', 'reading': 'そこ', 'meaning': 'da', 'note': 'bei dir'},
        {
          'form': 'あそこ',
          'reading': 'あそこ',
          'meaning': 'dort',
          'note': 'weit weg von uns beiden',
        },
      ],
    },
    'lex_ja_mise': {
      'usage': '„Laden, Geschäft" — jeder Laden in der Shotengai ist ein みせ.',
      'variants': [
        {
          'form': 'おみせ',
          'reading': 'おみせ',
          'meaning': 'Laden',
          'note': 'höflicher, mit お davor',
        },
      ],
    },
    'lex_ja_hitori': {
      'usage': '„allein" oder „eine Person". Mira ist ひとり in dieser Stadt.',
      'variants': [
        {
          'form': 'ひとりで',
          'reading': 'ひとりで',
          'meaning': 'allein (als Art und Weise)',
          'note': 'allein reisen, allein essen',
        },
      ],
    },
    'lex_ja_kasa': {
      'usage': '„Schirm". Erst ein Ding in Miras Hand, dann ein Wort. Als '
          'Kanji: 傘.',
      'variants': [
        {
          'form': 'あまがさ',
          'reading': 'あまがさ',
          'meaning': 'Regenschirm',
          'note': 'wörtlich あめ + かさ',
        },
      ],
    },
    'lex_ja_kore': {
      'usage': '„das hier" — das Ding bei mir, in meiner Hand.',
      'variants': [
        {'form': 'それ', 'reading': 'それ', 'meaning': 'das da', 'note': 'bei dir'},
        {
          'form': 'あれ',
          'reading': 'あれ',
          'meaning': 'das dort',
          'note': 'weit weg',
        },
      ],
    },
    'lex_ja_kowareta': {
      'usage': '„kaputt" — genauer: „ist kaputtgegangen". Die Form sagt: Es '
          'ist schon passiert.',
      'variants': [
        {
          'form': 'こわれている',
          'reading': 'こわれている',
          'meaning': 'ist kaputt',
          'note': 'als Zustand',
        },
        {
          'form': 'こわれました',
          'reading': 'こわれました',
          'meaning': 'ist kaputtgegangen',
          'note': 'dasselbe, höflicher',
        },
      ],
    },
    'lex_ja_dame': {
      'usage': '„geht nicht / kaputt / nein" — das Alltagswort, wenn etwas '
          'nicht geht.',
      'variants': [
        {
          'form': 'だめです',
          'reading': 'だめです',
          'meaning': 'geht nicht',
          'note': 'höflicher',
        },
        {
          'form': 'むり',
          'reading': 'むり',
          'meaning': 'unmöglich',
          'note': 'noch deutlicher',
        },
      ],
    },
    'lex_ja_ikura': {
      'usage': '„wie viel (kostet das)?" — die Frage im Laden.',
      'variants': [
        {
          'form': 'いくらですか',
          'reading': 'いくらですか',
          'meaning': 'wie viel kostet das?',
          'note': 'höflich, der ganze Satz',
        },
      ],
    },
    'lex_ja_iie': {
      'usage': '„nein" — höflich, im Gespräch mit Fremden.',
      'variants': [
        {'form': 'いや', 'reading': 'いや', 'meaning': 'nein', 'note': 'locker'},
        {
          'form': 'ううん',
          'reading': 'ううん',
          'meaning': 'nein',
          'note': 'unter Freunden, oft nur ein Laut',
        },
      ],
    },
    'lex_ja_hontou': {
      'usage': '„wirklich?" — als Frage, wenn man etwas kaum glauben kann.',
      'variants': [
        {
          'form': 'ほんとうに',
          'reading': 'ほんとうに',
          'meaning': 'wirklich (als Verstärkung)',
          'note': 'wirklich kalt, wirklich allein',
        },
        {
          'form': 'ほんと',
          'reading': 'ほんと',
          'meaning': 'wirklich?',
          'note': 'kurz, gesprochen',
        },
      ],
    },
    'lex_ja_daijoubu': {
      'usage': '„alles gut / in Ordnung" — als Frage und als Antwort.',
      'variants': [
        {
          'form': 'だいじょうぶです',
          'reading': 'だいじょうぶです',
          'meaning': 'alles in Ordnung',
          'note': 'höflicher',
        },
        {
          'form': 'へいき',
          'reading': 'へいき',
          'meaning': 'macht nichts',
          'note': 'lockerer',
        },
      ],
    },
    'lex_ja_hai': {
      'usage': '„ja". Und beim Überreichen: „hier, bitte" (はい、どうぞ).',
      'variants': [
        {'form': 'ええ', 'reading': 'ええ', 'meaning': 'ja', 'note': 'weicher'},
        {
          'form': 'うん',
          'reading': 'うん',
          'meaning': 'ja',
          'note': 'locker, unter Freunden',
        },
      ],
    },
    'lex_ja_douzo': {
      'usage': '„bitte, hier" — wenn man etwas gibt oder anbietet. Nicht das '
          '„bitte" einer Bitte. Das Gegenstück ist ありがとう.',
      'variants': [],
    },
    'lex_ja_arigatou': {
      'usage': '„danke".',
      'variants': [
        {
          'form': 'ありがとうございます',
          'reading': 'ありがとうございます',
          'meaning': 'vielen Dank',
          'note': 'höflicher — zu Fremden und Älteren',
        },
        {
          'form': 'どうも',
          'reading': 'どうも',
          'meaning': 'danke',
          'note': 'kurz und beiläufig',
        },
      ],
    },
  },
```

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/folge_01_regen_test.dart test/features/story/folge_01_dichte_test.dart test/features/story/story_route_cafe_test.dart`
Expected: PASS (der Validator akzeptiert den Block: alle Schlüssel im Budget, ≤ 2 Varianten, keine Variante gleicht einer Budget-Oberfläche).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episodes/folge_01_regen.dart test/features/story/folge_01_regen_test.dart
git commit -m "feat(story): Folge 01 — Erklärungsblock der Wirtin für alle 18 Wörter (Nachbesprechung)"
```

---

### Task 13: Abschluss — Analyzer, Full-Suite, Beweis, PR

**Files:**
- Modify: keine Code-Dateien (nur Fixes, falls Analyzer/Suite etwas finden)

- [ ] **Step 1: Analyzer**

Run: `flutter analyze`
Expected: `No issues found!` — sonst die gemeldeten Stellen beheben (typisch: ungenutzte Imports), erneut laufen lassen.

- [ ] **Step 2: Full-Suite**

Run: `flutter test 2>&1 | tail -30`
Expected: Alle Fehler ausschließlich in `test/mining_packs/ja/` (8 vorbestehende native-Tokenizer-Fehler). Jeder andere Fehler wird isoliert verifiziert und behoben — keine „Flakiness". Bricht der NUC mit OOM ab: Suite auf `pc` laufen lassen (Skill `cross-machine-test-deploy`) und das Ergebnis dort festhalten.

- [ ] **Step 3: Beweis-Durchlauf der Nutzerreise (Kurzfassung)**

Run: `flutter test test/features/story/story_route_cafe_test.dart test/features/cafe/cafe_debrief_screen_test.dart test/features/cafe/cafe_route_debrief_test.dart test/features/cafe/cafe_inv9_test.dart`
Expected: PASS — das ist die Kette Endkarte → Nachbesprechung → Akt 1 → Akt 2 → Café, plus INV-9/INV-11.

- [ ] **Step 4: Commit etwaiger Fixes + Push + Draft-PR**

```bash
git push -u origin impl/cafe-nachbesprechung
gh pr create --draft --base feat/reader-erleben --head impl/cafe-nachbesprechung \
  --title "feat(cafe): Nachbesprechung — nach der Folge geht es ins Café (Wörter)" \
  --body-file <PR-Text: Spec-Link, Plan-Link, Nutzerreise in 5 Zeilen, Test-Stand, offen: Gerätetest S23 + Schritte 3/4/5 der Spec>
```

Expected: Draft-PR gestapelt auf #45. Abnahme laut Spec §10: Ulis Gerätetest auf dem S23.

---

## Spec-Abdeckung (Selbstprüfung)

| Spec | Task |
|---|---|
| §3.1 Café-Einführung (V3: schon in P9/P10; Eintritt = Endkarte) | 11 |
| §3.2 Endkarte „Ins Café"/„Später", kein Gate | 11 |
| §3.3 Akt 1 Erklärungskarte (Wort: Form, Lesung, Bedeutung, Stelle, Gebrauch, Varianten; Sprosse 0→1) | 4, 5, 7 |
| §3.4 Akt 2 Turns, Schlusszeile rotierend | 6, 7 |
| §3.5 „Erklär's mir nochmal" = Hinweis; Sprosse-0-Karte im normalen Turn | 8 |
| §3.6 Später/Abbruch/Wiederkommen, Wirtin anwesend bei offener Nachbesprechung | 3, 9, 10 |
| §4 INV-8/9/11 Quelle = Manifest ∩ learn_items; Variante ≠ Item | 4 (+INV-9-Test), 7 (Test „Varianten wurden nie zu Items") |
| §5.1 `Episode.debrief`, abgeleitete Stelle-in-der-Folge | 1, 4 |
| §5.3 Route-Parameter, Belegung, Debrief-Screen, Turn-Erweiterungen | 6–10 |
| §5.4 Karte = `EncounterView` + Zusatz | 5 |
| §5.6 Validator (Budget-Item, Variante ≠ Budget-Oberfläche, ≤ 2) | 2 |
| §5.7 Prefs | 3 |
| §6 Content Folge 01 (18 Wörter) | 12 |
| §10 Tests | je Task; Kette in 13 |
| Nicht in diesem Plan (Spec §11, 3–5): Zeichen, Grammatik, P11 | Folgepläne |
