# Manga-Vollbild — Plan A: App (Reader-Vollbild, zwei Formate, Titelkarte)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Der Story-Reader zeigt jedes Panel bildschirmfüllend im passenden Format (quer/hoch), rechnet die Tippflächen auf den Beschnitt um, blendet die Systemleisten beim Lesen aus und öffnet die Folge mit einer Titelkarte über dem Titelbild — alles mit optionalen Feldern, sodass Folge 01 unverändert weiterläuft, bis Plan B die Bilder liefert.

**Architecture:** Drei kleine neue Einheiten (Datenfelder im Episodenschema, reine Geometrie-Funktionen für den Cover-Beschnitt, ein injizierbarer Vollbild-Adapter) und ein Umbau der Lesephase in `story_reader_screen.dart` von „AspectRatio + Scroll" auf „Stack in Schirmgröße". Kein neuer State, keine neuen Provider; `StoryRoute` bleibt bis auf den Adapter-Default unverändert.

**Tech Stack:** Flutter (Widget-Tests mit `flutter_test`, `tester.view.physicalSize` für Handy-Lagen), Dart 3, `SystemChrome` für den Vollbildmodus.

**Spec:** `docs/superpowers/specs/2026-09-23-manga-vollbild-titelbild-design.md` (§5 Datenformat, §7 Reader, §8 Invarianten). Plan B (Bilder, Layout-Datei, Folge-01-Verdrahtung) ist `docs/superpowers/plans/2026-09-23-manga-vollbild-bilder.md` und setzt Task 1 dieses Plans voraus.

## Global Constraints

- Branch: von `design/manga-vollbild` (Basis PR #51 `fix/reader-ux-feedback`) einen Arbeitszweig `impl/manga-vollbild-app` anlegen; Worktree-Guard: keine Heredocs/Schleifen/mehrzeiligen `-m` in Bash — Dateien mit dem Write-Tool schreiben, Commits mit `git commit -F <datei>`.
- Tests: `flutter test <datei>` je Task; Vollsuite am Ende. Die 8 roten `test/mining_packs/ja/`-Native-Tokenizer-Tests sind vorbestehend („grün" = „+N −8").
- Alle neuen Felder sind optional (`String?`, `StoryPolygon?`); `fromJson` darf bei fehlendem Schlüssel nie werfen (Spec §5.1).
- Seitenverhältnisse der ausgelieferten Bilder sind Konstanten: quer `1920 / 1072`, hoch `1080 / 1936` (Spec §3.1). Kein Bild wird zur Größenbestimmung dekodiert.
- Keine Gamification, kein Gate: der Reader bleibt ohne Titelbild, ohne Hochbild und ohne Vollbild-Adapter voll lesbar (INV-1).
- Deutsch ist Bedienung, Japanisch lebt im Artwork (INV-16, Reader-Erleben §1): die Titelkarte zeigt `titleJa` nur als Anzeige neben dem deutschen Titel, nie allein.
- Bestehende Widget-Keys bleiben erhalten: `story-title-card`, `story-reader-panel`, `story-reader-back`, `story-bubble-hit-$i`, `story-thought-box`, `story-diegetic-prompt`, `story-reaction-caption`, `story-end-card`, `dictionary-sheet`.
- Commit-Trailer wörtlich: `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` (Subagenten setzen sonst ihren eigenen Modellnamen).

## Review Focus

1. **Handy wird mitten in der Folge gedreht:** Position und Reaktionszustand bleiben, nur das Bild und die Tippflächen wechseln. Test in Task 4 (Drehen nach Vorwärtsblättern zeigt weiterhin Panel 2).
2. **Hochbild fehlt bei einem Panel (Übergangszeit, alte Daten):** Hochkant zeigt das Querbild bildschirmfüllend beschnitten, keine graue Fläche, kein Absturz. Test in Task 4.
3. **Tippfläche liegt teilweise im beschnittenen Rand:** Der sichtbare Teil ist tippbar, der unsichtbare Teil fängt keine Taps außerhalb des Bildes ab (Stack clippt). Test in Task 4 (Rechteck-Abbildung mit negativem Versatz).
4. **Reader wird per Zurück-Geste verlassen, ohne die Endkarte zu erreichen:** Systemleisten kommen zurück. Test in Task 3 (`exitImmersive` beim Dispose).
5. **Titelbild-Datei fehlt oder ist kaputt:** Titelkarte bleibt lesbar (dunkle Fläche statt Bild), Tipp startet die Folge. Test in Task 5 (`errorBuilder`).

---

### Task 1: Episodenschema — optionale Felder für Hochbild, Hoch-Tippfläche, Titelbild

**Files:**
- Modify: `lib/features/story/episode.dart` (Klassen `StoryBubble`, `StoryInteraction`, `StoryPanel`, `Episode`)
- Test: `test/features/story/episode_test.dart`

**Interfaces:**
- Consumes: nichts Neues.
- Produces (spätere Tasks und Plan B verlassen sich darauf):
  - `enum PanelFormat { landscape, portrait }`
  - `StoryBubble.hitAreaPortrait: StoryPolygon?` und `StoryPolygon StoryBubble.hitAreaFor(PanelFormat f)` (hoch → `hitAreaPortrait ?? hitArea`, quer → `hitArea`)
  - `StoryInteraction.reactionAssetPortrait: String?` und `String? StoryInteraction.reactionAssetFor(PanelFormat f)`
  - `StoryPanel.assetPortrait: String?` und `String StoryPanel.assetFor(PanelFormat f)`
  - `Episode.cover: String?`, `Episode.coverPortrait: String?`, `Episode.titleJa: String?`, `String? Episode.coverFor(PanelFormat f)`
  - JSON-Schlüssel: `assetPortrait`, `hitAreaPortrait`, `reactionAssetPortrait`, `cover`, `coverPortrait`, `titleJa`

- [ ] **Step 1: Failing Tests schreiben** — am Ende von `test/features/story/episode_test.dart` (innerhalb `main()`) anhängen:

```dart
  group('Manga-Vollbild: optionale Format-Felder (Spec §5.1)', () {
    Map<String, dynamic> panelJson({Map<String, dynamic> extra = const {}}) => {
          'index': 1,
          'asset': 'assets/story/folge01/p01.jpg',
          'bubbles': [
            {
              'speakerId': 'signage',
              'text': 'みなみまち駅',
              'hitArea': [
                {'x': 0.06, 'y': 0.05},
                {'x': 0.48, 'y': 0.05},
                {'x': 0.48, 'y': 0.18},
                {'x': 0.06, 'y': 0.18},
              ],
              'tokens': [],
              ...extra,
            },
          ],
          'thoughts': [],
          'interactions': [
            {
              'type': 'trace',
              'diegetic': true,
              'reactionAsset': 'assets/story/folge01/p02_reaction.jpg',
              'reactionAssetPortrait':
                  'assets/story/folge01/p02_reaction_hoch.jpg',
            },
          ],
        };

    Episode episodeWith(Map<String, dynamic> panel,
            {Map<String, dynamic> top = const {}}) =>
        Episode.fromJson({
          'id': 'ep_fmt',
          'seasonId': 'season_test',
          'orderIndex': 1,
          'title': 'Regen',
          'locale': 'ja',
          'era': '1996',
          'pages': [
            {'index': 0, 'panels': [panel]},
          ],
          ...top,
        });

    test('fehlende Schlüssel ergeben null und die Quer-Werte gelten', () {
      final ep = episodeWith(panelJson());
      final panel = ep.allPanels.first;
      expect(panel.assetPortrait, isNull);
      expect(panel.assetFor(PanelFormat.portrait), panel.asset);
      expect(panel.assetFor(PanelFormat.landscape), panel.asset);
      final bubble = panel.bubbles.first;
      expect(bubble.hitAreaPortrait, isNull);
      expect(bubble.hitAreaFor(PanelFormat.portrait).points, hasLength(4));
      expect(ep.cover, isNull);
      expect(ep.coverPortrait, isNull);
      expect(ep.titleJa, isNull);
      expect(ep.coverFor(PanelFormat.portrait), isNull);
    });

    test('Hochbild, Hoch-Tippfläche und Reaktions-Hochbild werden gelesen', () {
      final ep = episodeWith({
        ...panelJson(extra: {
          'hitAreaPortrait': [
            {'x': 0.10, 'y': 0.60},
            {'x': 0.90, 'y': 0.60},
            {'x': 0.90, 'y': 0.70},
            {'x': 0.10, 'y': 0.70},
          ],
        }),
        'assetPortrait': 'assets/story/folge01/p01_hoch.jpg',
      });
      final panel = ep.allPanels.first;
      expect(panel.assetFor(PanelFormat.portrait),
          'assets/story/folge01/p01_hoch.jpg');
      expect(panel.assetFor(PanelFormat.landscape),
          'assets/story/folge01/p01.jpg');
      final hoch = panel.bubbles.first.hitAreaFor(PanelFormat.portrait);
      expect(hoch.points.first.y, 0.60);
      expect(panel.bubbles.first.hitAreaFor(PanelFormat.landscape).points.first.y,
          0.05);
      final it = panel.interactions.first;
      expect(it.reactionAssetFor(PanelFormat.portrait),
          'assets/story/folge01/p02_reaction_hoch.jpg');
      expect(it.reactionAssetFor(PanelFormat.landscape),
          'assets/story/folge01/p02_reaction.jpg');
    });

    test('Titelbild in beiden Formaten und japanischer Titel', () {
      final ep = episodeWith(panelJson(), top: {
        'cover': 'assets/story/folge01/titel.jpg',
        'coverPortrait': 'assets/story/folge01/titel_hoch.jpg',
        'titleJa': '雨',
      });
      expect(ep.coverFor(PanelFormat.landscape), 'assets/story/folge01/titel.jpg');
      expect(ep.coverFor(PanelFormat.portrait),
          'assets/story/folge01/titel_hoch.jpg');
      expect(ep.titleJa, '雨');
    });

    test('Titelbild nur quer: hoch fällt auf quer zurück', () {
      final ep = episodeWith(panelJson(), top: {
        'cover': 'assets/story/folge01/titel.jpg',
      });
      expect(ep.coverFor(PanelFormat.portrait), 'assets/story/folge01/titel.jpg');
    });
  });
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `flutter test test/features/story/episode_test.dart`
Expected: Kompilierfehler „Undefined name 'PanelFormat'" / „The getter 'assetPortrait' isn't defined".

- [ ] **Step 3: Schema erweitern** — in `lib/features/story/episode.dart`:

Direkt nach der Klasse `StoryPolygon` einfügen:

```dart
/// Anzeigeformat eines Panels — quer (16:9) oder hoch (9:16). Der Reader
/// wählt es nach Handy-Lage (Spec Manga-Vollbild §7.1).
enum PanelFormat { landscape, portrait }
```

`StoryBubble` ersetzen durch:

```dart
class StoryBubble {
  final String speakerId;
  final String text;
  final String? audioRef;

  /// Tippfläche im Querbild (normiert 0..1).
  final StoryPolygon hitArea;

  /// Tippfläche im Hochbild (Spec Manga-Vollbild §5.1). Null = [hitArea] gilt.
  final StoryPolygon? hitAreaPortrait;
  final List<StoryToken> tokens;

  const StoryBubble({
    required this.speakerId,
    required this.text,
    this.audioRef,
    required this.hitArea,
    this.hitAreaPortrait,
    required this.tokens,
  });

  StoryPolygon hitAreaFor(PanelFormat format) =>
      format == PanelFormat.portrait ? (hitAreaPortrait ?? hitArea) : hitArea;

  factory StoryBubble.fromJson(Map<String, dynamic> j) => StoryBubble(
        speakerId: j['speakerId'] as String,
        text: j['text'] as String,
        audioRef: j['audioRef'] as String?,
        hitArea: StoryPolygon.fromJson(j['hitArea'] as List?),
        hitAreaPortrait: j['hitAreaPortrait'] == null
            ? null
            : StoryPolygon.fromJson(j['hitAreaPortrait'] as List?),
        tokens: [
          for (final t in (j['tokens'] as List? ?? const []))
            StoryToken.fromJson(t as Map<String, dynamic>),
        ],
      );
}
```

In `StoryInteraction` nach `reactionAsset` einfügen und Konstruktor/fromJson ergänzen:

```dart
  /// Reaktions-Variante im Hochformat (Spec Manga-Vollbild §5.1).
  final String? reactionAssetPortrait;
```
```dart
    this.reactionAssetPortrait,
```
```dart
        reactionAssetPortrait: j['reactionAssetPortrait'] as String?,
```
und als Methode in der Klasse:
```dart
  String? reactionAssetFor(PanelFormat format) =>
      format == PanelFormat.portrait
          ? (reactionAssetPortrait ?? reactionAsset)
          : reactionAsset;
```

In `StoryPanel` nach `asset`:

```dart
  /// Hochbild (9:16). Null = [asset] wird auch hochkant gezeigt.
  final String? assetPortrait;
```
Konstruktor: `this.assetPortrait,` (nach `required this.asset,`); fromJson: `assetPortrait: j['assetPortrait'] as String?,`; Methode:
```dart
  String assetFor(PanelFormat format) =>
      format == PanelFormat.portrait ? (assetPortrait ?? asset) : asset;
```

In `Episode` nach `outro`:

```dart
  /// Titelbild der Titelkarte, quer / hoch (Spec Manga-Vollbild §7.3). Ohne
  /// [cover] zeigt die Titelkarte nur Text.
  final String? cover;
  final String? coverPortrait;

  /// Japanische Schreibung des Titels, nur Anzeige neben dem deutschen Titel.
  final String? titleJa;
```
Konstruktor: `this.cover, this.coverPortrait, this.titleJa,` (nach `this.outro,`); fromJson: `cover: j['cover'] as String?, coverPortrait: j['coverPortrait'] as String?, titleJa: j['titleJa'] as String?,`; Methode:
```dart
  String? coverFor(PanelFormat format) =>
      format == PanelFormat.portrait ? (coverPortrait ?? cover) : cover;
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/story/episode_test.dart`
Expected: alle Tests PASS.

- [ ] **Step 5: Validator und Analyse prüfen**

Run: `flutter analyze lib/features/story/episode.dart && flutter test test/features/story/episode_validator_test.dart test/features/story/folge_01_regen_test.dart`
Expected: keine Analyse-Warnungen, Tests PASS (der Validator kennt die neuen Felder nicht und ignoriert sie).

- [ ] **Step 6: Commit**

Commit-Nachricht in `/tmp/msg-t1.txt` (Write-Tool), dann:
```bash
git add lib/features/story/episode.dart test/features/story/episode_test.dart
git commit -F /tmp/msg-t1.txt
```
Inhalt: `feat(story): Episodenschema — Hochbild, Hoch-Tippfläche, Titelbild als optionale Felder` + Leerzeile + Trailer.

---

### Task 2: Panel-Geometrie — Cover-Beschnitt und Tippflächen-Abbildung als reine Funktionen

**Files:**
- Create: `lib/features/story/panel_geometry.dart`
- Test: `test/features/story/panel_geometry_test.dart`

**Interfaces:**
- Consumes: `PanelFormat` aus Task 1.
- Produces:
  - `const double kLandscapeAspect = 1920 / 1072;`, `const double kPortraitAspect = 1080 / 1936;`
  - `double aspectOf(PanelFormat f)`
  - `PanelFormat formatForSize(Size screen)` (höher als breit → portrait)
  - `Rect coverRect(Size screen, double aspect)` — Rechteck des Bildes unter `BoxFit.cover`, zentriert
  - `Rect mapToScreen(Rect normalized, Rect imageRect)` — normiertes Bildrechteck → Schirmkoordinaten

- [ ] **Step 1: Failing Tests schreiben** — `test/features/story/panel_geometry_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart' show PanelFormat;
import 'package:nihongo_app/features/story/panel_geometry.dart';

void main() {
  test('Format folgt der Schirmlage', () {
    expect(formatForSize(const Size(1080, 2340)), PanelFormat.portrait);
    expect(formatForSize(const Size(2340, 1080)), PanelFormat.landscape);
    expect(formatForSize(const Size(1000, 1000)), PanelFormat.landscape);
  });

  test('Seitenverhältnisse sind die Auslieferungsgrößen der Spec', () {
    expect(aspectOf(PanelFormat.landscape), closeTo(1920 / 1072, 1e-9));
    expect(aspectOf(PanelFormat.portrait), closeTo(1080 / 1936, 1e-9));
  });

  test('S23 hochkant: Hochbild füllt die Höhe, Überstand links/rechts symmetrisch',
      () {
    final r = coverRect(const Size(1080, 2340), kPortraitAspect);
    expect(r.height, closeTo(2340, 1e-6));
    expect(r.width, closeTo(2340 * kPortraitAspect, 1e-6)); // ≈ 1305,4
    expect(r.left, closeTo((1080 - r.width) / 2, 1e-6)); // ≈ −112,7
    expect(r.top, closeTo(0, 1e-9));
    expect(r.center.dx, closeTo(540, 1e-6));
  });

  test('S23 quer: Querbild füllt die Breite, Überstand oben/unten symmetrisch',
      () {
    final r = coverRect(const Size(2340, 1080), kLandscapeAspect);
    expect(r.width, closeTo(2340, 1e-6));
    expect(r.height, closeTo(2340 / kLandscapeAspect, 1e-6)); // ≈ 1306,5
    expect(r.top, closeTo((1080 - r.height) / 2, 1e-6)); // ≈ −113,3
    expect(r.left, closeTo(0, 1e-9));
  });

  test('Tablet 4:3 quer: Querbild füllt die Höhe, Überstand seitlich', () {
    final r = coverRect(const Size(1600, 1200), kLandscapeAspect);
    expect(r.height, closeTo(1200, 1e-6));
    expect(r.width, closeTo(1200 * kLandscapeAspect, 1e-6));
    expect(r.left, lessThan(0));
  });

  test('normiertes Rechteck wird relativ zum Bildrechteck abgebildet', () {
    final image = Rect.fromLTWH(-100, 0, 1300, 2340);
    final hit = mapToScreen(const Rect.fromLTWH(0.1, 0.5, 0.4, 0.1), image);
    expect(hit.left, closeTo(-100 + 130, 1e-6));
    expect(hit.top, closeTo(1170, 1e-6));
    expect(hit.width, closeTo(520, 1e-6));
    expect(hit.height, closeTo(234, 1e-6));
  });
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `flutter test test/features/story/panel_geometry_test.dart`
Expected: Kompilierfehler, Datei `panel_geometry.dart` fehlt.

- [ ] **Step 3: Implementieren** — `lib/features/story/panel_geometry.dart`:

```dart
import 'dart:ui';

import 'episode.dart' show PanelFormat;

/// Seitenverhältnisse der ausgelieferten Bilder (Spec Manga-Vollbild §3.1).
/// Konstanten, damit der Reader kein Bild dekodieren muss, um Tippflächen
/// zu platzieren.
const double kLandscapeAspect = 1920 / 1072;
const double kPortraitAspect = 1080 / 1936;

double aspectOf(PanelFormat format) =>
    format == PanelFormat.portrait ? kPortraitAspect : kLandscapeAspect;

/// Höher als breit → Hochformat; quadratisch zählt als quer.
PanelFormat formatForSize(Size screen) =>
    screen.height > screen.width ? PanelFormat.portrait : PanelFormat.landscape;

/// Rechteck, das ein Bild mit Seitenverhältnis [aspect] (Breite/Höhe) unter
/// `BoxFit.cover` auf [screen] einnimmt: eine Achse füllt den Schirm genau,
/// die andere steht symmetrisch über (Beschnitt gleichmäßig an beiden
/// Rändern).
Rect coverRect(Size screen, double aspect) {
  final heightIfWidthFills = screen.width / aspect;
  final double w, h;
  if (heightIfWidthFills >= screen.height) {
    w = screen.width;
    h = heightIfWidthFills;
  } else {
    h = screen.height;
    w = screen.height * aspect;
  }
  return Rect.fromLTWH((screen.width - w) / 2, (screen.height - h) / 2, w, h);
}

/// Bildet ein normiertes Rechteck (0..1 im Bild) in Schirmkoordinaten ab.
Rect mapToScreen(Rect normalized, Rect imageRect) => Rect.fromLTWH(
      imageRect.left + normalized.left * imageRect.width,
      imageRect.top + normalized.top * imageRect.height,
      normalized.width * imageRect.width,
      normalized.height * imageRect.height,
    );
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/story/panel_geometry_test.dart`
Expected: 6 Tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/panel_geometry.dart test/features/story/panel_geometry_test.dart
git commit -F /tmp/msg-t2.txt
```
Inhalt: `feat(story): Panel-Geometrie — Cover-Beschnitt und Tippflächen-Abbildung` + Trailer.

---

### Task 3: Vollbild-Adapter — Systemleisten beim Lesen aus, danach wieder da

**Files:**
- Create: `lib/features/story/reader_system_ui.dart`
- Modify: `lib/features/story/story_reader_screen.dart` (Konstruktor, `_restorePosition`, `_beginReading`, `_advance`, neues `dispose`)
- Test: `test/features/story/story_reader_fullscreen_test.dart` (neu; Task 4 und 5 hängen weitere Tests an)

**Interfaces:**
- Consumes: nichts.
- Produces:
  - `abstract class ReaderSystemUi { Future<void> enterImmersive(); Future<void> exitImmersive(); }`
  - `class SystemChromeReaderUi implements ReaderSystemUi` (const-Konstruktor)
  - `StoryReaderScreen({... ReaderSystemUi systemUi = const SystemChromeReaderUi()})`

- [ ] **Step 1: Failing Test schreiben** — `test/features/story/story_reader_fullscreen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/reader_system_ui.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:nihongo_app/features/story/story_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingSystemUi implements ReaderSystemUi {
  final List<String> calls = [];
  @override
  Future<void> enterImmersive() async => calls.add('enter');
  @override
  Future<void> exitImmersive() async => calls.add('exit');
}

Future<StoryProgressStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  return StoryProgressStore(await SharedPreferences.getInstance());
}

Future<void> noopSpeak(String text) async {}

/// Zwei Panels; Panel 1 hat Quer- und Hochbild und eine Blase mit beiden
/// Tippflächen, Panel 2 hat nur ein Querbild (Übergangsfall).
Episode twoFormatEpisode({String? cover, String? coverPortrait, String? titleJa}) =>
    Episode.fromJson({
      'id': 'ep_fullscreen',
      'seasonId': 'season_test',
      'orderIndex': 1,
      'title': 'Regen',
      'locale': 'ja',
      'era': '1996',
      if (cover != null) 'cover': cover,
      if (coverPortrait != null) 'coverPortrait': coverPortrait,
      if (titleJa != null) 'titleJa': titleJa,
      'budget': {'items': [], 'glyphs': []},
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/story/p01.jpg',
              'assetPortrait': 'assets/story/p01_hoch.jpg',
              'bubbles': [
                {
                  'speakerId': 'signage',
                  'text': 'みなみまち駅',
                  'hitArea': [
                    {'x': 0.06, 'y': 0.05},
                    {'x': 0.48, 'y': 0.05},
                    {'x': 0.48, 'y': 0.18},
                    {'x': 0.06, 'y': 0.18},
                  ],
                  'hitAreaPortrait': [
                    {'x': 0.10, 'y': 0.10},
                    {'x': 0.50, 'y': 0.10},
                    {'x': 0.50, 'y': 0.30},
                    {'x': 0.10, 'y': 0.30},
                  ],
                  'tokens': [
                    {'surface': '駅', 'reading': 'えき', 'itemId': 'lex_ja_eki'},
                  ],
                },
              ],
              'thoughts': [
                {'text': 'Das ist Mira.'},
              ],
              'interactions': [],
            },
            {
              'index': 1,
              'asset': 'assets/story/p02.jpg',
              'bubbles': [
                {'speakerId': 'narrator', 'text': 'Zweites Panel', 'tokens': []},
              ],
              'thoughts': [],
              'interactions': [],
            },
          ],
        },
      ],
    });

Future<void> pumpReader(WidgetTester tester, Episode episode,
    {required StoryProgressStore store, RecordingSystemUi? ui}) async {
  await tester.pumpWidget(MaterialApp(
    home: StoryReaderScreen(
      episode: episode,
      progressStore: store,
      speak: noopSpeak,
      dictionaryEntries: const [],
      knownIds: const {},
      systemUi: ui ?? RecordingSystemUi(),
    ),
  ));
  await tester.pump();
}

/// Schirm in logischen Pixeln setzen (S23 = 1080×2340 physisch, hier /2).
void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Vollbild-Adapter (Spec §7.1)', () {
    testWidgets('Lesephase schaltet Vollbild ein, Endkarte wieder aus',
        (tester) async {
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      expect(ui.calls, isEmpty, reason: 'Titelkarte zeigt die Leisten noch');

      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(ui.calls, ['enter']);

      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
      expect(ui.calls, ['enter', 'exit']);
    });

    testWidgets('Reader verlassen mitten in der Folge stellt die Leisten wieder her',
        (tester) async {
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(ui.calls, ['enter']);

      await tester.pumpWidget(const SizedBox()); // Route weg → dispose
      await tester.pump();
      expect(ui.calls, ['enter', 'exit']);
    });

    testWidgets('Wiedereinstieg mitten in der Folge schaltet sofort Vollbild ein',
        (tester) async {
      final store = await freshStore();
      await store.savePosition('ep_fullscreen', 1);
      final ui = RecordingSystemUi();
      await pumpReader(tester, twoFormatEpisode(), store: store, ui: ui);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-title-card')), findsNothing);
      expect(ui.calls, ['enter']);
    });
  });
}
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart`
Expected: Kompilierfehler „reader_system_ui.dart not found" / „No named parameter 'systemUi'".

- [ ] **Step 3: Adapter schreiben** — `lib/features/story/reader_system_ui.dart`:

```dart
import 'package:flutter/services.dart';

/// Schaltet die Systemleisten beim Lesen aus und danach wieder ein (Spec
/// Manga-Vollbild §7.1). Als Schnittstelle, damit Widget-Tests beobachten
/// können, was der Reader schaltet, ohne `SystemChrome` zu berühren.
abstract class ReaderSystemUi {
  Future<void> enterImmersive();
  Future<void> exitImmersive();
}

/// Echte Umsetzung über `SystemChrome`. `immersiveSticky`: Leisten weg, ein
/// Wisch vom Rand zeigt sie kurz. Beim Verlassen kommen alle Leisten zurück.
class SystemChromeReaderUi implements ReaderSystemUi {
  const SystemChromeReaderUi();

  @override
  Future<void> enterImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  Future<void> exitImmersive() => SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
}
```

- [ ] **Step 4: Reader verdrahten** — in `lib/features/story/story_reader_screen.dart`:

Import ergänzen: `import 'reader_system_ui.dart';`

Im Widget nach `onEnterCafe` ein Feld + Konstruktor-Parameter:
```dart
  /// Vollbild beim Lesen (Spec Manga-Vollbild §7.1). Tests injizieren eine
  /// aufzeichnende Attrappe; die App nimmt den `SystemChrome`-Default.
  final ReaderSystemUi systemUi;
```
```dart
    this.systemUi = const SystemChromeReaderUi(),
```

Im State:
- `_restorePosition`: nach dem `setState(...)`-Block, innerhalb `if (resumeMidway) { ... }` als erste Zeile `widget.systemUi.enterImmersive();` ergänzen.
- `_beginReading`: als erste Zeile `widget.systemUi.enterImmersive();`.
- `_advance`: im Zweig `if (current >= _panels.length - 1) { ... }` vor dem `setState` die Zeile `widget.systemUi.exitImmersive();`.
- Neue Methode nach `initState`:
```dart
  @override
  void dispose() {
    // Zurück-Geste, Café-Wechsel, App-Navigation: Leisten immer wieder her.
    // Doppelt aufgerufen (Endkarte + dispose) ist unschädlich.
    widget.systemUi.exitImmersive();
    super.dispose();
  }
```

- [ ] **Step 5: Tests grün**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart test/features/story/story_reader_screen_test.dart`
Expected: alle PASS (die bestehenden Reader-Tests laufen mit dem `SystemChrome`-Default; im Test ruft `SystemChrome` nur einen Platform-Channel ohne Handler auf und wirft nicht).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/reader_system_ui.dart lib/features/story/story_reader_screen.dart test/features/story/story_reader_fullscreen_test.dart
git commit -F /tmp/msg-t3.txt
```
Inhalt: `feat(story): Vollbild beim Lesen — Systemleisten aus, beim Verlassen wieder an` + Trailer.

---

### Task 4: Lesephase als Vollbild — Format nach Lage, Cover-Beschnitt, Tippflächen umgerechnet

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (`_effectiveAssetFor`, Lesephase in `build`, Overlays)
- Test: `test/features/story/story_reader_fullscreen_test.dart` (Gruppe anhängen)

**Interfaces:**
- Consumes: `PanelFormat`, `assetFor`, `hitAreaFor`, `reactionAssetFor` (Task 1); `formatForSize`, `coverRect`, `aspectOf`, `mapToScreen` (Task 2).
- Produces: neue Keys `story-bubble-footer` (Blasen ohne Tippfläche) und `story-panel-image` (das Bild-Widget). Bestehende Keys bleiben.

- [ ] **Step 1: Failing Tests schreiben** — in `story_reader_fullscreen_test.dart` innerhalb `main()` anhängen:

```dart
  group('Lesephase als Vollbild (Spec §7.1/§7.2)', () {
    Future<void> startReading(WidgetTester tester, {RecordingSystemUi? ui}) async {
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore(), ui: ui);
      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
    }

    String shownAsset(WidgetTester tester) {
      final img = tester.widget<Image>(find.byKey(const ValueKey('story-panel-image')));
      return (img.image as AssetImage).assetName;
    }

    testWidgets('hochkant zeigt das Hochbild, quer das Querbild', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      expect(shownAsset(tester), 'assets/story/p01_hoch.jpg');

      setScreen(tester, const Size(1170, 540));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p01.jpg');
    });

    testWidgets('Panel ohne Hochbild zeigt hochkant das Querbild', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');
      expect(find.byKey(const ValueKey('story-bubble-footer')), findsOneWidget);
      expect(find.text('Zweites Panel'), findsOneWidget);
    });

    testWidgets('das Bild füllt den Schirm (Cover-Rechteck), nicht nur die Breite',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      final rect = tester.getRect(find.byKey(const ValueKey('story-panel-image')));
      expect(rect.height, closeTo(1170, 0.5));
      expect(rect.width, closeTo(1170 * (1080 / 1936), 0.5));
      expect(rect.left, closeTo((540 - rect.width) / 2, 0.5));
    });

    testWidgets('Tippfläche liegt relativ zum beschnittenen Bild, hochkant aus hitAreaPortrait',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      final imageW = 1170 * (1080 / 1936);
      final imageLeft = (540 - imageW) / 2;
      final hit = tester.getRect(find.byKey(const ValueKey('story-bubble-hit-0')));
      expect(hit.left, closeTo(imageLeft + 0.10 * imageW, 0.5));
      expect(hit.top, closeTo(0.10 * 1170, 0.5));
      expect(hit.width, closeTo(0.40 * imageW, 0.5));
      expect(hit.height, closeTo(0.20 * 1170, 0.5));
    });

    testWidgets('quer: Tippfläche aus hitArea, mit negativem Versatz oben', (tester) async {
      setScreen(tester, const Size(1170, 540));
      await startReading(tester);
      final imageH = 1170 / (1920 / 1072);
      final imageTop = (540 - imageH) / 2; // negativ
      final hit = tester.getRect(find.byKey(const ValueKey('story-bubble-hit-0')));
      expect(hit.left, closeTo(0.06 * 1170, 0.5));
      expect(hit.top, closeTo(imageTop + 0.05 * imageH, 0.5));
      expect(hit.width, closeTo(0.42 * 1170, 0.5));
    });

    testWidgets('Tipp auf die Tippfläche öffnet weiterhin das Wörterbuch', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);
    });

    testWidgets('Drehen mitten in der Folge behält die Position', (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');

      setScreen(tester, const Size(1170, 540));
      await tester.pumpAndSettle();
      expect(shownAsset(tester), 'assets/story/p02.jpg');
      expect(find.text('Zweites Panel'), findsOneWidget);
    });

    testWidgets('Gedanken-Kasten und Zurück-Chip liegen im Bild, keine AppBar mehr',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await startReading(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('story-thought-box')), findsOneWidget);
      expect(find.text('Das ist Mira.'), findsOneWidget);
      final back = tester.widget<IconButton>(find.byKey(const ValueKey('story-reader-back')));
      expect(back.onPressed, isNull, reason: 'auf Panel 1 gesperrt');
    });
  });
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart`
Expected: FAIL — `story-panel-image` nicht gefunden, Bildrechteck hat Panelbreite statt Schirmhöhe, `AppBar` vorhanden.

- [ ] **Step 3: Lesephase umbauen** — in `story_reader_screen.dart`:

Imports ergänzen: `import 'panel_geometry.dart';`

Die Konstante `_panelAspectRatio` samt Kommentar entfernen (sie wird nicht mehr gebraucht).

`_effectiveAssetFor` ersetzen durch:
```dart
  String _effectiveAssetFor(StoryPanel panel, PanelFormat format) {
    final reacted = _reactedPositions.contains(_position);
    final reaction = _diegeticInteractionOf(panel)?.reactionAssetFor(format);
    return (reacted && reaction != null) ? reaction : panel.assetFor(format);
  }
```

Den gesamten Rest der Klasse `_StoryReaderScreenState` ab der Zeile `final panel = _panels[position];` (also die Lesephase in `build` samt der schließenden Klammer von `build` **und** der schließenden Klammer der Klasse) ersetzen durch den folgenden Block; `_BubbleContent` darunter bleibt unverändert stehen:

```dart
    final panel = _panels[position];
    final pending = _pendingDiegeticOf(panel, position);
    final reactionCaption = _reactedPositions.contains(_position)
        ? _diegeticInteractionOf(panel)?.reactionCaption
        : null;
    final footerBubbles = [
      for (final b in panel.bubbles)
        if (b.hitArea.points.isEmpty) b,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        key: const ValueKey('story-reader-panel'),
        behavior: HitTestBehavior.opaque,
        onTap: _advance,
        child: LayoutBuilder(builder: (context, constraints) {
          final screen = Size(constraints.maxWidth, constraints.maxHeight);
          final format = formatForSize(screen);
          final imageRect = coverRect(screen, aspectOf(format));
          final asset = _effectiveAssetFor(panel, format);
          return Stack(
            clipBehavior: Clip.hardEdge,
            fit: StackFit.expand,
            children: [
              // Bild im Cover-Rechteck: eine Achse füllt den Schirm, die
              // andere steht symmetrisch über (Spec §3.1/§7.1).
              Positioned.fromRect(
                rect: imageRect,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    asset,
                    key: ValueKey('story-panel-image'),
                    fit: BoxFit.fill,
                    errorBuilder: (_, _, _) =>
                        Container(color: const Color(0xFF2A2A2A)),
                  ),
                ),
              ),
              // Tippflächen der gelettertern Blasen, relativ zum Bildrechteck.
              for (var i = 0; i < panel.bubbles.length; i++)
                if (panel.bubbles[i].hitAreaFor(format).points.isNotEmpty)
                  Positioned.fromRect(
                    rect: mapToScreen(
                        _bboxOf(panel.bubbles[i].hitAreaFor(format)),
                        imageRect),
                    child: GestureDetector(
                      key: ValueKey('story-bubble-hit-$i'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        widget.speak(panel.bubbles[i].text);
                        _openDictionary();
                      },
                    ),
                  ),
              // Bedienung und Erzählstimme über dem Bild, innerhalb der
              // Systemränder (Spec §7.2).
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BackChip(
                            enabled: position > 0,
                            onPressed: _goBack,
                          ),
                          const SizedBox(width: 8),
                          if (panel.thoughts.isNotEmpty)
                            Expanded(
                              child: Container(
                                key: const ValueKey('story-thought-box'),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xF2FFF8E7),
                                  border: Border.all(
                                      color: const Color(0xFF444444)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    for (final thought in panel.thoughts)
                                      Text(thought.text,
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      if (footerBubbles.isNotEmpty)
                        Container(
                          key: const ValueKey('story-bubble-footer'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFFFFF),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final bubble in footerBubbles)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: _BubbleContent(
                                      bubble: bubble, speak: widget.speak),
                                ),
                            ],
                          ),
                        ),
                      if (pending != null)
                        GestureDetector(
                          key: const ValueKey('story-diegetic-prompt'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (pending.type == InteractionType.trace) {
                              _openTrace(position);
                            } else {
                              _openSpeak(position);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xF2FFF8E7),
                              border:
                                  Border.all(color: const Color(0xFF444444)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  pending.type == InteractionType.trace
                                      ? Icons.edit
                                      : Icons.mic,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pending.promptText ??
                                        'Tippen, um mitzumachen',
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                                const Icon(Icons.touch_app, size: 18),
                              ],
                            ),
                          ),
                        ),
                      if (reactionCaption != null)
                        Container(
                          key: const ValueKey('story-reaction-caption'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFF8E7),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Text(
                            reactionCaption,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Zurück als kleiner halbtransparenter Chip oben links (die AppBar entfällt
/// im Vollbild, Spec §7.2). Behält den Key `story-reader-back`, damit der
/// Sperrzustand auf Panel 1 weiter testbar ist.
class _BackChip extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _BackChip({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0x99000000),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        key: const ValueKey('story-reader-back'),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
```

Hinweis: Die alten `Positioned`-Overlays (Gedanken-Kasten oben, Mitmach-Hinweis unten, Reaktions-Zeile unten, Blasen unter dem Bild) und das `SingleChildScrollView`/`AspectRatio` sind damit vollständig ersetzt; `_BubbleContent` bleibt unverändert und wird jetzt in der Fußzeile benutzt.

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart`
Expected: alle PASS.

- [ ] **Step 5: Bestehende Reader-Tests anpassen**

Run: `flutter test test/features/story/`
Erwartete Brüche und ihre Behebung (nur Assertions, die das alte Layout kodieren):
- Tests, die den Folgentitel in der AppBar suchen (`find.text('Test Episode')` während der Lesephase): Assertion entfernen, der Titel steht jetzt nur auf der Titelkarte.
- Tests, die Blasentext „unter dem Bild" per `find.text(...)` suchen: laufen weiter (Fußzeile zeigt denselben Text); falls `find.byType(SingleChildScrollView)` vorkommt, durch `find.byKey(const ValueKey('story-bubble-footer'))` ersetzen.
- Tests mit `tester.tapAt(const Offset(400, 50))` zum Schließen eines Sheets: laufen weiter (der Tap landet außerhalb des Sheets).
Alle anderen Fehlschläge sind echte Regressionen und werden im Code behoben, nicht im Test.

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/
git commit -F /tmp/msg-t4.txt
```
Inhalt: `feat(story): Lesephase als Vollbild — Format nach Lage, Cover-Beschnitt, Tippflächen umgerechnet` + Trailer.

---

### Task 5: Titelkarte mit Titelbild

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (Zweig `_phase == _ReaderPhase.title` in `build`)
- Test: `test/features/story/story_reader_fullscreen_test.dart` (Gruppe anhängen)

**Interfaces:**
- Consumes: `Episode.coverFor`, `Episode.titleJa`, `Episode.orderIndex` (Task 1); `formatForSize` (Task 2).
- Produces: Keys `story-title-cover` (Bild) und `story-title-ja` (japanischer Titel).

- [ ] **Step 1: Failing Tests schreiben** — anhängen:

```dart
  group('Titelkarte mit Titelbild (Spec §7.3)', () {
    testWidgets('mit Titelbild: Bild nach Lage, Folge, Titel, japanischer Titel, Anmoderation',
        (tester) async {
      setScreen(tester, const Size(540, 1170));
      await pumpReader(
          tester,
          twoFormatEpisode(
              cover: 'assets/story/titel.jpg',
              coverPortrait: 'assets/story/titel_hoch.jpg',
              titleJa: '雨'),
          store: await freshStore());
      final img = tester.widget<Image>(find.byKey(const ValueKey('story-title-cover')));
      expect((img.image as AssetImage).assetName, 'assets/story/titel_hoch.jpg');
      expect(find.text('Folge 1'), findsOneWidget);
      expect(find.text('Regen'), findsOneWidget);
      expect(find.byKey(const ValueKey('story-title-ja')), findsOneWidget);
      expect(find.text('雨'), findsOneWidget);
      expect(find.text('Tippe, um zu beginnen'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-panel-image')), findsOneWidget);
    });

    testWidgets('quer nimmt das Quer-Titelbild', (tester) async {
      setScreen(tester, const Size(1170, 540));
      await pumpReader(
          tester,
          twoFormatEpisode(
              cover: 'assets/story/titel.jpg',
              coverPortrait: 'assets/story/titel_hoch.jpg'),
          store: await freshStore());
      final img = tester.widget<Image>(find.byKey(const ValueKey('story-title-cover')));
      expect((img.image as AssetImage).assetName, 'assets/story/titel.jpg');
    });

    testWidgets('ohne Titelbild bleibt die Textkarte, ohne titleJa kein japanischer Titel',
        (tester) async {
      await pumpReader(tester, twoFormatEpisode(), store: await freshStore());
      expect(find.byKey(const ValueKey('story-title-cover')), findsNothing);
      expect(find.byKey(const ValueKey('story-title-ja')), findsNothing);
      expect(find.text('Regen'), findsOneWidget);
      expect(find.text('Tippe, um zu beginnen'), findsOneWidget);
    });

    testWidgets('kaputtes Titelbild: Karte bleibt lesbar und startet die Folge',
        (tester) async {
      await pumpReader(tester,
          twoFormatEpisode(cover: 'assets/story/gibt_es_nicht.jpg'),
          store: await freshStore());
      await tester.pumpAndSettle();
      expect(find.text('Regen'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('story-title-card')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('story-panel-image')), findsOneWidget);
    });
  });
```

- [ ] **Step 2: Test laufen lassen, Fehlschlag sehen**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart`
Expected: FAIL — `story-title-cover` nicht gefunden, „Folge 1" nicht gefunden.

- [ ] **Step 3: Titelkarte umbauen** — den Zweig `if (_phase == _ReaderPhase.title) { return Scaffold(...) }` ersetzen durch:

```dart
    if (_phase == _ReaderPhase.title) {
      final episode = widget.episode;
      final textTheme = Theme.of(context).textTheme;
      final hasCover = episode.cover != null;
      final onCover = hasCover ? Colors.white : null;

      final texts = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            hasCover ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text('Folge ${episode.orderIndex}',
              style: textTheme.labelLarge?.copyWith(color: onCover)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (episode.titleJa != null) ...[
                Text(episode.titleJa!,
                    key: const ValueKey('story-title-ja'),
                    style: textTheme.displaySmall?.copyWith(color: onCover)),
                const SizedBox(width: 12),
              ],
              Text(episode.title,
                  style: textTheme.headlineMedium?.copyWith(color: onCover)),
            ],
          ),
          if (episode.intro != null) ...[
            const SizedBox(height: 16),
            Text(episode.intro!,
                textAlign: hasCover ? TextAlign.start : TextAlign.center,
                style: TextStyle(color: onCover)),
          ],
          const SizedBox(height: 32),
          Text('Tippe, um zu beginnen',
              style: textTheme.bodySmall?.copyWith(color: onCover)),
        ],
      );

      return Scaffold(
        backgroundColor: hasCover ? Colors.black : null,
        body: GestureDetector(
          key: const ValueKey('story-title-card'),
          behavior: HitTestBehavior.opaque,
          onTap: _beginReading,
          child: hasCover
              ? LayoutBuilder(builder: (context, constraints) {
                  final format = formatForSize(
                      Size(constraints.maxWidth, constraints.maxHeight));
                  return Stack(fit: StackFit.expand, children: [
                    Image.asset(
                      episode.coverFor(format)!,
                      key: const ValueKey('story-title-cover'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: const Color(0xFF1B2220)),
                    ),
                    // Dunkler Verlauf unten, damit der Text auf jedem Motiv
                    // lesbar bleibt (Spec §7.3).
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xD9000000)],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: texts,
                        ),
                      ),
                    ),
                  ]);
                })
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: texts,
                  ),
                ),
        ),
      );
    }
```

- [ ] **Step 4: Tests grün**

Run: `flutter test test/features/story/story_reader_fullscreen_test.dart test/features/story/story_reader_screen_test.dart test/features/story/story_reader_end_card_test.dart`
Expected: alle PASS. Falls ein bestehender Test `find.text('Test Episode')` auf der Titelkarte zusammen mit einem Zähler prüft: „Folge 1" ist neu dazugekommen, `findsOneWidget` für den Titel bleibt gültig.

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_fullscreen_test.dart
git commit -F /tmp/msg-t5.txt
```
Inhalt: `feat(story): Titelkarte mit Titelbild, Folgennummer und japanischem Titel` + Trailer.

---

### Task 6: Analyse, Vollsuite, Route-Check

**Files:**
- Modify (nur falls nötig): `lib/features/story/story_route.dart`, betroffene Tests
- Test: gesamte Suite

**Interfaces:** keine neuen.

- [ ] **Step 1: Analyse**

Run: `flutter analyze`
Expected: 0 Fehler, 0 Warnungen in `lib/features/story/`. Unbenutzte Importe (z. B. wenn `AspectRatio` nirgends mehr vorkommt) entfernen.

- [ ] **Step 2: Route-Test**

Run: `flutter test test/features/story/story_route_test.dart test/features/story/story_route_cafe_test.dart`
Expected: PASS. `StoryRoute` übergibt kein `systemUi` (Default `SystemChromeReaderUi`); im Test wirft `SystemChrome` nicht. Falls der Test dennoch über einen fehlenden Platform-Handler stolpert: in `StoryRoute` ein optionales Feld `final ReaderSystemUi? systemUi;` ergänzen und im Test eine `RecordingSystemUi` durchreichen.

- [ ] **Step 3: Vollsuite**

Run: `flutter test`
Expected: „+N −8" — nur die 8 bekannten `test/mining_packs/ja/`-Native-Tokenizer-Fehler rot. Jeden anderen roten Test als Regression behandeln und im Code beheben.

- [ ] **Step 4: Commit + Push**

```bash
git add -A lib test
git commit -F /tmp/msg-t6.txt
git push -u origin impl/manga-vollbild-app
```
Inhalt: `chore(story): Analyse- und Suite-Nachzieher für das Reader-Vollbild` + Trailer (nur wenn es etwas zu committen gab). Danach Draft-PR `impl/manga-vollbild-app` → `design/manga-vollbild` öffnen; im PR-Text: Plan A komplett, Folge-01-Bilder folgen mit Plan B.
