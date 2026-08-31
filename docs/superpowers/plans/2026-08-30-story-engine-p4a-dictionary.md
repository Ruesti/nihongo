# Story-Engine P4a — Diegetic Dictionary (browsing, no story wiring) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the dictionary as a standalone, browsable object — kana-order (gojūon) navigation with no search field, meanings shown only for entries the reader already knows, and previous-owner margin notes that are always visible but never resolvable — matching `docs/story/BRIEF_STORY_ENGINE.md` §3.1/§3.2/§3.5. This is the first of two planned slices of the brief's phase P4 ("Wörterbuch: Kana-Blättern, Kosten, Handschrift-Bestand"): P4a builds the dictionary itself, provably correct on its own; a second slice (P4b, not part of this plan) wires it into the reader's forced-open moment at Folge 01/P09, including the "cost" mechanic (visible time passing) — that acceptance bar ("P09 fühlt sich richtig an") needs the reader integration this plan deliberately doesn't build yet.

**Architecture:** Two new, additive files under `lib/features/story/`, following the same self-contained, DB-free pattern as P1–P3 — no dependency on the real `LearnItems`/SRS tables (per the brief, "der Bestand des Buchs ist der SRS-Bestand", but wiring that up for real is the brief's own later phase P5, "Auslauf + SRS-Übergabe"; P4a takes a `Set<String> knownIds` as a plain constructor parameter instead, matching how `StoryReaderScreen` already takes its dependencies as explicit injected values rather than reading a real database). Gojūon browsing reuses the row/character grouping shape already established by `lib/data/kana_data.dart`'s `ScriptGroup`, but with a phase-appropriate extension (see Global Constraints) rather than modifying that shared file.

**Tech Stack:** Dart 3.11 / Flutter, `flutter_test`. No new packages.

## Global Constraints

- Base branch: `origin/main` — now includes phases P1–P3 (merged via PR #28/#29/#30): the `Episode`/`StoryPanel`/`StoryToken` schema and the Folge 01 "Regen" fixture (P1), `StoryReaderScreen` + `StoryProgressStore` (P2), and per-token tap-for-audio (P3). This plan does not modify any of those files.
- No DB/SRS integration in this phase. "Known" state is a plain `Set<String> knownIds` passed into the widget — not derived from `LearnItems`, `MiningDb`, or any Drift table. This mirrors the established precedent in this exact codebase: the comic feature's own dictionary seam (`lib/features/mining_slice/reading_tab.dart`) is deliberately an empty stub today with an explicit "wire a real dictionary later" comment — the same deferred-integration pattern, not a new one.
- No JMdict integration. `lib/mining_packs/ja/jmdict_db.dart`/`jmdict_tables.dart` exist but ship no bundled data (only a raw Drift schema plus an XML import CLI tool) and would require async DB setup with an XML fixture per test — real integration is future work once meanings actually need to come from a real dictionary source, not this phase's job.
- Gojūon groups for this feature are **not** `lib/data/kana_data.dart`'s `hiraganaGroups` — that list only has the 10 base seion rows with no voiced (濁音)/semi-voiced (半濁音) kana, which would leave words starting with a voiced kana (e.g. どうぞ, one of Folge 01's own 8 budgeted words) unreachable when browsing by row. This plan defines its own `dictionaryGroups` list (Task 2) with each row extended to include its voiced/semi-voiced kana, kept local to `lib/features/story/` rather than changing the shared `kana_data.dart`, since no other feature currently needs full-row voiced-kana grouping.
- No "handwriting" web font (e.g. via `google_fonts`, which is already a pubspec dependency but is only ever used in `lib/core/theme.dart`, with zero existing test coverage exercising it — introducing it here would be the first-ever GoogleFonts widget test in this codebase, an avoidable risk). The "handwritten vs. printed" distinction (brief §3.1) is represented with plain, always-available `TextStyle` properties instead (italic + a distinct color) — swapping in a real handwriting font later is a simple, isolated follow-up once that's confirmed test-safe.
- A margin note has **no gesture handler at all** once rendered — not a disabled-looking affordance, genuinely absent as an interactive element — matching exactly how P3 renders locked (non-lookupable) tokens in the panel reader (brief §3.5: "sie sind nie auflösbar — kein Tap").
- Run tests with `flutter test <path>` from the repo root.

---

### Task 1: Dictionary entry model + Folge 01 fixture

**Files:**
- Create: `lib/features/story/dictionary.dart`
- Create: `test/fixtures/story/folge_01_dictionary_fixture.dart`
- Test: `test/fixtures/story/folge_01_dictionary_fixture_test.dart`

**Interfaces:**
- Produces (used by Task 2): `class DictionaryEntry { final String id; final String headword; final String meaning; final String? marginNote; const DictionaryEntry({required id, required headword, required meaning, marginNote}); }`; `const List<DictionaryEntry> folge01DictionaryEntries` (8 entries, `id`s matching the `itemId`s already used in the P1 Folge 01 episode fixture: `lex_ja_sumimasen`, `lex_ja_ame`, `lex_ja_kasa`, `lex_ja_kore`, `lex_ja_kowareta`, `lex_ja_hai`, `lex_ja_douzo`, `lex_ja_arigatou`).

- [ ] **Step 1: Write the failing test**

Create `test/fixtures/story/folge_01_dictionary_fixture_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'folge_01_dictionary_fixture.dart';

void main() {
  test('has exactly the 8 budgeted words from Folge 01, each with a German meaning',
      () {
    expect(folge01DictionaryEntries, hasLength(8));
    for (final entry in folge01DictionaryEntries) {
      expect(entry.meaning, isNotEmpty);
    }
  });

  test("only あめ carries the previous owner's margin note", () {
    final withNotes =
        folge01DictionaryEntries.where((e) => e.marginNote != null).toList();
    expect(withNotes, hasLength(1));
    expect(withNotes.single.headword, 'あめ');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/fixtures/story/folge_01_dictionary_fixture_test.dart`
Expected: FAIL — `folge_01_dictionary_fixture.dart` does not exist yet (import error).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/dictionary.dart`:

```dart
/// One entry in the diegetic dictionary (brief §3). The dictionary's
/// contents are the reader's own learned vocabulary — [meaning] is only
/// ever shown once the reader has learned this entry (see
/// `DictionarySheet`'s `knownIds`). [marginNote], when present, belongs to
/// the book's previous owner and is never resolvable (§3.5) — it is not
/// itself a translation and is unrelated to whether the entry is known.
class DictionaryEntry {
  final String id;
  final String headword;
  final String meaning;
  final String? marginNote;

  const DictionaryEntry({
    required this.id,
    required this.headword,
    required this.meaning,
    this.marginNote,
  });
}
```

Create `test/fixtures/story/folge_01_dictionary_fixture.dart`:

```dart
import 'package:nihongo_app/features/story/dictionary.dart';

/// The 8 budgeted words from Folge 01 "Regen" (docs/story/PILOT_01_REGEN.md),
/// with German meanings from the episode's own vocabulary table. あめ carries
/// the previous owner's margin note first alluded to at P24 ("ein kurzer
/// Vermerk in Kanji und ein Datum") — the only entry with one, matching the
/// brief's dosage rule of at most one note per episode (§3.5).
const List<DictionaryEntry> folge01DictionaryEntries = [
  DictionaryEntry(
    id: 'lex_ja_sumimasen',
    headword: 'すみません',
    meaning: 'Entschuldigung / Verzeihung',
  ),
  DictionaryEntry(
    id: 'lex_ja_ame',
    headword: 'あめ',
    meaning: 'Regen',
    marginNote: '(unleserliche Randnotiz, Kanji und Datum)',
  ),
  DictionaryEntry(
    id: 'lex_ja_kasa',
    headword: 'かさ',
    meaning: 'Schirm',
  ),
  DictionaryEntry(
    id: 'lex_ja_kore',
    headword: 'これ',
    meaning: 'das hier',
  ),
  DictionaryEntry(
    id: 'lex_ja_kowareta',
    headword: 'こわれた',
    meaning: 'kaputt',
  ),
  DictionaryEntry(
    id: 'lex_ja_hai',
    headword: 'はい',
    meaning: 'ja',
  ),
  DictionaryEntry(
    id: 'lex_ja_douzo',
    headword: 'どうぞ',
    meaning: 'bitte / hier',
  ),
  DictionaryEntry(
    id: 'lex_ja_arigatou',
    headword: 'ありがとう',
    meaning: 'danke',
  ),
];
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/fixtures/story/folge_01_dictionary_fixture_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/story/dictionary.dart test/fixtures/story/folge_01_dictionary_fixture.dart test/fixtures/story/folge_01_dictionary_fixture_test.dart
git commit -m "feat(story): add DictionaryEntry model and Folge 01 dictionary fixture"
```

---

### Task 2: Gojūon browsing groups + DictionarySheet widget

**Files:**
- Create: `lib/features/story/dictionary_groups.dart`
- Create: `lib/features/story/dictionary_sheet.dart`
- Test: `test/features/story/dictionary_sheet_test.dart`

**Interfaces:**
- Consumes: `DictionaryEntry` from Task 1 (`lib/features/story/dictionary.dart`); `folge01DictionaryEntries` from Task 1's fixture (test-only use); `ScriptGroup` from `lib/core/language_module.dart` (already exists: `{name: String, characters: List<String>, romanizations: List<String>}`).
- Produces: `const List<ScriptGroup> dictionaryGroups` (10 rows, each including its voiced/semi-voiced kana); `class DictionarySheet extends StatefulWidget { const DictionarySheet({required List<DictionaryEntry> entries, required Set<String> knownIds}); }`. Widget keys: `ValueKey('dictionary-group-list')`, `ValueKey('dictionary-group-<name>')` per row (e.g. `dictionary-group-あ行`), `ValueKey('dictionary-entry-list')`, `ValueKey('dictionary-back')`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/story/dictionary_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/dictionary_groups.dart';
import 'package:nihongo_app/features/story/dictionary_sheet.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';

const _entries = [
  DictionaryEntry(
    id: 'lex_a',
    headword: 'あめ',
    meaning: 'Regen',
    marginNote: 'unleserliche Notiz',
  ),
  DictionaryEntry(id: 'lex_b', headword: 'かさ', meaning: 'Schirm'),
];

void main() {
  test('every Folge 01 dictionary entry is reachable via some gojūon group',
      () {
    for (final entry in folge01DictionaryEntries) {
      final reachable = dictionaryGroups.any(
        (g) => g.characters.contains(entry.headword[0]),
      );
      expect(
        reachable,
        isTrue,
        reason:
            '${entry.headword} (id: ${entry.id}) is not reachable via any dictionaryGroups row',
      );
    }
  });

  testWidgets('shows the gojūon group list first, not individual entries',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    expect(find.text('あ行'), findsOneWidget);
    expect(find.text('か行'), findsOneWidget);
    expect(find.text('あめ'), findsNothing);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets(
      'tapping a group shows only entries whose headword starts in that row',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();

    expect(find.text('あめ'), findsOneWidget);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets('the back button returns from entries to the group list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();
    expect(find.text('あめ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dictionary-back')));
    await tester.pump();

    expect(find.text('あ行'), findsOneWidget);
    expect(find.text('あめ'), findsNothing);
  });

  testWidgets('a known entry shows its meaning; an unknown entry does not',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {'lex_a'}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();
    expect(find.text('Regen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dictionary-back')));
    await tester.pump();
    await tester.tap(find.text('か行'));
    await tester.pump();
    expect(find.text('Schirm'), findsNothing);
    expect(find.text('かさ'), findsOneWidget);
  });

  testWidgets('a margin note is always visible and has no gesture handler',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();

    expect(find.text('unleserliche Notiz'), findsOneWidget);

    // No gesture handler wraps the note at all, so tapping it is a no-op —
    // nothing new appears, nothing throws.
    await tester.tap(find.text('unleserliche Notiz'));
    await tester.pump();
    expect(find.text('unleserliche Notiz'), findsOneWidget);
  });

  testWidgets(
      'reading the real Folge 01 fixture: すみません is unknown and shows no meaning',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(
          entries: folge01DictionaryEntries,
          knownIds: const {},
        ),
      ),
    ));

    await tester.tap(find.text('さ行'));
    await tester.pump();

    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Entschuldigung / Verzeihung'), findsNothing);
  });

  testWidgets(
      'reading the real Folge 01 fixture: どうぞ is reachable via た行 (voiced row)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(
          entries: folge01DictionaryEntries,
          knownIds: const {'lex_ja_douzo'},
        ),
      ),
    ));

    await tester.tap(find.text('た行'));
    await tester.pump();

    expect(find.text('どうぞ'), findsOneWidget);
    expect(find.text('bitte / hier'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/story/dictionary_sheet_test.dart`
Expected: FAIL — `dictionary_groups.dart` and `dictionary_sheet.dart` do not exist yet (import errors).

- [ ] **Step 3: Write the implementation**

Create `lib/features/story/dictionary_groups.dart`:

```dart
import '../../core/language_module.dart' show ScriptGroup;

/// Gojūon rows for browsing the diegetic dictionary (brief §3.2), each
/// extended to include its voiced (濁音) and semi-voiced (半濁音) kana in
/// the same row — e.g. た行 also covers だ/ぢ/づ/で/ど. `kana_data.dart`'s
/// `hiraganaGroups` only lists the 10 base seion rows, which would leave
/// words starting with a voiced kana (like どうぞ, one of Folge 01's own
/// budgeted words) unreachable when browsing by row. Kept local to this
/// feature rather than added to the shared `kana_data.dart`, since no other
/// feature currently needs full-row voiced-kana grouping.
const List<ScriptGroup> dictionaryGroups = [
  ScriptGroup(
    name: 'あ行',
    characters: ['あ', 'い', 'う', 'え', 'お'],
    romanizations: ['a', 'i', 'u', 'e', 'o'],
  ),
  ScriptGroup(
    name: 'か行',
    characters: ['か', 'き', 'く', 'け', 'こ', 'が', 'ぎ', 'ぐ', 'げ', 'ご'],
    romanizations: [
      'ka', 'ki', 'ku', 'ke', 'ko',
      'ga', 'gi', 'gu', 'ge', 'go',
    ],
  ),
  ScriptGroup(
    name: 'さ行',
    characters: ['さ', 'し', 'す', 'せ', 'そ', 'ざ', 'じ', 'ず', 'ぜ', 'ぞ'],
    romanizations: [
      'sa', 'shi', 'su', 'se', 'so',
      'za', 'ji', 'zu', 'ze', 'zo',
    ],
  ),
  ScriptGroup(
    name: 'た行',
    characters: ['た', 'ち', 'つ', 'て', 'と', 'だ', 'ぢ', 'づ', 'で', 'ど'],
    romanizations: [
      'ta', 'chi', 'tsu', 'te', 'to',
      'da', 'ji', 'zu', 'de', 'do',
    ],
  ),
  ScriptGroup(
    name: 'な行',
    characters: ['な', 'に', 'ぬ', 'ね', 'の'],
    romanizations: ['na', 'ni', 'nu', 'ne', 'no'],
  ),
  ScriptGroup(
    name: 'は行',
    characters: [
      'は', 'ひ', 'ふ', 'へ', 'ほ',
      'ば', 'び', 'ぶ', 'べ', 'ぼ',
      'ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ',
    ],
    romanizations: [
      'ha', 'hi', 'fu', 'he', 'ho',
      'ba', 'bi', 'bu', 'be', 'bo',
      'pa', 'pi', 'pu', 'pe', 'po',
    ],
  ),
  ScriptGroup(
    name: 'ま行',
    characters: ['ま', 'み', 'む', 'め', 'も'],
    romanizations: ['ma', 'mi', 'mu', 'me', 'mo'],
  ),
  ScriptGroup(
    name: 'や行',
    characters: ['や', 'ゆ', 'よ'],
    romanizations: ['ya', 'yu', 'yo'],
  ),
  ScriptGroup(
    name: 'ら行',
    characters: ['ら', 'り', 'る', 'れ', 'ろ'],
    romanizations: ['ra', 'ri', 'ru', 're', 'ro'],
  ),
  ScriptGroup(
    name: 'わ行',
    characters: ['わ', 'を', 'ん'],
    romanizations: ['wa', 'wo', 'n'],
  ),
];
```

Create `lib/features/story/dictionary_sheet.dart`:

```dart
import 'package:flutter/material.dart';

import '../../core/language_module.dart' show ScriptGroup;
import 'dictionary.dart';
import 'dictionary_groups.dart';

/// Browses [entries] by gojūon row — no search field. Looking something up
/// requires knowing its reading well enough to find the right row and
/// character (brief §3.2 — the friction is deliberate). An entry's
/// [DictionaryEntry.meaning] only renders once its id is in [knownIds];
/// otherwise only the headword shows. A margin note, when present, always
/// shows regardless of known-state and has no gesture handler at all — not
/// merely undecorated, genuinely unresolvable (§3.5), matching how locked
/// tokens render inert in the panel reader (P3).
class DictionarySheet extends StatefulWidget {
  final List<DictionaryEntry> entries;
  final Set<String> knownIds;

  const DictionarySheet({
    super.key,
    required this.entries,
    required this.knownIds,
  });

  @override
  State<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<DictionarySheet> {
  ScriptGroup? _selectedGroup;

  List<DictionaryEntry> _entriesForGroup(ScriptGroup group) {
    return widget.entries
        .where((e) => group.characters.contains(e.headword[0]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final group = _selectedGroup;
    if (group == null) {
      return ListView(
        key: const ValueKey('dictionary-group-list'),
        children: [
          for (final g in dictionaryGroups)
            ListTile(
              key: ValueKey('dictionary-group-${g.name}'),
              title: Text(g.name),
              onTap: () => setState(() => _selectedGroup = g),
            ),
        ],
      );
    }

    return Column(
      key: const ValueKey('dictionary-entry-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const ValueKey('dictionary-back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedGroup = null),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final entry in _entriesForGroup(group)) _entryTile(entry),
            ],
          ),
        ),
      ],
    );
  }

  Widget _entryTile(DictionaryEntry entry) {
    final known = widget.knownIds.contains(entry.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.headword,
            style: entry.marginNote != null
                ? const TextStyle(decoration: TextDecoration.underline)
                : null,
          ),
          if (known)
            Text(
              entry.meaning,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Color(0xFF2A4D8F),
              ),
            ),
          if (entry.marginNote != null)
            Text(
              entry.marginNote!,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/story/dictionary_sheet_test.dart`
Expected: PASS (all 8 tests: 1 plain `test`, 7 `testWidgets`).

- [ ] **Step 5: Run the full story-feature test suite together**

Run: `flutter test test/features/story/ test/fixtures/story/`
Expected: PASS (all tests across P1–P3 and this plan — 33 total).

- [ ] **Step 6: Commit**

```bash
git add lib/features/story/dictionary_groups.dart lib/features/story/dictionary_sheet.dart test/features/story/dictionary_sheet_test.dart
git commit -m "feat(story): add gojūon-browsing DictionarySheet (P4a — dictionary object)"
```
