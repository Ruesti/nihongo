# W3: Story-Reader in die App verdrahten — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Folge 01 („Regen") ist aus dem Lesen-Tab heraus in der echten App lesbar — mit echtem TTS, Wörterbuch, Sprech-/Nachzeichen-Momenten und SRS-Anschluss (Einführung am Folgen-Ende, diegetische Encounter, Bridge-Projektion unter dem korrekten BCP-47-Code).

**Architecture:** `StoryReaderScreen` ist ein reines UI-Widget ohne DB/Provider-Wissen. W3 baut (a) die Folge-01-Inhalte von Test-Fixtures zu Produktions-Quellen um, (b) eine `StoryRoute`-Wrapper-Widget nach dem `CafeRoute`-Muster (liest Provider, injiziert Singletons, mappt `locale→languageId`, sichert fire-and-forget-Callbacks ab), (c) einen immer sichtbaren Einstiegs-FAB im Lesen-Tab („Lesen ab Tag 1": der Manga-Einstieg hängt NICHT am Mining-Store), und (d) eine kleine `DiegeticEncounter`-Erweiterung, damit die Bridge-Projektion im richtigen Mining-Bucket landet.

**Tech Stack:** Flutter/Dart, Riverpod (`flutter_riverpod`), drift (LearningDb/MiningDb), `shared_preferences`, bestehende Singletons `TtsService.instance`/`SttService.instance`. Keine neuen Abhängigkeiten.

## Global Constraints

- UI-Strings deutsch (bestehender App-Standard).
- **„Grün" heißt:** Full-Suite-Fehler sind ausschließlich die 8 vorbestehenden in `test/mining_packs/ja/` (fehlende native Tokenizer-`.so`, rot auch auf main). Jeder andere Fehler ist ein Regress dieses Plans.
- `languageId` (Pack-ID) ist IMMER `'lang_${episode.locale}'` (= `'lang_ja'`); niemals `episode.locale` roh als `languageId` verwenden. Bridge-Projektionen laufen IMMER unter dem BCP-47-Code (= `episode.locale`, `'ja'`), nie unter `'lang_ja'`.
- Die drei Reader-Callbacks (`onEpisodeComplete`, `onDiegeticSpeakSuccess`, `onDiegeticTraceSuccess`) sind fire-and-forget (Reader awaited nichts) → an der Verdrahtungsstelle IMMER `.catchError(...)` anhängen.
- Panel-Bilder bleiben `assets/comic/placeholder_page.png` (bereits gebündelt). Die finalen ComfyUI-Panels sind ein späterer reiner Asset-Austausch (`asset`-Strings in `lib/features/story/episodes/folge_01_regen.dart` + neue PNGs + pubspec) — KEIN Task dieses Plans.
- Test-Kommandos aus dem Repo-Root des Worktrees ausführen.

---

### Task 1: Folge-01-Inhalte von `test/fixtures/` nach `lib/` (mit Re-Export)

Die Episode (`pilot01RegenJson`) und das Wörterbuch (`folge01DictionaryEntries`) existieren heute nur als Test-Fixtures. Produktionscode darf nicht aus `test/` importieren → Inhalte wandern nach `lib/`, die Fixtures werden Re-Exports (kein Drift, kein bestehender Test bricht).

**Files:**
- Create: `lib/features/story/episodes/folge_01_regen.dart`
- Modify: `test/fixtures/story/pilot_01_regen_fixture.dart` (wird Re-Export)
- Modify: `test/fixtures/story/folge_01_dictionary_fixture.dart` (wird Re-Export)
- Test: `test/features/story/folge_01_regen_test.dart`

**Interfaces:**
- Consumes: `Episode.fromJson(Map<String,dynamic>)` (`lib/features/story/episode.dart:241`), `void validateEpisode(Episode)` (`lib/features/story/episode_validator.dart:16`), `DictionaryEntry` (`lib/features/story/dictionary.dart`).
- Produces (für Task 3): `const Map<String, dynamic> pilot01RegenJson`, `const List<DictionaryEntry> folge01DictionaryEntries`, `Episode loadFolge01()` — alle aus `package:nihongo_app/features/story/episodes/folge_01_regen.dart`.

- [ ] **Step 1: Failing Test schreiben**

`test/features/story/folge_01_regen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';

void main() {
  test('loadFolge01 liefert die validierte Folge 01', () {
    final episode = loadFolge01();
    expect(episode.id, 'ep_ja_shotengai_01');
    expect(episode.locale, 'ja');
    expect(episode.budget.items, isNotEmpty);
    expect(episode.allPanels.length, greaterThanOrEqualTo(2));
  });

  test('das Folge-01-Woerterbuch deckt jedes Budget-Item ab', () {
    final episode = loadFolge01();
    final dictIds = folge01DictionaryEntries.map((e) => e.id).toSet();
    for (final item in episode.budget.items) {
      expect(dictIds, contains(item.id),
          reason: '${item.id} hat keinen Woerterbuch-Eintrag');
    }
  });
}
```

- [ ] **Step 2: Test laufen lassen — muss failen**

Run: `flutter test test/features/story/folge_01_regen_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package ... episodes/folge_01_regen.dart` (Datei existiert nicht).

- [ ] **Step 3: Implementieren (Inhalte verschieben)**

`lib/features/story/episodes/folge_01_regen.dart` anlegen:
1. Den **kompletten** `const Map<String, dynamic> pilot01RegenJson = { ... };`-Block wörtlich aus `test/fixtures/story/pilot_01_regen_fixture.dart` übernehmen (Name beibehalten).
2. Den **kompletten** `const List<DictionaryEntry> folge01DictionaryEntries = [ ... ];`-Block wörtlich aus `test/fixtures/story/folge_01_dictionary_fixture.dart` übernehmen; dessen Import auf `../dictionary.dart` umstellen.
3. Kopf der neuen Datei:

```dart
import '../dictionary.dart';
import '../episode.dart';
import '../episode_validator.dart';

/// Folge 01 „Regen" (ep_ja_shotengai_01) als gebündelter Produktions-
/// Inhalt. Panel-Assets zeigen noch auf den Platzhalter; der Tausch gegen
/// die finalen Panels ist ein reiner Asset-Austausch in dieser Datei.
Episode loadFolge01() {
  final episode = Episode.fromJson(pilot01RegenJson);
  validateEpisode(episode);
  return episode;
}
```

4. Beide Fixture-Dateien durch einen Re-Export ersetzen (kompletter neuer Dateiinhalt, jeweils identisch):

```dart
export 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
```

- [ ] **Step 4: Tests laufen lassen — neuer Test + alle Story-Tests grün**

Run: `flutter test test/features/story/ test/fixtures/ 2>&1 | tail -5`
Expected: PASS (alle; die Re-Exports halten `pilot01RegenJson`/`folge01DictionaryEntries` für bestehende Tests verfügbar).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/episodes/folge_01_regen.dart test/fixtures/story/ test/features/story/folge_01_regen_test.dart
git commit -m "feat(story): Folge-01-Inhalte werden Produktions-Quelle (Fixtures re-exportieren) (W3)"
```

---

### Task 2: `DiegeticEncounter` reicht den BCP-47-Code an die Bridge durch

`DiegeticEncounter.encounter` ruft `markEncountered(item)` heute OHNE `languageCode` → mit gesetzter Bridge projiziert `KnowledgeBridge.onLearnItemReviewed` unter der Pack-ID `'lang_ja'` in den Mining-Store statt unter `'ja'` (derselbe Bug, den W2 fürs Café gefixt hat, vgl. `lib/features/cafe/cafe_turn_screen.dart:105-113`).

**Files:**
- Modify: `lib/features/story/diegetic_encounter.dart`
- Test: `test/features/story/diegetic_encounter_bridge_test.dart`

**Interfaces:**
- Consumes: `LadderReview.markEncountered(LearnItem, {String? languageCode})` (`lib/core/ladder/ladder_review.dart:75`), `KnowledgeBridge(MiningDb)`, `FsrsKnowledgeSource.load(MiningDb, {required String languageCode})`, `Knowledge` (enum aus `lib/core/pipeline/sentence_scoring.dart`).
- Produces (für Task 3): `DiegeticEncounter({required LadderReview ladder, required String languageId, String? languageCode})` — neuer optionaler Parameter, Default `null` (= bisheriges Verhalten, kein bestehender Test bricht).

- [ ] **Step 1: Failing Test schreiben**

`test/features/story/diegetic_encounter_bridge_test.dart` (Muster: `test/features/cafe/cafe_bridge_test.dart`):

```dart
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/ladder_review.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart' show Knowledge;
import 'package:nihongo_app/features/story/diegetic_encounter.dart';

Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

void main() {
  test('ein diegetischer Encounter mit Bridge projiziert unter BCP-47 ja, '
      'nicht unter der Pack-ID lang_ja', () async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_dog',
        glossKey: 'dog',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_dog',
        languageId: 'lang_ja',
        conceptId: 'concept_dog',
        writtenForm: '犬',
        reading: 'いぬ'));

    final encounter = DiegeticEncounter(
      ladder: LadderReview(learning, bridge: KnowledgeBridge(mining)),
      languageId: 'lang_ja',
      languageCode: 'ja',
    );
    await encounter.encounter(RefType.lexeme, 'lex_ja_dog');

    // Rung 1 → learning, im kanonischen 'ja'-Bucket …
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.learning);
    // … und NICHTS im toten 'lang_ja'-Bucket.
    expect(await _knows(mining, '犬', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
```

- [ ] **Step 2: Test laufen lassen — muss failen**

Run: `flutter test test/features/story/diegetic_encounter_bridge_test.dart`
Expected: FAIL — zuerst Compile-Fehler `No named parameter with the name 'languageCode'`.

- [ ] **Step 3: Implementieren**

`lib/features/story/diegetic_encounter.dart` — Feld + Parameter + Durchreichung (kompletter neuer Klassen-Kern; Doc-Kommentare der Datei beibehalten):

```dart
class DiegeticEncounter {
  final LadderReview ladder;
  final String languageId;

  /// BCP-47-Code für die Bridge-Projektion ('ja'), analog zum Café
  /// (cafe_turn_screen.dart): ohne ihn fiele die Projektion auf die
  /// Pack-ID ('lang_ja') zurück und landete im falschen Mining-Bucket.
  final String? languageCode;

  const DiegeticEncounter({
    required this.ladder,
    required this.languageId,
    this.languageCode,
  });

  Future<void> encounter(RefType refType, String refId) async {
    await ladder.introduce(languageId, refType, refId,
        languageCode: languageCode);
    final id = '$languageId:${refType.name}:$refId';
    final item = await ladder.learning.getLearnItem(id);
    if (item == null || item.masteryRung != 0) return;
    await ladder.markEncountered(item, languageCode: languageCode);
  }
}
```

WICHTIG: Vor dem Überschreiben die bestehende `encounter`-Implementierung lesen (`lib/features/story/diegetic_encounter.dart:23-30`) und deren exakte Logik beibehalten — es ändert sich NUR die `languageCode`-Durchreichung an `introduce`/`markEncountered`. Falls die bestehende Methode das Item anders lädt, diese Form behalten.

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/ 2>&1 | tail -5`
Expected: PASS (neuer Test + alle bestehenden diegetic-Tests; Parameter ist optional).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/diegetic_encounter.dart test/features/story/diegetic_encounter_bridge_test.dart
git commit -m "fix(story): diegetischer Encounter projiziert unter BCP-47 'ja', nicht 'lang_ja' (W3)"
```

---

### Task 3: `StoryRoute` — der Provider-Wrapper um den Reader

Das W2-Muster (`lib/features/cafe/cafe_route.dart`): eine `ConsumerWidget`, die Provider liest und den fertigen Screen baut. Hier zusätzlich: async Deps (SharedPreferences-Store, `knownIds`-Abfrage) über einen `FutureProvider.autoDispose`.

**Files:**
- Create: `lib/features/story/story_route.dart`
- Test: `test/features/story/story_route_test.dart`

**Interfaces:**
- Consumes: `loadFolge01()`, `folge01DictionaryEntries` (Task 1); `DiegeticEncounter(..., languageCode:)` (Task 2); `StoryReaderScreen` (Konstruktor siehe unten); `learningDbProvider`/`knowledgeBridgeProvider` (`lib/app/knowledge_providers.dart`); `LearningDb.getLearnItem(String id)`; `EpisodeSrsHandoff({required ladder, required languageId})`; `SttSpeakEvaluator()`, `const KanaTraceEvaluator()`, `TtsService.instance.speak`; `StoryProgressStore(SharedPreferences)`; `RefType` (`lib/core/ladder/rung_defs.dart`).
- Produces (für Task 4): `class StoryRoute extends ConsumerWidget` mit `const StoryRoute({super.key})` aus `package:nihongo_app/features/story/story_route.dart`; Provider `storyEpisodeProvider` (`Provider<Episode>`), `storyReaderDepsProvider` (`FutureProvider.autoDispose<({StoryProgressStore store, Set<String> knownIds})>`).

Referenz — der Reader-Konstruktor (`lib/features/story/story_reader_screen.dart:61-73`):

```dart
const StoryReaderScreen({
  super.key,
  required this.episode,            // Episode
  required this.progressStore,      // StoryProgressStore
  required this.speak,              // Future<void> Function(String)
  required this.dictionaryEntries,  // List<DictionaryEntry>
  required this.knownIds,           // Set<String>
  this.onEpisodeComplete,           // Future<void> Function()?
  this.speakEvaluator,              // SpeakEvaluator?
  this.onDiegeticSpeakSuccess,      // Future<void> Function(List<String>)?
  this.traceEvaluator,              // TraceEvaluator?
  this.onDiegeticTraceSuccess,      // Future<void> Function(List<String>)?
});
```

- [ ] **Step 1: Failing Tests schreiben**

`test/features/story/story_route_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/story/episodes/folge_01_regen.dart';
import 'package:nihongo_app/features/story/story_route.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LearningDb> _seededDb() async {
  final db = LearningDb.forTesting();
  await seedJaPack(db);
  return db;
}

void main() {
  testWidgets('die Route baut den Reader ueber die echten Provider',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('Durchlesen bis zum Ende fuehrt jedes Budget-Item auf '
      'Sprosse 0 ein — ueber die echte Route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWithValue(learning)],
      child: const MaterialApp(home: StoryRoute()),
    ));
    await tester.pumpAndSettle();

    // Bis zum letzten Panel lesen; P09 oeffnet das Woerterbuch automatisch —
    // durch Tap oberhalb des Sheets schliessen (Muster:
    // story_reader_srs_handoff_test.dart).
    for (var i = 0; i < 23; i++) {
      await tester.tap(find.byKey(const ValueKey('story-reader-panel')));
      await tester.pumpAndSettle();
      if (find.byKey(const ValueKey('dictionary-sheet')).evaluate().isNotEmpty) {
        await tester.tapAt(const Offset(400, 50));
        await tester.pumpAndSettle();
      }
    }
    await tester.pumpAndSettle();

    final episode = loadFolge01();
    for (final ref in episode.budget.items) {
      final item = await learning
          .getLearnItem('lang_ja:${ref.refType.name}:${ref.id}');
      expect(item, isNotNull, reason: '${ref.id} wurde nicht eingefuehrt');
      expect(item!.masteryRung, 0);
    }
  });

  test('knownIds enthaelt genau die schon eingefuehrten Budget-Items',
      () async {
    SharedPreferences.setMockInitialValues({});
    final learning = await _seededDb();
    addTearDown(() async => learning.close());
    await learning.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_ame',
        rung: 0);

    final container = ProviderContainer(
        overrides: [learningDbProvider.overrideWithValue(learning)]);
    addTearDown(container.dispose);

    final deps = await container.read(storyReaderDepsProvider.future);
    expect(deps.knownIds, contains('lex_ja_ame'));
    expect(deps.knownIds, isNot(contains('lex_ja_sumimasen')));
  });
}
```

Hinweis für den Implementierer: Falls `ref.refType` in `ItemRef` anders heißt oder kein `RefType` ist, in `lib/features/story/episode.dart` (Klasse `ItemRef`) nachsehen und die Row-ID exakt wie `LadderReview.introduce` (`ladder_review.dart:68`: `'$languageId:${refType.name}:$refId'`) konstruieren. Falls `lex_ja_ame` nicht im Folge-01-Budget liegt, ein tatsächliches Budget-Item aus `pilot01RegenJson` wählen (Budget-Liste in Task 1 sichtbar) und beide Erwartungen entsprechend anpassen.

- [ ] **Step 2: Tests laufen lassen — müssen failen**

Run: `flutter test test/features/story/story_route_test.dart`
Expected: FAIL — Compile-Fehler, `story_route.dart` existiert nicht.

- [ ] **Step 3: Implementieren**

`lib/features/story/story_route.dart` (komplett):

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/tts_service.dart';
import 'diegetic_encounter.dart';
import 'episode.dart';
import 'episode_srs_handoff.dart';
import 'episodes/folge_01_regen.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'story_reader_screen.dart';
import 'trace_evaluator.dart';

/// Folge 01, beim ersten Zugriff validiert. Ein Schema-Verstoss wirft —
/// und erscheint damit ehrlich als Fehler in der Route statt still
/// falschen Inhalt zu zeigen.
final storyEpisodeProvider = Provider<Episode>((ref) => loadFolge01());

/// Async-Abhaengigkeiten des Readers: Fortschritts-Store + die IDs, deren
/// Bedeutung aufgedeckt werden darf (= Budget-Items, die je eingefuehrt
/// wurden). autoDispose: bei jedem Betreten frisch berechnet, damit ein
/// zweiter Durchlauf die inzwischen eingefuehrten Woerter zeigt.
final storyReaderDepsProvider = FutureProvider.autoDispose<
    ({StoryProgressStore store, Set<String> knownIds})>((ref) async {
  final episode = ref.watch(storyEpisodeProvider);
  final learning = ref.watch(learningDbProvider);
  final languageId = 'lang_${episode.locale}';
  final prefs = await SharedPreferences.getInstance();
  final known = <String>{};
  for (final item in episode.budget.items) {
    final rowId = '$languageId:${item.refType.name}:${item.id}';
    if (await learning.getLearnItem(rowId) != null) known.add(item.id);
  }
  return (store: StoryProgressStore(prefs), knownIds: known);
});

/// W3: die echte Route um [StoryReaderScreen] — liest die Provider,
/// injiziert die Service-Singletons, mappt locale ('ja') auf die Pack-ID
/// ('lang_ja') und sichert die fire-and-forget-Callbacks des Readers ab.
/// Muster: CafeRoute (W2).
class StoryRoute extends ConsumerWidget {
  const StoryRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(storyEpisodeProvider);
    final learning = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final deps = ref.watch(storyReaderDepsProvider);
    final languageId = 'lang_${episode.locale}';

    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Folge nicht verfügbar:\n$e',
              textAlign: TextAlign.center),
        ),
      ),
      data: (d) {
        final handoff = EpisodeSrsHandoff(
          ladder: LadderReview(learning),
          languageId: languageId,
        );
        final encounter = DiegeticEncounter(
          ladder: LadderReview(learning, bridge: bridge),
          languageId: languageId,
          languageCode: episode.locale,
        );
        Future<void> encounterAll(List<String> itemIds) async {
          for (final id in itemIds) {
            await encounter.encounter(RefType.lexeme, id);
          }
        }

        return StoryReaderScreen(
          episode: episode,
          progressStore: d.store,
          speak: (t) => TtsService.instance.speak(t),
          dictionaryEntries: folge01DictionaryEntries,
          knownIds: d.knownIds,
          onEpisodeComplete: () => handoff.introduceEpisode(episode).catchError(
              (Object e) => debugPrint('story: SRS-Handoff fehlgeschlagen: $e')),
          speakEvaluator: SttSpeakEvaluator(),
          onDiegeticSpeakSuccess: (ids) => encounterAll(ids).catchError(
              (Object e) => debugPrint('story: Speak-Encounter fehlgeschlagen: $e')),
          traceEvaluator: const KanaTraceEvaluator(),
          onDiegeticTraceSuccess: (ids) => encounterAll(ids).catchError(
              (Object e) => debugPrint('story: Trace-Encounter fehlgeschlagen: $e')),
        );
      },
    );
  }
}
```

Hinweis: Falls `LadderReview.learning` in Task 2 nicht öffentlich gebraucht wurde und `ItemRef.refType` ein String ist, gilt derselbe Hinweis wie im Test — die Row-ID-Konstruktion exakt an `ladder_review.dart:68` spiegeln.

- [ ] **Step 4: Tests laufen lassen**

Run: `flutter test test/features/story/ 2>&1 | tail -5`
Expected: PASS (alle drei neuen Tests + Bestand).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/story_route.dart test/features/story/story_route_test.dart
git commit -m "feat(story): StoryRoute — der Reader haengt an echten Providern, TTS/STT/Trace und dem SRS (W3)"
```

---

### Task 4: Einstieg im Lesen-Tab — der Folge-FAB ist IMMER da

Design-Prinzip „Lesen ab Tag 1 — der Manga wartet auf niemanden" (Spec `docs/superpowers/specs/2026-09-13-lernmechanik-ein-lernweg-zwei-gleise-design.md`, §3): Der Story-Einstieg darf NICHT am Mining-Store hängen. Deshalb wandern die FABs aus `_ReadingTabBody` (nur im Mining-Happy-Path erreichbar) hoch in `ReadingTab`, das ein äußeres `Scaffold` bekommt. Der Comic-FAB bleibt bedingt (Mining + Comic-Pack), der Story-FAB ist unbedingt.

**Files:**
- Modify: `lib/features/mining_slice/reading_tab.dart`
- Test: `test/features/mining_slice/reading_tab_test.dart` (erweitern; bestehende 3 Tests müssen unverändert grün bleiben)

**Interfaces:**
- Consumes: `StoryRoute` (Task 3), bestehende Provider/Widgets in `reading_tab.dart` (`readingRepositoryProvider`, `comicPackProvider`, `miningDbProvider`, `OpeningGate`, `ComicReaderScreen`, `ComicRepository`, `_EmptyComicDictionary`).
- Produces: Widget-Key `'story-entry-fab'` (der Einstieg), unverändert `'comic-entry-fab'`.

**Fallstricke:** (a) Zwei `FloatingActionButton` im selben Screen → Hero-Tag-Kollision; beide bekommen explizite `heroTag`s. (b) Die `when`-Zweige von `ReadingTab` bauen heute eigene `Scaffold`s — die inneren Scaffolds bleiben erhalten (verschachtelte Scaffolds sind zulässig), nur das äußere trägt die FABs.

- [ ] **Step 1: Failing Tests schreiben**

In `test/features/mining_slice/reading_tab_test.dart` Imports ergänzen und zwei Tests anhängen:

```dart
// zusätzliche Imports oben in der Datei:
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/mining_slice/reading_tab.dart'; // (bereits da)
import 'package:nihongo_app/packs/ja/ja_seed.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

```dart
  testWidgets('der Folge-Einstieg ist auch OHNE Mining-Store da und '
      'oeffnet den Story-Reader (Lesen ab Tag 1)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    addTearDown(() async => learning.close());
    await seedJaPack(learning);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Mining bewusst NICHT konfiguriert: miningDbProvider bleibt null →
        // "Mining ist nicht konfiguriert." — der Manga-Einstieg muss trotzdem da sein.
        learningDbProvider.overrideWithValue(learning),
      ],
      child: const MaterialApp(home: ReadingTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-entry-fab')), findsOneWidget);
    expect(find.byKey(const ValueKey('comic-entry-fab')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('story-entry-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-reader-panel')), findsOneWidget);
  });

  testWidgets('der Folge-Einstieg ist auch im Mining-Happy-Path da',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final learning = LearningDb.forTesting();
    final db = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await db.close();
    });
    await seedJaPack(learning);
    final repo = SliceRepository(db: db, pack: _pack());
    await repo.seed(includeDemoKnowledge: false);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        learningDbProvider.overrideWithValue(learning),
        readingRepositoryProvider.overrideWith((ref) async => repo),
      ],
      child: const MaterialApp(home: ReadingTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('story-entry-fab')), findsOneWidget);
    expect(find.byKey(const ValueKey('blank-slate')), findsOneWidget);
  });
```

- [ ] **Step 2: Tests laufen lassen — müssen failen**

Run: `flutter test test/features/mining_slice/reading_tab_test.dart`
Expected: FAIL — `story-entry-fab` wird nicht gefunden (im No-Mining-Fall existiert heute gar kein FAB).

- [ ] **Step 3: Implementieren**

`lib/features/mining_slice/reading_tab.dart` — `ReadingTab` und `_ReadingTabBody` ersetzen (Provider und `_EmptyComicDictionary` bleiben unverändert); neue Imports: `../story/story_route.dart`:

```dart
class ReadingTab extends ConsumerWidget {
  const ReadingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = ref.watch(readingRepositoryProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Lesen nicht verfügbar:\n$e',
                textAlign: TextAlign.center),
          ),
          data: (repo) => repo == null
              ? const Center(child: Text('Mining ist nicht konfiguriert.'))
              : OpeningGate(repo: repo),
        );

    return Scaffold(
      body: body,
      floatingActionButton: const _ReadingFabs(),
    );
  }
}

/// Die Einstiege ins bebilderte Lesen. Der Folge-Einstieg (Story-Engine)
/// ist IMMER da — „Lesen ab Tag 1": er haengt nur an der LearningDb, nie
/// am Mining-Store. Der Comic-Einstieg bleibt opt-in wie gehabt
/// (Mining-Store + gebuendeltes Comic-Pack).
class _ReadingFabs extends ConsumerWidget {
  const _ReadingFabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(miningDbProvider);
    final comicPack = ref.watch(comicPackProvider).valueOrNull;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (db != null && comicPack != null) ...[
          FloatingActionButton(
            key: const ValueKey('comic-entry-fab'),
            heroTag: 'comic-entry',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ComicReaderScreen(
                repo: ComicRepository(
                  db: db,
                  pack: comicPack,
                  dictionary: const _EmptyComicDictionary(),
                ),
                // TODO(follow-up): source from the active pack's
                // ScriptProfile.direction instead of a fixed ltr default.
                direction: TextDirection.ltr,
              ),
            )),
            child: const Icon(Icons.auto_stories),
          ),
          const SizedBox(height: 12),
        ],
        FloatingActionButton.extended(
          key: const ValueKey('story-entry-fab'),
          heroTag: 'story-entry',
          icon: const Icon(Icons.menu_book),
          label: const Text('Folge 1: Regen'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StoryRoute()),
          ),
        ),
      ],
    );
  }
}
```

`_ReadingTabBody` entfällt ersatzlos (sein Inhalt ist auf `ReadingTab`/`_ReadingFabs` aufgeteilt). Der bestehende `TextDirection`-TODO-Kommentar wandert wörtlich mit.

- [ ] **Step 4: Tests laufen lassen — neue + alle bestehenden**

Run: `flutter test test/features/mining_slice/ 2>&1 | tail -5`
Expected: PASS — insbesondere der bestehende `blank-slate`-Test unverändert grün (das äußere Scaffold ändert die OpeningGate-Darstellung nicht).

- [ ] **Step 5: Commit**

```bash
git add lib/features/mining_slice/reading_tab.dart test/features/mining_slice/reading_tab_test.dart
git commit -m "feat(read): Folge-1-Einstieg im Lesen-Tab — immer sichtbar, oeffnet den Story-Reader (W3)"
```

---

### Task 5: `KanaTraceEvaluator`-Smoke mit dem gebündelten あ

Der Trace-Evaluator läuft mit W3 erstmals im echten Betrieb. Dieser Charakterisierungs-Test beweist die Naht Evaluator → gebündeltes KanjiVG-SVG (`assets/kanji_svg/3042.svg` = あ), die bisher kein Test abdeckt (bestehende Tests nutzen Fakes). KEIN Implementierungs-Step — getestet wird Bestandscode; ein Fehlschlag ist ein echter Befund und wird verortet, nicht wegjustiert.

**Files:**
- Test: `test/features/story/kana_trace_evaluator_asset_test.dart`

**Interfaces:**
- Consumes: `const KanaTraceEvaluator()` / `TraceEvaluator.evaluate(String target, List<List<Offset>> userStrokes)` (`lib/features/story/trace_evaluator.dart`).
- Produces: nichts (reiner Verifikations-Task).

- [ ] **Step 1: Test schreiben**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/trace_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<List<Offset>> strokes(int n) => List.generate(
      n, (_) => [const Offset(0, 0), const Offset(10, 10)]);

  test('あ nutzt das gebuendelte SVG: erst die volle Strichzahl genuegt',
      () async {
    const evaluator = KanaTraceEvaluator();
    // Erwartete Strichzahl = Anzahl der <path>-Elemente in
    // assets/kanji_svg/3042.svg (KanjiVG: あ hat 3 Striche). Weicht das
    // SVG ab, gilt das SVG — Zahl hier anpassen und im Commit begruenden.
    expect(await evaluator.evaluate('あ', strokes(3)), isTrue);
    expect(await evaluator.evaluate('あ', strokes(2)), isFalse);
  });

  test('め ist nicht gebuendelt und faellt ehrlich auf Minimum 1 zurueck',
      () async {
    const evaluator = KanaTraceEvaluator();
    expect(await evaluator.evaluate('め', strokes(1)), isTrue);
  });
}
```

- [ ] **Step 2: Test laufen lassen**

Run: `flutter test test/features/story/kana_trace_evaluator_asset_test.dart`
Expected: PASS. Falls FAIL: Verhalten von `KanaTraceEvaluator.evaluate` + `strokeAssetForKana` + SVG-Inhalt prüfen und den Befund im Commit dokumentieren — NICHT blind die Erwartung umdrehen.

- [ ] **Step 3: Commit**

```bash
git add test/features/story/kana_trace_evaluator_asset_test.dart
git commit -m "test(story): KanaTraceEvaluator-Naht zum gebuendelten あ-SVG charakterisiert (W3)"
```

---

### Task 6: Full-Suite + Analyzer — Regress-Freiheit beweisen

**Files:** keine neuen; nur Verifikation (und ggf. Fixes mit eigenem Commit).

- [ ] **Step 1: Analyzer**

Run: `flutter analyze 2>&1 | tail -5`
Expected: keine neuen Warnungen/Fehler in den von W3 berührten Dateien (Bestands-Infos sind okay, wenn sie auch auf main bestehen — im Zweifel `git stash`-frei per `git diff origin/main --name-only` die berührten Dateien listen und nur deren Meldungen bewerten).

- [ ] **Step 2: Full-Suite**

Run: `flutter test 2>&1 | tail -15`
Expected: Fehlschläge sind AUSSCHLIESSLICH die 8 vorbestehenden in `test/mining_packs/ja/` (native Tokenizer-`.so` fehlt headless). Jeder andere Fehler wird verortet und gefixt, bevor der Branch fertig gemeldet wird — nie als „flaky" abgetan ohne isolierte Verifikation.

- [ ] **Step 3: Abschluss-Commit (nur falls Fixes anfielen)**

```bash
git add -A && git commit -m "test(w3): Full-Suite-Regresse behoben"
```

---

## Anschlussstellen (bewusst NICHT in diesem Plan)

- **ComfyUI-Panels einsetzen** (sobald Uli die Bilder freigibt): PNGs z. B. nach `assets/story/`, pubspec-Eintrag `assets/story/`, `asset`-Strings in `lib/features/story/episodes/folge_01_regen.dart` von `assets/comic/placeholder_page.png` auf die echten Dateien umstellen. Reiner Content-Tausch, kein Code.
- **め-SVG bündeln** + Formscoring im `KanaTraceEvaluator` (heute Strichzahl-Minimum-1-Fallback für め — funktioniert, ist nur grob).
- **Gerätetest** (TTS/STT sind Singletons mit Plattform-Kanälen — headless nicht prüfbar): Folge 01 auf dem S23 durchspielen.
- **PRAGMA foreign_keys=ON** app-weit (vorbestehendes Folge-Ticket; W3 ist durch `seedJaPack`-Reihenfolge in `main.dart` gedeckt).
