# Reader-Erleben Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Der Story-Reader wird zur erlebbaren Geschichte: Titelkarte, Sprechblasen-Tippflächen im Bild, deutsche Erzählkästen und Bedienung, reagierende Panels nach Erfolg, Endkarte mit Haken, Wiederbetreten-Fix — plus Prototyp-Lettering auf den vorhandenen Panels, damit Uli das Erlebnis vor der finalen Renderarbeit beurteilen kann.

**Architecture:** Spec: `docs/superpowers/specs/2026-09-13-reader-erleben-design.md`. Zwei Ebenen: Japanisch nur im Artwork (Tippflächen über `StoryBubble.hitArea`, das bereits existiert und heute leer deserialisiert), Deutsch als Erzählstimme/Bedienung (Overlay-Erzählkästen, Titel-/Endkarte, Sheet-Texte). Der Reader-`build` bekommt Phasen (Titelkarte → Lesen → Endkarte) und die Panel-Region wird ein `Stack` mit `LayoutBuilder` (normierte 0..1-Koordinaten → Pixel). Erfolg einer diegetischen Interaktion tauscht das Panelbild weich gegen ein `reactionAsset` und zeigt eine `reactionCaption`.

**Tech Stack:** Flutter/Dart (Riverpod nur in der bestehenden Route, hier unberührt), `shared_preferences` (StoryProgressStore), Python 3 + Pillow 11 für das Lettering-Skript (Font: `/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf`, verifiziert CJK-fähig).

## Global Constraints

- **Deutsch ist Bediensprache, Japanisch ist Lernstoff** — kein japanischer Meta-/UI-Text. Die bestehenden Strings `なぞって:`, `よくできました ✓`, `もう一度どうぞ` werden ersetzt durch (wörtlich): Aufgabe Speak `Hör zu und sprich nach:` · Aufgabe Trace `Zeichne das Zeichen nach:` · Erfolg `Gut! ✓` · Misserfolg `Fast — hör noch einmal und versuch's gleich nochmal.`
- Invarianten unangetastet: kein Gate (INV-1: „weiter" überspringt immer), keine Punkte/Streaks (INV-10), Reaktions-Bild ist Bonusbild im selben Panel-Slot, kein Story-Ast.
- Alle neuen Episodenfelder optional mit Fallback: fehlendes `intro` → Titelkarte nur mit Titel; fehlendes `reactionAsset` → Erfolg zeigt nur Caption bzw. ✓; Bubble mit leerem `hitArea` → Dialog wie bisher unter dem Bild (Übergangs-Fallback).
- „Grün" heißt: Full-Suite-Fehler sind ausschließlich die 8 vorbestehenden in `test/mining_packs/ja/` (fehlende native `.so`, rot auch auf main).
- Keine neuen Dart-Dependencies. Python-Skript nutzt nur PIL (kein fontTools).
- Test-Kommandos aus dem Repo-Root des Worktrees (`/home/uli/projects/nihongo/.claude/worktrees/reader-erleben`).
- Widget-Keys neu (wörtlich): `story-title-card`, `story-end-card`, `story-end-done`, `story-thought-box`, `story-reaction-caption`, `story-bubble-hit-<i>` (i = Bubble-Index im Panel).

---

### Task 1: Schema — `Episode.intro/outro`, `StoryInteraction.reactionAsset/reactionCaption`

**Files:**
- Modify: `lib/features/story/episode.dart` (Episode: Felder nach `pages` Z.227, Konstruktor Z.230–239, fromJson Z.241–253; StoryInteraction: Felder nach `optional` Z.146, Konstruktor Z.148–152, fromJson Z.154–158)
- Test: `test/features/story/episode_test.dart` (Tests anhängen)

**Interfaces:**
- Consumes: bestehende `Episode.fromJson` / `StoryInteraction.fromJson`.
- Produces: `Episode.intro` (`String?`), `Episode.outro` (`String?`), `StoryInteraction.reactionAsset` (`String?`), `StoryInteraction.reactionCaption` (`String?`) — alle optional, Default `null`; fromJson-Schlüssel gleichnamig.

- [ ] **Step 1: Failing Tests schreiben** — an `test/features/story/episode_test.dart` anhängen:

```dart
  test('Episode traegt optionale deutsche intro/outro-Texte', () {
    final withTexts = Episode.fromJson({
      'id': 'ep_x', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {'items': [], 'maxNew': 0},
      'pages': [],
      'intro': 'Eine junge Frau steigt aus dem Zug.',
      'outro': 'Der Name kommt ihr bekannt vor …',
    });
    expect(withTexts.intro, 'Eine junge Frau steigt aus dem Zug.');
    expect(withTexts.outro, 'Der Name kommt ihr bekannt vor …');

    final without = Episode.fromJson({
      'id': 'ep_y', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {'items': [], 'maxNew': 0},
      'pages': [],
    });
    expect(without.intro, isNull);
    expect(without.outro, isNull);
  });

  test('StoryInteraction traegt optionales Reaktions-Bild + Erzaehlzeile', () {
    final withReaction = StoryInteraction.fromJson({
      'type': 'speak', 'diegetic': true,
      'reactionAsset': 'assets/story/p07_reaction.jpg',
      'reactionCaption': 'Sie hat dich gehört.',
    });
    expect(withReaction.reactionAsset, 'assets/story/p07_reaction.jpg');
    expect(withReaction.reactionCaption, 'Sie hat dich gehört.');

    final without = StoryInteraction.fromJson({'type': 'trace'});
    expect(without.reactionAsset, isNull);
    expect(without.reactionCaption, isNull);
  });
```

Hinweis: Falls `episode_test.dart` andere Pflichtfelder im Episode-JSON erwartet (z. B. `budget`-Form), das Muster eines bestehenden `Episode.fromJson`-Tests in der Datei übernehmen — die Assertions oben bleiben unverändert.

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/episode_test.dart` · Expected: FAIL (kein Getter `intro`).
- [ ] **Step 3: Implementieren** — in `episode.dart`:

```dart
  // In class Episode, nach `final List<StoryPage> pages;`:
  /// Deutsche Anmoderation der Titelkarte (Spec Reader-Erleben §2.1).
  final String? intro;
  /// Deutscher Erzählhaken der Endkarte (§2.6).
  final String? outro;
  // Konstruktor: `this.intro, this.outro` als optionale benannte Parameter.
  // fromJson: intro: j['intro'] as String?, outro: j['outro'] as String?,
```

```dart
  // In class StoryInteraction, nach `final bool optional;`:
  /// Panel-Variante, die nach Erfolg dieser Interaktion einblendet (§2.4).
  final String? reactionAsset;
  /// Deutsche Erzählzeile zur Reaktion.
  final String? reactionCaption;
  // Konstruktor: this.reactionAsset, this.reactionCaption (optional).
  // fromJson: reactionAsset: j['reactionAsset'] as String?,
  //           reactionCaption: j['reactionCaption'] as String?,
```

- [ ] **Step 4: Pass zeigen** — Run: `flutter test test/features/story/episode_test.dart` · Expected: PASS.
- [ ] **Step 5: Commit** — `git add lib/features/story/episode.dart test/features/story/episode_test.dart && git commit -m "feat(story): Episodenschema — intro/outro + Reaktions-Bild/-Zeile (Reader-Erleben)"`

---

### Task 2: `StoryProgressStore` — Abschluss merken

**Files:**
- Modify: `lib/features/story/story_progress_store.dart`
- Test: `test/features/story/story_progress_store_test.dart` (anhängen)

**Interfaces:**
- Produces: `Future<void> markCompleted(String episodeId)`, `Future<bool> isCompleted(String episodeId)` — SharedPreferences-Key `story_completed_<episodeId>` (bool).

- [ ] **Step 1: Failing Test** — anhängen (Setup-Muster der Datei übernehmen: `SharedPreferences.setMockInitialValues({})` + `StoryProgressStore(await SharedPreferences.getInstance())`):

```dart
  test('markCompleted/isCompleted merken den Folgen-Abschluss pro Episode', () async {
    SharedPreferences.setMockInitialValues({});
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    expect(await store.isCompleted('ep_a'), isFalse);
    await store.markCompleted('ep_a');
    expect(await store.isCompleted('ep_a'), isTrue);
    expect(await store.isCompleted('ep_b'), isFalse);
  });
```

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/story_progress_store_test.dart` · Expected: FAIL (Methode fehlt).
- [ ] **Step 3: Implementieren** — in der Klasse ergänzen:

```dart
  static const _completedPrefix = 'story_completed_';

  /// Merkt, dass die Folge einmal zu Ende gelesen wurde. Eine
  /// abgeschlossene Folge startet beim nächsten Öffnen bei der
  /// Titelkarte (Spec Reader-Erleben §2.7).
  Future<void> markCompleted(String episodeId) async =>
      await _prefs.setBool('$_completedPrefix$episodeId', true);

  Future<bool> isCompleted(String episodeId) async =>
      _prefs.getBool('$_completedPrefix$episodeId') ?? false;
```

- [ ] **Step 4: Pass zeigen** — Run wie Step 2 · Expected: PASS.
- [ ] **Step 5: Commit** — `git add lib/features/story/story_progress_store.dart test/features/story/story_progress_store_test.dart && git commit -m "feat(story): Folgen-Abschluss im ProgressStore (Reader-Erleben)"`

---

### Task 3: Sheets deutsch + Auto-Schließen bei Erfolg + Trace-Ghost-Vorlage

**Files:**
- Modify: `lib/features/story/diegetic_speak_sheet.dart` (Feedback-Strings Z.41/47; Aufgaben-Label; Auto-Close)
- Modify: `lib/features/story/diegetic_trace_sheet.dart` (Strings Z.59/65/78; Ghost-Glyph im Canvas; Auto-Close)
- Test: `test/features/story/diegetic_speak_sheet_test.dart`, `test/features/story/diegetic_trace_sheet_test.dart` (Erwartungen umstellen + neue Fälle)

**Interfaces:**
- Consumes: bestehende Widget-APIs (unverändert: `targetText, evaluator, speak, onSuccess, onSkip, threshold`).
- Produces: Verhalten „bei Erfolg feuert `onSuccess` sofort, und 900 ms später `onSkip`" — Task 5/6-Tests verlassen sich darauf. Konstante `kDiegeticSuccessAutoClose = Duration(milliseconds: 900)` als top-level in `diegetic_speak_sheet.dart`, vom Trace-Sheet importiert/wiederverwendet.

- [ ] **Step 1: Failing Tests** — in beiden Sheet-Test-Dateien:
  1. Alle Erwartungen auf die japanischen Strings (`よくできました ✓`, `もう一度どうぞ`, `なぞって:`) auf die deutschen Strings aus den Global Constraints umstellen (`Gut! ✓`, `Fast — hör noch einmal und versuch's gleich nochmal.`, Label-Text s. Step 3).
  2. Neuer Fall Speak (analog Trace mit `diegetic-trace-done` nach Strichen auf `diegetic-trace-canvas`):

```dart
  testWidgets('bei Erfolg schliesst sich das Sheet nach kurzer Pause von selbst',
      (tester) async {
    var skipped = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DiegeticSpeakSheet(
          targetText: 'すみません',
          evaluator: _FakeSpeakEvaluator(0.9),
          speak: (_) async {},
          onSuccess: () {},
          onSkip: () => skipped++,
        ),
      ),
    ));
    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pump();
    expect(find.text('Gut! ✓'), findsOneWidget);
    expect(skipped, 0); // noch offen — das ✓ soll ankommen
    await tester.pump(const Duration(milliseconds: 950));
    expect(skipped, 1); // Auto-Close hat onSkip gerufen
  });
```

  (Fake-Evaluatoren aus der jeweiligen Test-Datei wiederverwenden; fehlen sie dort, aus `story_reader_screen_test.dart:206–219` kopieren.)
  3. Neuer Fall Trace-Ghost: nach dem Pumpen des Trace-Sheets `expect(find.byKey(const ValueKey('diegetic-trace-ghost')), findsOneWidget);` und der Ghost zeigt den Zieltext: `expect(find.descendant(of: find.byKey(const ValueKey('diegetic-trace-ghost')), matching: find.text('あめ')), findsOneWidget);`

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/diegetic_speak_sheet_test.dart test/features/story/diegetic_trace_sheet_test.dart` · Expected: FAIL (deutsche Strings/Ghost/Auto-Close fehlen).
- [ ] **Step 3: Implementieren**

`diegetic_speak_sheet.dart`:

```dart
/// Wie lange das Erfolgs-✓ sichtbar bleibt, bevor sich ein diegetisches
/// Sheet von selbst schliesst und das Panel reagieren kann (§2.4).
const kDiegeticSuccessAutoClose = Duration(milliseconds: 900);
```

`_attempt` neu:

```dart
  Future<void> _attempt() async {
    final score = await widget.evaluator.evaluate(widget.targetText);
    if (!mounted) return;
    if (score >= widget.threshold) {
      setState(() => _feedback = 'Gut! ✓');
      if (!_succeeded) {
        _succeeded = true;
        widget.onSuccess();
        Future.delayed(kDiegeticSuccessAutoClose, () {
          if (mounted) widget.onSkip();
        });
      }
    } else {
      setState(() =>
          _feedback = "Fast — hör noch einmal und versuch's gleich nochmal.");
    }
  }
```

Im `build` über dem Zieltext ein deutsches Aufgaben-Label ergänzen:

```dart
          const Text('Hör zu und sprich nach:'),
          const SizedBox(height: 8),
          Text(widget.targetText, style: const TextStyle(fontSize: 24)),
```

`diegetic_trace_sheet.dart`: `_submit` analog (`'Gut! ✓'` / Misserfolgstext / `_succeeded`-Block mit demselben `Future.delayed(kDiegeticSuccessAutoClose, ...)`; Import `import 'diegetic_speak_sheet.dart' show kDiegeticSuccessAutoClose;`). Kopfzeile Z.78 ersetzen:

```dart
          const Text('Zeichne das Zeichen nach:'),
          const SizedBox(height: 4),
          Text(widget.targetText, style: const TextStyle(fontSize: 22)),
```

Ghost-Vorlage: den `CustomPaint`-Container in einen `Stack` packen —

```dart
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: FittedBox(
                      key: const ValueKey('diegetic-trace-ghost'),
                      fit: BoxFit.contain,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.targetText,
                          style: const TextStyle(color: Color(0xFFDDDDDD)),
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _InkPainter(_strokes, _current),
                    size: Size.infinite,
                  ),
                ],
              ),
```

- [ ] **Step 4: Pass zeigen** — Run wie Step 2, danach `flutter test test/features/story/` (Reader-Tests, die Erfolgspfade pumpen, können am Auto-Close hängen: jede betroffene Stelle mit `await tester.pump(kDiegeticSuccessAutoClose)` bzw. `pumpAndSettle` nachziehen — betroffene Dateien laut Suchlauf `grep -rl "よくできました\|もう一度\|なぞって" test/`).
- [ ] **Step 5: Commit** — `git add lib/features/story/diegetic_*.dart test/features/story/ && git commit -m "feat(story): Sheets deutsch, Erfolg schliesst sanft, Trace-Ghost-Vorlage (Reader-Erleben)"`

---

### Task 4: Panel-Stack — Tippflächen im Bild, Erzählkästen, Wörterbuch-Extraktion

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (build Z.234–277, `_maybeShowDictionary` Z.122–142, `_BubbleContent`-Nutzung Z.263–270)
- Test: `test/features/story/story_reader_screen_test.dart` (neue Fälle anhängen)

**Interfaces:**
- Consumes: `StoryBubble.hitArea` (`StoryPolygon`, leer wenn ungesetzt — Kriterium `bubble.hitArea.points.isEmpty`), `widget.speak`, `DictionarySheet`.
- Produces: private Methode `void _openDictionary()` (zeigt das bestehende ModalSheet; von `_maybeShowDictionary` UND vom hitArea-Tap genutzt); Overlay-Keys `story-bubble-hit-<i>`, `story-thought-box`. Task 6 baut im selben Stack weiter (Bild via `_effectiveAssetFor(panel)` — hier noch NICHT einführen, Task 6 tut es).

- [ ] **Step 1: Failing Tests** — anhängen an `story_reader_screen_test.dart` (Helfer `_freshStore`/`_noopSpeak` der Datei nutzen):

```dart
Episode _episodeWithHitAreaBubble() => Episode.fromJson({
      'id': 'ep_hit', 'seasonId': 's', 'orderIndex': 1, 'title': 'Hit',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'refType': 'lexeme', 'id': 'lex_ja_sumimasen'},
        ],
        'maxNew': 1,
      },
      'pages': [
        {
          'index': 0,
          'panels': [
            {
              'index': 0,
              'asset': 'assets/comic/placeholder_page.png',
              'bubbles': [
                {
                  'speakerId': 'protagonist',
                  'text': 'すみません',
                  'hitArea': [
                    {'x': 0.1, 'y': 0.1},
                    {'x': 0.6, 'y': 0.1},
                    {'x': 0.6, 'y': 0.3},
                    {'x': 0.1, 'y': 0.3},
                  ],
                  'tokens': [
                    {'surface': 'すみません', 'itemId': 'lex_ja_sumimasen'},
                  ],
                },
              ],
              'thoughts': [
                {'text': 'Ich hätte anrufen sollen.'},
              ],
              'interactions': [],
            },
          ],
        },
      ],
    });

  testWidgets('eine Bubble mit hitArea wird Tippflaeche im Bild: '
      'kein Dialogtext unter dem Panel, Tap spricht und oeffnet das Woerterbuch',
      (tester) async {
    final spoken = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithHitAreaBubble(),
        progressStore: await _freshStore(),
        speak: (t) async => spoken.add(t),
        dictionaryEntries: const [
          DictionaryEntry(id: 'lex_ja_sumimasen', headword: 'すみません',
              meaning: 'Entschuldigung'),
        ],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsOneWidget);
    // Kein Fallback-Text unter dem Bild:
    expect(find.text('すみません'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-bubble-hit-0')));
    await tester.pumpAndSettle();
    expect(spoken, ['すみません']);
    expect(find.byKey(const ValueKey('dictionary-sheet')), findsOneWidget);
  });

  testWidgets('thoughts erscheinen als Erzaehlkasten-Overlay', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _episodeWithHitAreaBubble(),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    final box = find.byKey(const ValueKey('story-thought-box'));
    expect(box, findsOneWidget);
    expect(find.descendant(of: box,
        matching: find.text('Ich hätte anrufen sollen.')), findsOneWidget);
  });

  testWidgets('eine Bubble OHNE hitArea rendert wie bisher unter dem Bild '
      '(Uebergangs-Fallback)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: _twoPanelEpisode(),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-bubble-hit-0')), findsNothing);
  });
```

  (Hinweis: `_twoPanelEpisode()` muss dafür mindestens eine Bubble ohne hitArea auf Panel 0 haben — hat es laut Z.14–55; sonst den Dialog-Text-Finder der Datei übernehmen. Import von `DictionaryEntry`: `package:nihongo_app/features/story/dictionary.dart`, falls nicht schon importiert. Falls die Titelkarte aus Task 5 schon existiert, vor den Assertions einmal `await tester.tap(find.byKey(const ValueKey('story-title-card'))); await tester.pumpAndSettle();` — Tasks 4 und 5 sind unabhängig implementierbar, wer später kommt, zieht die Tests des anderen nach.)

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/story_reader_screen_test.dart` · Expected: die 3 neuen FAIL, Bestand grün.
- [ ] **Step 3: Implementieren** in `story_reader_screen.dart`:

  1. `_maybeShowDictionary` (Z.122–142): den `showModalBottomSheet`-Block in eine Methode ziehen —

```dart
  void _openDictionary() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        key: const ValueKey('dictionary-sheet'),
        height: MediaQuery.of(context).size.height * 0.7,
        child: DictionarySheet(
          entries: widget.dictionaryEntries,
          knownIds: widget.knownIds,
        ),
      ),
    );
  }
```

  (Exakte bestehende Parameter aus Z.129–140 übernehmen — obiger Block ist die Zielform; weicht der Bestand ab, den Bestand 1:1 in die Methode verschieben.) `_maybeShowDictionary` ruft im PostFrameCallback nur noch `_openDictionary()`.

  2. Bounding-Box-Helfer (top-level in der Datei):

```dart
Rect _bboxOf(StoryPolygon polygon) {
  var minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
  for (final p in polygon.points) {
    if (p.x < minX) minX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.x > maxX) maxX = p.x;
    if (p.y > maxY) maxY = p.y;
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
```

  3. Panel-Region (Z.241–249) ersetzen durch Stack mit LayoutBuilder:

```dart
              AspectRatio(
                aspectRatio: _panelAspectRatio,
                child: LayoutBuilder(builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final h = constraints.maxHeight;
                  return Stack(fit: StackFit.expand, children: [
                    Image.asset(
                      panel.asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFEDEDED)),
                    ),
                    if (panel.thoughts.isNotEmpty)
                      Positioned(
                        top: 8, left: 8, right: 8,
                        child: Container(
                          key: const ValueKey('story-thought-box'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFF8E7),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final thought in panel.thoughts)
                                Text(thought.text,
                                    style: const TextStyle(
                                        fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),
                    for (var i = 0; i < panel.bubbles.length; i++)
                      if (panel.bubbles[i].hitArea.points.isNotEmpty)
                        Positioned(
                          left: _bboxOf(panel.bubbles[i].hitArea).left * w,
                          top: _bboxOf(panel.bubbles[i].hitArea).top * h,
                          width: _bboxOf(panel.bubbles[i].hitArea).width * w,
                          height: _bboxOf(panel.bubbles[i].hitArea).height * h,
                          child: GestureDetector(
                            key: ValueKey('story-bubble-hit-$i'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              widget.speak(panel.bubbles[i].text);
                              _openDictionary();
                            },
                          ),
                        ),
                  ]);
                }),
              ),
```

  4. Text-Spalte unter dem Bild (Z.250–273): thoughts-Schleife ERSATZLOS streichen (jetzt Overlay); bubbles-Schleife filtern: `for (final bubble in panel.bubbles) if (bubble.hitArea.points.isEmpty) ...` (Fallback bleibt).

- [ ] **Step 4: Pass zeigen** — Run: `flutter test test/features/story/` · Expected: PASS (bestehende thought-Tests finden den Text im Overlay weiter; falls ein Test das ALTE Layout prüft — z. B. Reihenfolge im Column — die Erwartung auf das Overlay umziehen und im Commit begründen).
- [ ] **Step 5: Commit** — `git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart && git commit -m "feat(story): Tippflaechen im Bild + Erzaehlkaesten-Overlay + Woerterbuch-Extraktion (Reader-Erleben)"`

---

### Task 5: Titelkarte, Endkarte, Wiederbetreten-Fix

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (`_restorePosition` Z.84–99, `_advance` Z.101–105, `_maybeFireCompletion` Z.209–213, `build` Z.215–233)
- Test: `test/features/story/story_reader_screen_test.dart` (neue Fälle + Bestand nachziehen)

**Interfaces:**
- Consumes: `Episode.intro/outro` (Task 1), `StoryProgressStore.markCompleted/isCompleted` (Task 2).
- Produces: Phasen-Verhalten, auf das sich Task 7/8 und alle Durchlese-Tests stützen: **Erstöffnung und abgeschlossene Folge starten auf der Titelkarte** (`story-title-card`, Tap darauf → Panel 0); mitten-drin-Resume (gespeicherte Position > 0, nicht abgeschlossen) geht direkt ins Lesen; **Tap auf dem letzten Panel → Endkarte** (`story-end-card` mit `story-end-done`-Button, der `Navigator.pop` ruft); `onEpisodeComplete` + `progressStore.markCompleted` feuern unverändert beim ERREICHEN des letzten Panels.

- [ ] **Step 1: Failing Tests** — anhängen:

```dart
  testWidgets('Erstoeffnung zeigt die Titelkarte mit Titel und Anmoderation; '
      'Tap startet das Lesen', (tester) async {
    final episode = Episode.fromJson({
      ...pilot01RegenJson,
      'intro': 'Eine junge Frau steigt allein aus dem Zug.',
    });
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-title-card')), findsOneWidget);
    expect(find.text('Folge 1 — Regen'), findsOneWidget);
    expect(find.text('Eine junge Frau steigt allein aus dem Zug.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('story-reader-panel')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });
```

  (Der Titel-String muss dem `title`-Feld von `pilot01RegenJson` entsprechen — vor dem Schreiben in `lib/features/story/episodes/folge_01_regen.dart` nachsehen und exakt übernehmen.)

```dart
  testWidgets('Tap auf dem letzten Panel oeffnet die Endkarte; '
      'ihr Knopf verlaesst den Reader', (tester) async {
    final episode = Episode.fromJson({
      ..._twoPanelEpisodeJson(), // s. Hinweis unten
      'outro': 'Der Name kommt ihr bekannt vor …',
    });
    final store = await _freshStore();
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel'))); // → Panel 2 (letztes)
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel'))); // → Endkarte
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-end-card')), findsOneWidget);
    expect(find.text('Der Name kommt ihr bekannt vor …'), findsOneWidget);
    expect(await store.isCompleted(episode.id), isTrue);
  });

  testWidgets('eine abgeschlossene Folge startet beim Wiederoeffnen auf der '
      'Titelkarte — nicht auf dem letzten Panel mit offenem Sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = StoryProgressStore(prefs);
    final episode = Episode.fromJson(pilot01RegenJson);
    await store.savePosition(episode.id, 23);
    await store.markCompleted(episode.id);

    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: episode,
        progressStore: store,
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        traceEvaluator: _FakeTraceEvaluator(true),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-title-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('diegetic-trace-sheet')), findsNothing);
  });
```

  Hinweis `_twoPanelEpisodeJson()`: Die bestehende `_twoPanelEpisode()` gibt ein `Episode`-Objekt zurück; für den outro-Spread wird die JSON-Map gebraucht — die Map aus `_twoPanelEpisode()` (Z.14–55) in einen eigenen Helfer `Map<String, dynamic> _twoPanelEpisodeJson()` heben und `_twoPanelEpisode()` darauf umstellen (`Episode.fromJson(_twoPanelEpisodeJson())`).

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/story_reader_screen_test.dart` · Expected: neue Fälle FAIL.
- [ ] **Step 3: Implementieren** in `story_reader_screen.dart`:

```dart
enum _ReaderPhase { title, reading, end }
```

  State: `_ReaderPhase _phase = _ReaderPhase.title;` — `_restorePosition` neu:

```dart
  Future<void> _restorePosition() async {
    final done = await widget.progressStore.isCompleted(widget.episode.id);
    final saved =
        done ? null : await widget.progressStore.lastPosition(widget.episode.id);
    if (!mounted) return;
    final clamped = saved == null ? 0 : saved.clamp(0, _panels.length - 1);
    final resumeMidway = !done && saved != null && clamped > 0;
    setState(() {
      _position = clamped;
      _phase = resumeMidway ? _ReaderPhase.reading : _ReaderPhase.title;
    });
    if (resumeMidway) {
      _maybeShowDictionary(clamped);
      _maybeShowSpeak(clamped);
      _maybeShowTrace(clamped);
      _maybeFireCompletion(clamped);
    }
  }

  void _beginReading() {
    setState(() => _phase = _ReaderPhase.reading);
    _maybeShowDictionary(_position ?? 0);
    _maybeShowSpeak(_position ?? 0);
    _maybeShowTrace(_position ?? 0);
    _maybeFireCompletion(_position ?? 0);
  }
```

  `_advance`: der Block „letztes Panel → return" wird zu `setState(() => _phase = _ReaderPhase.end); return;`. `_maybeFireCompletion` ergänzt nach `_completionFired = true;`: `widget.progressStore.markCompleted(widget.episode.id);` (nicht awaited — bewusst; `SharedPreferences.setBool` wirft praktisch nicht, und der Reader darf am Folgen-Ende nicht auf Disk warten).

  `build`: vor dem bisherigen Scaffold —

```dart
    if (_position == null) { /* bestehender Ladezweig unverändert */ }
    if (_phase == _ReaderPhase.title) {
      return Scaffold(
        body: GestureDetector(
          key: const ValueKey('story-title-card'),
          behavior: HitTestBehavior.opaque,
          onTap: _beginReading,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.episode.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  if (widget.episode.intro != null) ...[
                    const SizedBox(height: 16),
                    Text(widget.episode.intro!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 32),
                  Text('Tippe, um zu beginnen',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_phase == _ReaderPhase.end) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              key: const ValueKey('story-end-card'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ende der Folge',
                    style: Theme.of(context).textTheme.titleLarge),
                if (widget.episode.outro != null) ...[
                  const SizedBox(height: 16),
                  Text(widget.episode.outro!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 32),
                FilledButton(
                  key: const ValueKey('story-end-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zurück zum Lesen'),
                ),
              ],
            ),
          ),
        ),
      );
    }
```

- [ ] **Step 4: Bestand nachziehen + Pass zeigen** — Alle bestehenden Tests, die direkt aufs erste Panel erwarten, brauchen jetzt einen Titelkarten-Tap; der „nicht über das letzte Panel hinaus"-Test erwartet jetzt die Endkarte. Betroffene systematisch finden: `grep -n "story-reader-panel" test/features/story/*.dart test/features/mining_slice/*.dart` — in jeder Datei nach dem ersten `pumpAndSettle` einfügen: `await tester.tap(find.byKey(const ValueKey('story-title-card'))); await tester.pumpAndSettle();` (auch `story_route_test.dart`, `story_reader_srs_handoff_test.dart`, `story_reader_diegetic_*_test.dart`, `reading_tab_test.dart`-Story-Fall). Resume-Tests (gespeicherte Position > 0) bleiben ohne Titelkarte — das prüft der resumeMidway-Pfad. Run: `flutter test test/features/story/ test/features/mining_slice/` · Expected: PASS.
- [ ] **Step 5: Commit** — `git add lib/features/story/story_reader_screen.dart test/ && git commit -m "feat(story): Titelkarte, Endkarte mit Haken, Wiederbetreten startet vorn (Reader-Erleben)"`

---

### Task 6: Die Geschichte reagiert — Reaktions-Bild + Erzählzeile nach Erfolg

**Files:**
- Modify: `lib/features/story/story_reader_screen.dart` (Stack aus Task 4, `_maybeShowSpeak` Z.144–172, `_maybeShowTrace` Z.174–207)
- Test: `test/features/story/story_reader_screen_test.dart`

**Interfaces:**
- Consumes: `StoryInteraction.reactionAsset/reactionCaption` (Task 1), Auto-Close-Verhalten der Sheets (Task 3).
- Produces: Nach Erfolg einer diegetischen speak/trace-Interaktion zeigt das Panel `reactionAsset` (weiche Überblendung) und `reactionCaption` als Kasten am unteren Panelrand (`story-reaction-caption`). Ohne Erfolg/bei Skip: Original unverändert.

- [ ] **Step 1: Failing Test:**

```dart
  testWidgets('nach erfolgreichem Sprechen reagiert das Panel: '
      'Reaktionsbild + Erzaehlzeile', (tester) async {
    final json = _episodeWithDiegeticSpeakOnSecondPanelJson();
    // Reaktion an die speak-Interaktion des zweiten Panels haengen:
    final panel = ((json['pages'] as List).first
        as Map<String, dynamic>)['panels'][1] as Map<String, dynamic>;
    (panel['interactions'] as List)[0] = {
      'type': 'speak', 'diegetic': true,
      'reactionAsset': 'assets/comic/placeholder_page.png',
      'reactionCaption': 'Sie hat dich gehört.',
    };
    await tester.pumpWidget(MaterialApp(
      home: StoryReaderScreen(
        episode: Episode.fromJson(json),
        progressStore: await _freshStore(),
        speak: _noopSpeak,
        dictionaryEntries: const [],
        knownIds: const {},
        speakEvaluator: _FakeSpeakEvaluator(0.9),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-title-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('diegetic-speak-mic')));
    await tester.pumpAndSettle(); // Erfolg + Auto-Close (900ms) + Crossfade
    expect(find.byKey(const ValueKey('diegetic-speak-sheet')), findsNothing);
    expect(find.byKey(const ValueKey('story-reaction-caption')), findsOneWidget);
    expect(find.text('Sie hat dich gehört.'), findsOneWidget);
  });
```

  (Analog Task 5: `_episodeWithDiegeticSpeakOnSecondPanel()` Z.102–147 in einen `...Json()`-Map-Helfer heben. Ein zweiter, kleiner Fall: Skip statt Mic → `story-reaction-caption` bleibt `findsNothing`.)

- [ ] **Step 2: Fail zeigen** — Run: `flutter test test/features/story/story_reader_screen_test.dart` · Expected: FAIL.
- [ ] **Step 3: Implementieren** in `story_reader_screen.dart`:

  State: `final Set<int> _reactedPositions = {};` — Helfer:

```dart
  StoryInteraction? _diegeticInteractionOf(StoryPanel panel) {
    for (final it in panel.interactions) {
      if (it.diegetic &&
          (it.type == InteractionType.speak ||
              it.type == InteractionType.trace)) {
        return it;
      }
    }
    return null;
  }

  void _markReacted(int position) {
    if (!mounted) return;
    setState(() => _reactedPositions.add(position));
  }
```

  In `_maybeShowSpeak`: den `onSuccess`-Callback des Sheets erweitern — vor dem bestehenden `widget.onDiegeticSpeakSuccess?.call(itemIds)` ein `_markReacted(position);` (position ist der Methoden-Parameter). Analog in `_maybeShowTrace`.

  Im Stack aus Task 4: das nackte `Image.asset` ersetzen durch

```dart
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Image.asset(
                        _effectiveAssetFor(panel),
                        key: ValueKey(_effectiveAssetFor(panel)),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: const Color(0xFFEDEDED)),
                      ),
                    ),
```

  mit

```dart
  String _effectiveAssetFor(StoryPanel panel) {
    final reacted = _reactedPositions.contains(_position);
    final reaction = _diegeticInteractionOf(panel)?.reactionAsset;
    return (reacted && reaction != null) ? reaction : panel.asset;
  }
```

  und unter den thought-Kasten (im Stack) den Reaktions-Kasten:

```dart
                    if (_reactedPositions.contains(_position) &&
                        _diegeticInteractionOf(panel)?.reactionCaption != null)
                      Positioned(
                        bottom: 8, left: 8, right: 8,
                        child: Container(
                          key: const ValueKey('story-reaction-caption'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xF2FFF8E7),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: Text(
                            _diegeticInteractionOf(panel)!.reactionCaption!,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
```

- [ ] **Step 4: Pass zeigen** — Run: `flutter test test/features/story/` · Expected: PASS.
- [ ] **Step 5: Commit** — `git add lib/features/story/story_reader_screen.dart test/features/story/story_reader_screen_test.dart && git commit -m "feat(story): das Panel reagiert auf Erfolg — Reaktionsbild + Erzaehlzeile (Reader-Erleben)"`

---

### Task 7: Prototyp-Content — Lettering-Skript + Folge-01-Daten

**Files:**
- Create: `tool/letter_folge01.py` (erstes Python-Skript im Repo, bewusst: reine Prototyp-Hilfe)
- Modify: `lib/features/story/episodes/folge_01_regen.dart` (hitAreas, intro/outro, Reaktionen)
- Create (generiert): `assets/story/p07_reaction.jpg`, `assets/story/p22_reaction.jpg`, `assets/story/p24_reaction.jpg` + geletterte `p07/p08/p11/p17/p18/p19/p20/p21/p22/p23/p24.jpg`
- Test: `test/features/story/folge_01_panel_assets_test.dart` (erweitern), `test/features/story/folge_01_regen_test.dart` (erweitern)

**Interfaces:**
- Consumes: Schema-Felder (Task 1). Quell-Renders: `/home/uli/.claude/jobs/df1342e0/tmp/final/P01.png … P24.png` (NICHT die schon verkleinerten JPEGs erneut beschriften — immer von den Originalen neu erzeugen, damit das Skript idempotent ist).
- Produces: Folge 01 mit befüllten hitAreas/intro/outro/Reaktionen — die Daten, mit denen Uli das Erlebnis testet.

**Blasen-Slots (normierte Rechtecke `x, y, w, h`; identisch im Skript UND als hitArea in der Fixture — Werte sind die EINE Quelle der Wahrheit, beide Stellen übernehmen sie wörtlich):**

| Panel | Bubble | Text | Slot |
|---|---|---|---|
| P07 | 0 | すみません | 0.52, 0.05, 0.42, 0.14 |
| P08 | 0 | はい？ | 0.06, 0.05, 0.36, 0.13 |
| P11 | 0 | あめ | 0.32, 0.36, 0.30, 0.14 |
| P17 | 0 | これ、こわれた | 0.06, 0.05, 0.46, 0.14 |
| P18 | 0 | これ… こわれた…？ | 0.48, 0.05, 0.46, 0.14 |
| P19 | 0 | はい | 0.06, 0.05, 0.30, 0.12 |
| P20 | 0 | ありがとう | 0.52, 0.05, 0.42, 0.13 |
| P21 | 0 | はい。かさ。どうぞ | 0.06, 0.05, 0.50, 0.14 |
| P22 | 0 | ありがとう… すみません | 0.44, 0.05, 0.50, 0.14 |
| P23 | 0 | かさ… | 0.56, 0.05, 0.38, 0.12 |
| P24 | 0 | あめ | 0.30, 0.34, 0.32, 0.14 |

P24-Bubble 1 (inerte Randnotiz, `tokens: []`) bekommt KEIN Lettering und KEINE hitArea → bleibt Fallback-Text unter dem Bild (INV-7-Sichtbarkeit bleibt erhalten).

- [ ] **Step 1: Skript schreiben** — `tool/letter_folge01.py` (komplett):

```python
#!/usr/bin/env python3
"""Prototyp-Lettering fuer Folge 01 (Spec Reader-Erleben §4).

Komponiert Sprechblasen + japanischen Text auf die Original-Renders und
erzeugt getoente Reaktions-Varianten. Haesslich ist erlaubt — beurteilt
wird das Erlebnis, nicht das Artwork. Idempotent: liest immer die
Originale aus SRC, schreibt nach DST.
"""
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

SRC = '/home/uli/.claude/jobs/df1342e0/tmp/final'
DST = 'assets/story'
FONT = '/usr/share/fonts/truetype/droid/DroidSansFallbackFull.ttf'
WIDTH = 1080

# Panel -> Liste von (text, (x, y, w, h)) — MUSS mit den hitAreas in
# lib/features/story/episodes/folge_01_regen.dart uebereinstimmen.
BUBBLES = {
    7:  [('すみません', (0.52, 0.05, 0.42, 0.14))],
    8:  [('はい？', (0.06, 0.05, 0.36, 0.13))],
    11: [('あめ', (0.32, 0.36, 0.30, 0.14))],
    17: [('これ、こわれた', (0.06, 0.05, 0.46, 0.14))],
    18: [('これ… こわれた…？', (0.48, 0.05, 0.46, 0.14))],
    19: [('はい', (0.06, 0.05, 0.30, 0.12))],
    20: [('ありがとう', (0.52, 0.05, 0.42, 0.13))],
    21: [('はい。かさ。どうぞ', (0.06, 0.05, 0.50, 0.14))],
    22: [('ありがとう… すみません', (0.44, 0.05, 0.50, 0.14))],
    23: [('かさ…', (0.56, 0.05, 0.38, 0.12))],
    24: [('あめ', (0.30, 0.34, 0.32, 0.14))],
}
REACTIONS = [7, 22, 24]


def load(n):
    img = Image.open(f'{SRC}/P{n:02d}.png').convert('RGB')
    w, h = img.size
    return img.resize((WIDTH, int(h * WIDTH / w)), Image.LANCZOS)


def fit_font(draw, text, box_w, box_h):
    size = int(box_h * 0.55)
    while size > 10:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        if r - l <= box_w * 0.86 and b - t <= box_h * 0.7:
            return font
        size -= 2
    return ImageFont.truetype(FONT, 10)


def letter(img, bubbles):
    draw = ImageDraw.Draw(img)
    W, H = img.size
    for text, (x, y, w, h) in bubbles:
        box = (x * W, y * H, (x + w) * W, (y + h) * H)
        draw.ellipse(box, fill='white', outline='black', width=4)
        font = fit_font(draw, text, (box[2] - box[0]), (box[3] - box[1]))
        l, t, r, b = draw.textbbox((0, 0), text, font=font)
        cx = (box[0] + box[2]) / 2 - (r - l) / 2 - l
        cy = (box[1] + box[3]) / 2 - (b - t) / 2 - t
        draw.text((cx, cy), text, fill='black', font=font)
    return img


def main():
    for n in range(1, 25):
        img = load(n)
        if n in BUBBLES:
            img = letter(img, BUBBLES[n])
        img.save(f'{DST}/p{n:02d}.jpg', quality=85, optimize=True)
        if n in REACTIONS:
            warm = ImageEnhance.Color(
                ImageEnhance.Brightness(img).enhance(1.12)).enhance(1.25)
            warm.save(f'{DST}/p{n:02d}_reaction.jpg', quality=85,
                      optimize=True)
    print('OK: 24 Panels geletttert/kopiert, '
          f'{len(REACTIONS)} Reaktions-Varianten erzeugt.')


if __name__ == '__main__':
    main()
```

- [ ] **Step 2: Skript ausführen** — Run: `python3 tool/letter_folge01.py` · Expected: `OK: 24 Panels …`; Stichprobe: `python3 -c "from PIL import Image; print(Image.open('assets/story/p07.jpg').size)"`.
- [ ] **Step 3: Failing Tests erweitern** — `folge_01_regen_test.dart`: neuer Test

```dart
  test('Folge 01 traegt intro, outro und pro Dialog-Bubble eine hitArea', () {
    final episode = loadFolge01();
    expect(episode.intro, isNotNull);
    expect(episode.outro, isNotNull);
    for (final panel in episode.allPanels) {
      for (final bubble in panel.bubbles) {
        if (bubble.tokens.isNotEmpty) {
          expect(bubble.hitArea.points, hasLength(4),
              reason: 'Panel ${panel.index}: Dialog-Bubble ohne Tippflaeche');
        }
      }
    }
    final speakTrace = episode.allPanels
        .expand((p) => p.interactions)
        .where((i) => i.diegetic &&
            (i.type == InteractionType.speak ||
             i.type == InteractionType.trace));
    for (final it in speakTrace) {
      expect(it.reactionAsset, isNotNull);
      expect(it.reactionCaption, isNotNull);
    }
  });
```

  `folge_01_panel_assets_test.dart`: die bestehende Schleife prüft schon jedes `panel.asset`; ergänzen um die Reaktions-Assets:

```dart
    for (final it in episode.allPanels.expand((p) => p.interactions)) {
      final asset = it.reactionAsset;
      if (asset != null) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(1000));
      }
    }
```

- [ ] **Step 4: Fixture befüllen** — in `lib/features/story/episodes/folge_01_regen.dart`:
  1. `intro`/`outro` auf Episode-Ebene (nach `'era'`):

```dart
  'intro':
      'Eine junge Frau steigt allein aus dem Zug — es regnet. '
      'In ihrer Hand: ein Zettel, dessen Tinte verläuft.',
  'outro':
      'Der Schirm ist geliehen, der Regen hört nicht auf. '
      'Und der Name über dem Café … den hat sie doch schon einmal gelesen?',
```

  2. Pro Tabellen-Zeile die `hitArea` in die jeweilige Bubble (Rechteck als 4 Punkte, Beispiel P07 — Slot `0.52, 0.05, 0.42, 0.14`):

```dart
              'hitArea': [
                {'x': 0.52, 'y': 0.05},
                {'x': 0.94, 'y': 0.05},
                {'x': 0.94, 'y': 0.19},
                {'x': 0.52, 'y': 0.19},
              ],
```

  (x2 = x+w, y2 = y+h; für alle 11 Tabellen-Zeilen exakt aus der Slot-Tabelle rechnen. P24-Notiz-Bubble bekommt KEINE hitArea.)
  3. Reaktionen an die drei Interaktionen:

```dart
          // P07:
          'interactions': [
            {'type': 'speak', 'diegetic': true,
             'reactionAsset': 'assets/story/p07_reaction.jpg',
             'reactionCaption': 'Sie hat dich gehört.'},
          ],
          // P22:
            {'type': 'speak', 'diegetic': true,
             'reactionAsset': 'assets/story/p22_reaction.jpg',
             'reactionCaption': 'Der Ladenbesitzer nickt dir zu.'},
          // P24:
            {'type': 'trace', 'diegetic': true,
             'reactionAsset': 'assets/story/p24_reaction.jpg',
             'reactionCaption': 'あめ — Regen. Dein erstes geschriebenes Zeichen.'},
```

- [ ] **Step 5: Pass zeigen** — Run: `flutter test test/features/story/folge_01_regen_test.dart test/features/story/folge_01_panel_assets_test.dart` · Expected: PASS. Danach `flutter test test/features/story/` (Fallback-abhängige Tests: der Durchlese-Test dismisst Sheets über Keys, nicht über Textposition — sollte grün bleiben; Abweichungen verorten, nicht überschreiben).
- [ ] **Step 6: Commit** — `git add tool/letter_folge01.py assets/story lib/features/story/episodes/folge_01_regen.dart test/features/story/ && git commit -m "feat(story): Prototyp-Lettering + Folge-01-Erlebnisdaten — hitAreas, intro/outro, Reaktionen (Reader-Erleben)"`

---

### Task 8: Full-Suite + Analyzer

- [ ] **Step 1:** Run: `flutter analyze 2>&1 | tail -3` — keine neuen Meldungen in geänderten Dateien (`git diff origin/wire/w3-story-reader --name-only` als Referenzliste; Bestandsmeldungen in `tool/proof_*.dart` u.ä. sind nicht unsere).
- [ ] **Step 2:** Run: `flutter test 2>&1 | tail -3` — Fehlschläge sind AUSSCHLIESSLICH die 8 vorbestehenden `test/mining_packs/ja/`-Fehler. Jeder andere wird verortet und gefixt.
- [ ] **Step 3 (nur bei Fixes):** `git add -A && git commit -m "test(reader-erleben): Full-Suite-Regresse behoben"`

---

## Anschlussstellen (bewusst NICHT in diesem Plan)

- **Geräte-Deploy + Ulis Erlebnis-Test** (die eigentliche Abnahme, Spec §6) — nach Task 8 über den bestehenden Laptop-Checkout.
- **Finale Panels:** ckpt-6-Renders mit echtem Lettering ersetzen die Prototyp-JPEGs; hitAreas werden dann mit dem Klick-Werkzeug neu gesetzt (das Werkzeug selbst entsteht erst, wenn die finalen Panels kommen — fürs Prototyp-Raster genügt die Slot-Tabelle).
- **Furigana-Umschalter, Panel-Animationen** (Spec §5).
