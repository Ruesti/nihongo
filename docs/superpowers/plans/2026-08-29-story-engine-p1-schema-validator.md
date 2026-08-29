# Story-Engine P1 — Content-Schema + Validator Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Episode/Page/Panel/Bubble/Token content schema from `docs/story/BRIEF_STORY_ENGINE.md` §2, author Folge 01 ("Regen") as a fixture, and build a validator that enforces INV-3 (no panel exceeds the episode's budget) and INV-4 (every non-singleton item appears in ≥2 distinct panels).

**Architecture:** Three self-contained, additive Dart files under a new `lib/features/story/` directory, following the hand-written-`fromJson` pattern already used by `lib/features/comic/comic_pack.dart` (no JSON codegen). The schema reuses the existing `RefType` enum from `lib/core/ladder/rung_defs.dart` rather than redefining it. The fixture is a plain Dart `const` map (not yet a bundled asset — that's a P2 reader concern) consumed by both a parse smoke test and the validator's tests. Nothing in this phase touches the reader, the review screen, or any UI.

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`, no new dependencies.

## Global Constraints

- Base branch: `origin/main` — it already contains the Five-Rung Retrieval Ladder, SM-2 SRS, and `ScriptProfile` abstraction the brief assumes. Do **not** base this work on `spec/gefuehrter-weg`; that branch carries the now-superseded Journey/Lektions-Step layer.
- No JSON codegen (no `freezed`, no `json_serializable`). Hand-written `fromJson` factory constructors on plain immutable classes, matching `lib/features/comic/comic_pack.dart`.
- Reuse `enum RefType { lexeme, character, grammar }` from `lib/core/ladder/rung_defs.dart` — import it, do not redefine it.
- Every `Panel.asset` value in the P1 fixture is `assets/comic/placeholder_page.png` (already bundled — see `pubspec.yaml`'s `assets/comic/` entry). No new binary assets in this phase.
- Café/`CafeTurn` schema (brief §4) is explicitly **out of scope** — that is phase P7. Do not scaffold it here.
- Run tests with `flutter test <path>` from the repo root.

---

### Task 1: Episode content schema

**Files:**
- Create: `lib/features/story/episode.dart`
- Test: `test/features/story/episode_test.dart`

**Interfaces:**
- Consumes: `RefType` from `lib/core/ladder/rung_defs.dart` (already exists: `enum RefType { lexeme, character, grammar }`).
- Produces (used by Task 2 and Task 3): `Episode.fromJson(Map<String, dynamic>)`, `Episode.allPanels` (`Iterable<StoryPanel>`), `Episode.budget` (`EpisodeBudget`), `EpisodeBudget.items` (`List<ItemRef>`), `EpisodeBudget.glyphs` (`List<GlyphRef>`), `ItemRef{id: String, refType: RefType, singleton: bool}`, `GlyphRef{glyph: String}`, `StoryPanel{index: int, asset: String, bubbles: List<StoryBubble>, thoughts: List<StoryThought>, interactions: List<StoryInteraction>, anchorShot: String?, notes: String}`, `StoryBubble{speakerId: String, text: String, audioRef: String?, hitArea: StoryPolygon, tokens: List<StoryToken>}`, `StoryToken{surface: String, reading: String?, itemId: String?, lookupable: bool}`, `StoryThought{text: String}`, `StoryInteraction{type: InteractionType, diegetic: bool, optional: bool}`, `InteractionType` enum (`reveal, listen, speak, trace, dictionary`), `StoryPage{index: int, panels: List<StoryPanel>}`, `StoryPolygon{points: List<StoryPoint>}`, `StoryPoint{x: double, y: double}`.

- [ ] **Step 1: Write the failing test**

Create `test/features/story/episode_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart' show RefType;
import 'package:nihongo_app/features/story/episode.dart';

const _json = {
  'id': 'ep_test_01',
  'seasonId': 'season_test',
  'orderIndex': 1,
  'title': 'Test',
  'locale': 'ja',
  'era': '1996',
  'budget': {
    'items': [
      {'id': 'lex_test_hai', 'refType': 'lexeme'},
      {'id': 'lex_test_douzo', 'refType': 'lexeme', 'singleton': true},
    ],
    'glyphs': [
      {'glyph': 'あ'},
    ],
  },
  'pages': [
    {
      'index': 1,
      'panels': [
        {
          'index': 1,
          'asset': 'assets/comic/placeholder_page.png',
          'anchorShot': 'A1',
          'notes': 'author-only commentary',
          'thoughts': [
            {'text': 'Ich hätte anrufen sollen.'},
          ],
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい',
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_test_hai'},
              ],
            },
          ],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
        },
      ],
    },
  ],
};

void main() {
  test('parses a full episode with budget, thoughts, bubbles, and interactions', () {
    final episode = Episode.fromJson(_json);

    expect(episode.id, 'ep_test_01');
    expect(episode.seasonId, 'season_test');
    expect(episode.orderIndex, 1);
    expect(episode.era, '1996');

    expect(episode.budget.items, hasLength(2));
    expect(episode.budget.items[0].id, 'lex_test_hai');
    expect(episode.budget.items[0].refType, RefType.lexeme);
    expect(episode.budget.items[0].singleton, isFalse);
    expect(episode.budget.items[1].singleton, isTrue);
    expect(episode.budget.glyphs.single.glyph, 'あ');

    expect(episode.pages, hasLength(1));
    final panel = episode.pages.single.panels.single;
    expect(panel.index, 1);
    expect(panel.anchorShot, 'A1');
    expect(panel.notes, 'author-only commentary');
    expect(panel.thoughts.single.text, 'Ich hätte anrufen sollen.');

    final bubble = panel.bubbles.single;
    expect(bubble.speakerId, 'ladenbesitzer');
    expect(bubble.tokens.single.itemId, 'lex_test_hai');
    expect(bubble.tokens.single.lookupable, isTrue);
    expect(bubble.hitArea.points, isEmpty);

    expect(panel.interactions.single.type, InteractionType.speak);
    expect(panel.interactions.single.diegetic, isTrue);
    expect(panel.interactions.single.optional, isTrue);

    expect(episode.allPanels, hasLength(1));
  });

  test('defaults anchorShot to null, notes to empty, and itemId to null when absent', () {
    final episode = Episode.fromJson({
      ..._json,
      'pages': [
        {
          'index': 1,
          'panels': [
            {
              'index': 1,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'passantin',
                  'text': 'はい？',
                  'tokens': [
                    {'surface': 'はい'},
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

    final panel = episode.pages.single.panels.single;
    expect(panel.anchorShot, isNull);
    expect(panel.notes, '');
    expect(panel.bubbles.single.tokens.single.itemId, isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/story/episode_test.dart`
Expected: FAIL — `lib/features/story/episode.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/episode.dart`:

```dart
import '../../core/ladder/rung_defs.dart' show RefType;

/// A reference to a budgeted vocabulary/grammar item within an episode.
/// Within P1 this is a free-standing content slug; binding it to a real
/// LearnItem row is a later (P5) concern.
class ItemRef {
  final String id;
  final RefType refType;

  /// True only for items the brief explicitly exempts from the ≥2-panel
  /// repetition rule (INV-4).
  final bool singleton;

  const ItemRef({
    required this.id,
    required this.refType,
    this.singleton = false,
  });

  factory ItemRef.fromJson(Map<String, dynamic> j) => ItemRef(
        id: j['id'] as String,
        refType: RefType.values.byName(j['refType'] as String),
        singleton: j['singleton'] as bool? ?? false,
      );
}

/// A kana/kanji glyph budgeted for an episode (distinct from vocabulary
/// items — see docs/story/BRIEF_STORY_ENGINE.md §2).
class GlyphRef {
  final String glyph;
  const GlyphRef(this.glyph);
  factory GlyphRef.fromJson(Map<String, dynamic> j) =>
      GlyphRef(j['glyph'] as String);
}

class EpisodeBudget {
  final List<ItemRef> items;
  final List<GlyphRef> glyphs;

  const EpisodeBudget({required this.items, required this.glyphs});

  factory EpisodeBudget.fromJson(Map<String, dynamic> j) => EpisodeBudget(
        items: [
          for (final i in (j['items'] as List? ?? const []))
            ItemRef.fromJson(i as Map<String, dynamic>),
        ],
        glyphs: [
          for (final g in (j['glyphs'] as List? ?? const []))
            GlyphRef.fromJson(g as Map<String, dynamic>),
        ],
      );
}

/// A point in normalized (0..1) panel space.
class StoryPoint {
  final double x, y;
  const StoryPoint(this.x, this.y);

  factory StoryPoint.fromJson(Map<String, dynamic> j) => StoryPoint(
        (j['x'] as num).toDouble(),
        (j['y'] as num).toDouble(),
      );
}

/// A bubble hit-area. Empty until real panel artwork exists to trace it
/// against (deferred to the panel-reader phase, P2/P3).
class StoryPolygon {
  final List<StoryPoint> points;
  const StoryPolygon(this.points);

  factory StoryPolygon.fromJson(List<dynamic>? j) => StoryPolygon([
        for (final p in (j ?? const []))
          StoryPoint.fromJson(p as Map<String, dynamic>),
      ]);
}

class StoryToken {
  final String surface;
  final String? reading;
  final String? itemId;

  /// False only for locked kanji (INV-7) — tapping does nothing, no hint,
  /// no lock message. True for every kana token.
  final bool lookupable;

  const StoryToken({
    required this.surface,
    this.reading,
    this.itemId,
    required this.lookupable,
  });

  factory StoryToken.fromJson(Map<String, dynamic> j) => StoryToken(
        surface: j['surface'] as String,
        reading: j['reading'] as String?,
        itemId: j['itemId'] as String?,
        lookupable: j['lookupable'] as bool? ?? true,
      );
}

class StoryBubble {
  final String speakerId;
  final String text;
  final String? audioRef;
  final StoryPolygon hitArea;
  final List<StoryToken> tokens;

  const StoryBubble({
    required this.speakerId,
    required this.text,
    this.audioRef,
    required this.hitArea,
    required this.tokens,
  });

  factory StoryBubble.fromJson(Map<String, dynamic> j) => StoryBubble(
        speakerId: j['speakerId'] as String,
        text: j['text'] as String,
        audioRef: j['audioRef'] as String?,
        hitArea: StoryPolygon.fromJson(j['hitArea'] as List?),
        tokens: [
          for (final t in (j['tokens'] as List? ?? const []))
            StoryToken.fromJson(t as Map<String, dynamic>),
        ],
      );
}

/// A learner's-native-language thought bubble (never target-language).
class StoryThought {
  final String text;
  const StoryThought(this.text);
  factory StoryThought.fromJson(Map<String, dynamic> j) =>
      StoryThought(j['text'] as String);
}

enum InteractionType { reveal, listen, speak, trace, dictionary }

class StoryInteraction {
  final InteractionType type;

  /// True if this interaction is part of the fiction (e.g. a phone call
  /// scene inviting speech) rather than a bolt-on practice prompt.
  final bool diegetic;

  /// Always true in story mode (INV-1) — no interaction may gate reading.
  final bool optional;

  const StoryInteraction({
    required this.type,
    required this.diegetic,
    this.optional = true,
  });

  factory StoryInteraction.fromJson(Map<String, dynamic> j) => StoryInteraction(
        type: InteractionType.values.byName(j['type'] as String),
        diegetic: j['diegetic'] as bool? ?? false,
        optional: j['optional'] as bool? ?? true,
      );
}

class StoryPanel {
  final int index;
  final String asset;
  final List<StoryBubble> bubbles;
  final List<StoryThought> thoughts;
  final List<StoryInteraction> interactions;

  /// Recurring camera axis id (e.g. "A1") — see docs/story/VISUAL_STYLE.md.
  /// Null when the panel does not reuse one of the series' fixed anchors.
  final String? anchorShot;

  /// Author commentary. Never rendered to the reader.
  final String notes;

  const StoryPanel({
    required this.index,
    required this.asset,
    required this.bubbles,
    required this.thoughts,
    required this.interactions,
    this.anchorShot,
    this.notes = '',
  });

  factory StoryPanel.fromJson(Map<String, dynamic> j) => StoryPanel(
        index: j['index'] as int,
        asset: j['asset'] as String,
        bubbles: [
          for (final b in (j['bubbles'] as List? ?? const []))
            StoryBubble.fromJson(b as Map<String, dynamic>),
        ],
        thoughts: [
          for (final t in (j['thoughts'] as List? ?? const []))
            StoryThought.fromJson(t as Map<String, dynamic>),
        ],
        interactions: [
          for (final i in (j['interactions'] as List? ?? const []))
            StoryInteraction.fromJson(i as Map<String, dynamic>),
        ],
        anchorShot: j['anchorShot'] as String?,
        notes: j['notes'] as String? ?? '',
      );
}

class StoryPage {
  final int index;
  final List<StoryPanel> panels;

  const StoryPage({required this.index, required this.panels});

  factory StoryPage.fromJson(Map<String, dynamic> j) => StoryPage(
        index: j['index'] as int,
        panels: [
          for (final p in (j['panels'] as List? ?? const []))
            StoryPanel.fromJson(p as Map<String, dynamic>),
        ],
      );
}

class Episode {
  final String id;
  final String seasonId;
  final int orderIndex;
  final String title;
  final String locale;
  final String era;
  final EpisodeBudget budget;
  final List<StoryPage> pages;

  const Episode({
    required this.id,
    required this.seasonId,
    required this.orderIndex,
    required this.title,
    required this.locale,
    required this.era,
    required this.budget,
    required this.pages,
  });

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        id: j['id'] as String,
        seasonId: j['seasonId'] as String,
        orderIndex: j['orderIndex'] as int,
        title: j['title'] as String,
        locale: j['locale'] as String,
        era: j['era'] as String,
        budget: EpisodeBudget.fromJson(j['budget'] as Map<String, dynamic>),
        pages: [
          for (final p in (j['pages'] as List? ?? const []))
            StoryPage.fromJson(p as Map<String, dynamic>),
        ],
      );

  /// All panels across all pages, in reading order.
  Iterable<StoryPanel> get allPanels => pages.expand((p) => p.panels);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/story/episode_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episode.dart test/features/story/episode_test.dart
git commit -m "feat(story): add Episode/Page/Panel/Bubble/Token content schema"
```

---

### Task 2: Folge 01 ("Regen") fixture

**Files:**
- Create: `test/fixtures/story/pilot_01_regen_fixture.dart`
- Test: `test/fixtures/story/pilot_01_regen_fixture_test.dart`

**Interfaces:**
- Consumes: `Episode.fromJson` from Task 1.
- Produces (used by Task 3): `const Map<String, dynamic> pilot01RegenJson` — a complete, schema-shaped encoding of `docs/story/PILOT_01_REGEN.md` (as corrected: every non-singleton item tagged in exactly 2 panels; `lex_ja_douzo` is the sole `singleton: true` item).

- [ ] **Step 1: Write the failing test**

Create `test/fixtures/story/pilot_01_regen_fixture_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';

import 'pilot_01_regen_fixture.dart';

void main() {
  test('the pilot episode fixture parses into 6 pages and 24 panels', () {
    final episode = Episode.fromJson(pilot01RegenJson);

    expect(episode.id, 'ep_ja_shotengai_01');
    expect(episode.pages, hasLength(6));
    expect(episode.allPanels, hasLength(24));
    expect(episode.budget.items, hasLength(8));
    expect(episode.budget.glyphs, hasLength(3));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/fixtures/story/pilot_01_regen_fixture_test.dart`
Expected: FAIL — `pilot_01_regen_fixture.dart` does not exist yet (import error).

- [ ] **Step 3: Write the fixture**

Create `test/fixtures/story/pilot_01_regen_fixture.dart`, encoding `docs/story/PILOT_01_REGEN.md` (corrected version) in full:

```dart
/// Folge 01 — "Regen", encoded per docs/story/PILOT_01_REGEN.md.
const Map<String, dynamic> pilot01RegenJson = {
  'id': 'ep_ja_shotengai_01',
  'seasonId': 'season_ja_shotengai',
  'orderIndex': 1,
  'title': 'Regen',
  'locale': 'ja',
  'era': '1996',
  'budget': {
    'items': [
      {'id': 'lex_ja_sumimasen', 'refType': 'lexeme'},
      {'id': 'lex_ja_ame', 'refType': 'lexeme'},
      {'id': 'lex_ja_kasa', 'refType': 'lexeme'},
      {'id': 'lex_ja_kore', 'refType': 'lexeme'},
      {'id': 'lex_ja_kowareta', 'refType': 'lexeme'},
      {'id': 'lex_ja_hai', 'refType': 'lexeme'},
      {'id': 'lex_ja_douzo', 'refType': 'lexeme', 'singleton': true},
      {'id': 'lex_ja_arigatou', 'refType': 'lexeme'},
    ],
    'glyphs': [
      {'glyph': 'あ'},
      {'glyph': 'め'},
      {'glyph': 'か'},
    ],
  },
  'pages': [
    // Seite 1 — Ankunft
    {
      'index': 1,
      'panels': [
        {
          'index': 1,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Weitwinkel. Kleiner Bahnsteig, keine Menschen. Regen fällt '
              'schräg durch Neonlicht. Sie steht mit Tasche, Kopf noch '
              'nicht gehoben. Kein Wort in den ersten sechs Panels.',
        },
        {
          'index': 2,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Detail: ihre Hand hält einen handgeschriebenen Zettel, '
              'Tinte läuft im Regen. Zettel zeigt verlaufene, unleserliche '
              'Kanji — kein Antippen, keine Übersetzung.',
        },
        {
          'index': 3,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [
            {'text': 'Ich hätte anrufen sollen.'},
          ],
          'interactions': [],
          'notes':
              'Gedankenpanel, enger Ausschnitt, ihr Gesicht, Regen im Haar. '
              'Einziger Hinweis auf ein Davor. Nicht ausbauen.',
        },
        {
          'index': 4,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie geht los. Rücken zur Kamera, leere Straße, Wasser auf '
              'Asphalt, Kabelmasten gegen grauen Himmel.',
        },
      ],
    },
    // Seite 2 — Die Straße
    {
      'index': 2,
      'panels': [
        {
          'index': 5,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'anchorShot': 'A1',
          'notes':
              'Eingang der Shotengai. Überdachtes Dach, Regen prasselt '
              'darauf. Innen trocken, warmes Licht, halb tot: drei von '
              'sieben Rollläden geschlossen. Etablierungs-Panel.',
        },
        {
          'index': 6,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie tritt ein, schüttelt sich. Erleichterung. Erstes '
              'trockenes Bild der Folge.',
        },
      ],
    },
    // Seite 3 — Das Wörterbuch versagt
    {
      'index': 3,
      'panels': [
        {
          'index': 7,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'すみません',
              'tokens': [
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
          'notes':
              'Eine ältere Frau kommt ihr entgegen, Einkaufstüte, zügig. '
              'Die Figur hebt die Hand. Ihr erstes Wort der Serie, im Zug '
              'auswendig gelernt. Sprechmoment 1.',
        },
        {
          'index': 8,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'passantin',
              'text': 'はい？',
              'tokens': [
                {'surface': 'はい', 'itemId': null},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Die Frau bleibt stehen, freundlich, wartend. はい ist hier '
              'noch nicht im Bestand — wird erst P19 als Item eingeführt, '
              'hier ist es Klang.',
        },
        {
          'index': 9,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [
            {'type': 'dictionary', 'diegetic': true},
          ],
          'notes':
              'Die Figur blättert hektisch im Wörterbuch. Nasse Finger, '
              'Seiten kleben. Es gibt nichts zu finden, weil sie nicht '
              'weiß, wonach sie sucht. Kernszene: das Werkzeug wird zuerst '
              'als nutzlos vorgeführt.',
        },
        {
          'index': 10,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Aufblick. Die Frau ist weg, nur noch ihr Rücken am Ende der '
              'Straße. Wörterbuch schließt automatisch. Erste Demütigung, '
              'nicht kommentiert.',
        },
      ],
    },
    // Seite 4 — Der Laden
    {
      'index': 4,
      'panels': [
        {
          'index': 11,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'あめ',
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
          ],
          'thoughts': [
            {'text': 'Regen.'},
          ],
          'interactions': [],
          'notes':
              'Sie steht allein, Blick nach oben aufs Dach, Regen trommelt. '
              'Ein Wetterbericht-Aushang an einer Litfaßsäule zeigt あめ — '
              'geschrieben, nicht gesprochen. Sie kann es hier noch nicht '
              'lesen, der Leser auch nicht. Erste Verknüpfung Klang↔Zeichen.',
        },
        {
          'index': 12,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Ein einzelnes warmes Licht weiter hinten. Offene Schiebetür. '
              'Ladenschild: Kanji, reine Bildtextur.',
        },
        {
          'index': 13,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie tritt unter das Vordach. Nicht hinein — sie will sich '
              'nur unterstellen.',
        },
        {
          'index': 14,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Innen, aus ihrer Perspektive: Werkbank, Werkzeug an der '
              'Wand, CRT-Fernseher läuft ohne Ton, ein alter Mann sitzt mit '
              'dem Rücken zu ihr und arbeitet. Er dreht sich nicht um — er '
              'registriert sie, sagt aber nichts. Das ist die Figur.',
        },
      ],
    },
    // Seite 5 — Der Moment
    {
      'index': 5,
      'panels': [
        {
          'index': 15,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Detail neben der Tür: ein Schirmständer mit drei Schirmen, '
              'einer mit gebrochener Speiche, halb geöffnet, verkantet. '
              'Erstauftritt kasa als Objekt, nicht als Wort — das Wort '
              'kommt erst P21. Prinzip: Ding vor Wort.',
        },
        {
          'index': 16,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Ihre Hände. Sie hat den Schirm aus dem Ständer genommen, '
              'dreht ihn, findet die Bruchstelle. Reines Handwerks-Panel, '
              'kein Gesicht. Der Kompetenz-Umschlag der Serie: sie tut, '
              'was sie nicht sagen kann.',
        },
        {
          'index': 17,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'これ、こわれた',
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Er hat sich umgedreht, steht jetzt, zeigt auf den Schirm. '
              'Seine ersten Worte: drei Wörter, kein Satzbau, keine '
              'Höflichkeitsform — weil er so redet, nicht weil es '
              'didaktisch bequem ist.',
        },
        {
          'index': 18,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'これ… こわれた…？',
              'tokens': [
                {'surface': 'これ', 'itemId': 'lex_ja_kore'},
                {'surface': 'こわれた', 'itemId': 'lex_ja_kowareta'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie schaut ihn an, hat kein Wort verstanden außer dem '
              'Zeigen, spricht die Wörter probeweise nach — lautes '
              'Einprägen, keine Kommunikation. Die eigentliche Frage '
              'bleibt die Geste: sie nickt Richtung Werkbank.',
        },
        {
          'index': 19,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい',
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Er, minimal — ein Nicken. はい wird hier als Item '
              'aufgenommen. Die erste gelungene Kommunikation der Folge — '
              'und es ist eine gestische, keine sprachliche.',
        },
      ],
    },
    // Seite 6 — Der Schirm
    {
      'index': 6,
      'panels': [
        {
          'index': 20,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう',
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Zeitraffer-Panel, breit. Sie an der Werkbank, er im '
              'Hintergrund am Fernseher, blickt nicht auf. Ein leiser Dank '
              'zwischendurch, ohne Antwort — passt zu seiner '
              'Zurückhaltung. Draußen dunkler geworden, Regen unverändert.',
        },
        {
          'index': 21,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'ladenbesitzer',
              'text': 'はい。かさ。どうぞ',
              'tokens': [
                {'surface': 'はい', 'itemId': 'lex_ja_hai'},
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
                {'surface': 'どうぞ', 'itemId': 'lex_ja_douzo'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Sie hält den reparierten Schirm hoch, geöffnet. Er steht in '
              'der Tür. Emotionaler Höhepunkt: er gibt ihr den Schirm, den '
              'sie selbst repariert hat — die Geste ist größer als das '
              'Objekt. Kein Panel darf das erklären.',
        },
        {
          'index': 22,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'ありがとう… すみません',
              'tokens': [
                {'surface': 'ありがとう', 'itemId': 'lex_ja_arigatou'},
                {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'speak', 'diegetic': true},
          ],
          'notes':
              'Sie, Schirm in beiden Händen, Verbeugung angedeutet. Hängt '
              'sumimasen an, weil es das einzige andere Wort ist, das sie '
              'hat — falsch verwendet, und dadurch richtig. Er zieht eine '
              'Augenbraue hoch statt sie zu korrigieren. Sprechmoment 2.',
        },
        {
          'index': 23,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'protagonist',
              'text': 'かさ…',
              'tokens': [
                {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
              ],
            },
          ],
          'thoughts': [],
          'interactions': [],
          'notes':
              'Draußen, unter dem Schirm. Erste Einstellung mit ihr im '
              'Regen und trocken, Licht des Ladens hinter ihr noch an. Sie '
              'murmelt das neue Wort nach — erste unaufgeforderte '
              'japanische Äußerung der Folge.',
        },
        {
          'index': 24,
          'asset': 'assets/comic/placeholder_page.png',
          'bubbles': [
            {
              'speakerId': 'buch',
              'text': 'あめ',
              'tokens': [
                {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
              ],
            },
            {
              'speakerId': 'vorbesitzer_notiz',
              'text': '(unleserliche Randnotiz, Kanji und Datum)',
              'tokens': [],
            },
          ],
          'thoughts': [],
          'interactions': [
            {'type': 'trace', 'diegetic': true},
          ],
          'notes':
              'Sie hat unter dem Vordach angehalten, das Wörterbuch '
              'aufgeschlagen, sucht あめ. Die Seite ist bereits '
              'angestrichen. Am Rand fremde Handschrift: ein kurzer '
              'Vermerk in Kanji und ein Datum — nicht antippbar, nicht '
              'auflösbar. Schlussbild: sie liest あめ zum ersten Mal '
              'selbst und zeichnet あ め nach — der eine diegetische '
              'Schreibmoment der Folge, Übergang in den Übungsmodus.',
        },
      ],
    },
  ],
};
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/fixtures/story/pilot_01_regen_fixture_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add test/fixtures/story/pilot_01_regen_fixture.dart test/fixtures/story/pilot_01_regen_fixture_test.dart
git commit -m "test(story): add Folge 01 'Regen' fixture from docs/story/PILOT_01_REGEN.md"
```

---

### Task 3: Episode validator enforcing INV-3 and INV-4

**Files:**
- Create: `lib/features/story/episode_validator.dart`
- Test: `test/features/story/episode_validator_test.dart`

**Interfaces:**
- Consumes: `Episode`, `StoryPanel`, `StoryBubble`, `StoryToken`, `ItemRef` from Task 1 (`lib/features/story/episode.dart`); `pilot01RegenJson` from Task 2 (`test/fixtures/story/pilot_01_regen_fixture.dart`).
- Produces: `void validateEpisode(Episode episode)` — throws `StoryValidationException` if any invariant is violated, returns normally otherwise. `class StoryValidationException implements Exception { final List<String> violations; ... }`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/episode_validator_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/episode_validator.dart';

import '../../fixtures/story/pilot_01_regen_fixture.dart';

Map<String, dynamic> _mutableCopy(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  test('the pilot episode fixture is valid as written', () {
    final episode = Episode.fromJson(pilot01RegenJson);
    expect(() => validateEpisode(episode), returnsNormally);
  });

  test('does not flag the singleton item (douzo) despite a single occurrence', () {
    final episode = Episode.fromJson(pilot01RegenJson);
    final douzo =
        episode.budget.items.firstWhere((i) => i.id == 'lex_ja_douzo');
    expect(douzo.singleton, isTrue);
    validateEpisode(episode); // must not throw
  });

  test('INV-3: rejects a token that references an item outside the budget', () {
    final tampered = _mutableCopy(pilot01RegenJson);
    final page3 = (tampered['pages'] as List)[2] as Map<String, dynamic>;
    final panel7 = (page3['panels'] as List)[0] as Map<String, dynamic>;
    final token =
        ((panel7['bubbles'] as List)[0] as Map)['tokens'] as List;
    (token[0] as Map<String, dynamic>)['itemId'] = 'lex_ja_ghost';

    final episode = Episode.fromJson(tampered);

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('lex_ja_ghost'),
        ),
      ),
    );
  });

  test('INV-4: rejects a non-singleton item that only appears in one panel', () {
    final tampered = _mutableCopy(pilot01RegenJson);
    final lastPage = (tampered['pages'] as List).last as Map<String, dynamic>;
    final lastPanel = (lastPage['panels'] as List).last as Map<String, dynamic>;
    (lastPanel['bubbles'] as List)
        .removeWhere((b) => (b as Map)['speakerId'] == 'buch');

    final episode = Episode.fromJson(tampered);

    expect(
      () => validateEpisode(episode),
      throwsA(
        isA<StoryValidationException>().having(
          (e) => e.violations.join(),
          'violations',
          contains('lex_ja_ame'),
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/episode_validator_test.dart`
Expected: FAIL — `lib/features/story/episode_validator.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/episode_validator.dart`:

```dart
import 'episode.dart';

class StoryValidationException implements Exception {
  final List<String> violations;
  const StoryValidationException(this.violations);

  @override
  String toString() =>
      'StoryValidationException:\n${violations.map((v) => '  - $v').join('\n')}';
}

/// Enforces INV-3 (no panel may use an item outside the episode's declared
/// budget) and INV-4 (every non-singleton budgeted item must appear as a
/// tagged token in ≥2 distinct panels). Throws [StoryValidationException]
/// listing every violation found; does not stop at the first one.
void validateEpisode(Episode episode) {
  final violations = <String>[];
  final budgetIds = {for (final item in episode.budget.items) item.id};
  final panelsByItem = <String, Set<int>>{};

  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        final itemId = token.itemId;
        if (itemId == null) continue;
        if (!budgetIds.contains(itemId)) {
          violations.add(
            'Panel ${panel.index}: token "${token.surface}" references item '
            '"$itemId", which is not in the episode budget (INV-3).',
          );
          continue;
        }
        panelsByItem.putIfAbsent(itemId, () => {}).add(panel.index);
      }
    }
  }

  for (final item in episode.budget.items) {
    final panelCount = panelsByItem[item.id]?.length ?? 0;
    final minRequired = item.singleton ? 1 : 2;
    if (panelCount < minRequired) {
      violations.add(
        'Item "${item.id}" appears in $panelCount panel(s) but requires at '
        'least $minRequired (singleton=${item.singleton}) (INV-4).',
      );
    }
  }

  if (violations.isNotEmpty) {
    throw StoryValidationException(violations);
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/episode_validator_test.dart`
Expected: PASS (all 4 tests).

- [ ] **Step 5: Run the full new test suite together**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS (all tests across Tasks 1–3).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/episode_validator.dart test/features/story/episode_validator_test.dart
git commit -m "feat(story): add episode validator enforcing INV-3 and INV-4"
```
