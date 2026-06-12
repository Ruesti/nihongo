# Phase 0: New Schema Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the new Drift database schema, typed `ScriptProfile` model, and a minimal Japanese seed pack as the data foundation for the multilingual learning app — without breaking any existing features.

**Architecture:** A new `LearningDb` (in `lib/core/db/`) is created alongside the existing `AppDatabase` so old features keep compiling and running. `ScriptProfile` is a pure Dart model; the Drift-generated row class is named `ScriptProfileRow` to avoid a name collision. The JA seed pack is idempotent and runs once at cold start.

**Tech Stack:** Dart 3.11, Drift 2.22, sqlite3_flutter_libs, build_runner, dart:convert (SDK), flutter_test / NativeDatabase.memory().

---

### Task 1: ScriptProfile model

**Files:**
- Create: `lib/core/script_profile.dart`
- Create: `test/core/script_profile_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/core/script_profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/script_profile.dart';

void main() {
  test('ScriptProfile fields round-trip', () {
    const p = ScriptProfile(
      id: 'sp_test',
      scriptType: ScriptType.syllabary,
      direction: Direction.ltr,
      decomposability: Decomposability.atomic,
      positionalForms: false,
      toneSystem: ToneSystem.pitchAccent,
      needsScriptTrack: true,
      transliteration: 'romaji',
      inputMethods: [InputMethod.keyboard, InputMethod.ime],
    );
    expect(p.scriptType, ScriptType.syllabary);
    expect(p.direction, Direction.ltr);
    expect(p.inputMethods, [InputMethod.keyboard, InputMethod.ime]);
  });

  test('isDecomposable true when not atomic', () {
    const p = ScriptProfile(
      id: 'sp_kanji',
      scriptType: ScriptType.logographic,
      direction: Direction.ltr,
      decomposability: Decomposability.radicals,
      positionalForms: false,
      toneSystem: ToneSystem.none,
      needsScriptTrack: true,
      transliteration: 'none',
      inputMethods: [InputMethod.ime],
    );
    expect(p.isDecomposable, isTrue);
  });

  test('isDecomposable false when atomic', () {
    const p = ScriptProfile(
      id: 'sp_latin',
      scriptType: ScriptType.alphabet,
      direction: Direction.ltr,
      decomposability: Decomposability.atomic,
      positionalForms: false,
      toneSystem: ToneSystem.none,
      needsScriptTrack: false,
      transliteration: 'none',
      inputMethods: [InputMethod.keyboard],
    );
    expect(p.isDecomposable, isFalse);
  });

  test('hasToneSystem true for tonal', () {
    const p = ScriptProfile(
      id: 'sp_zh',
      scriptType: ScriptType.logographic,
      direction: Direction.ltr,
      decomposability: Decomposability.radicals,
      positionalForms: false,
      toneSystem: ToneSystem.tonal,
      needsScriptTrack: false,
      transliteration: 'pinyin',
      inputMethods: [InputMethod.ime],
    );
    expect(p.hasToneSystem, isTrue);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/script_profile_test.dart
```
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Create `lib/core/script_profile.dart`**

```dart
enum ScriptType { alphabet, syllabary, logographic, abugida, abjad, hangul }

enum Direction { ltr, rtl }

enum Decomposability { atomic, radicals, jamo, consonantMatra, baseDiacritics }

enum ToneSystem { none, tonal, pitchAccent, vowelPoints }

enum InputMethod { keyboard, ime, handwriting }

class ScriptProfile {
  final String id;
  final ScriptType scriptType;
  final Direction direction;
  final Decomposability decomposability;
  final bool positionalForms;
  final ToneSystem toneSystem;
  final bool needsScriptTrack;
  final String transliteration;
  final List<InputMethod> inputMethods;

  const ScriptProfile({
    required this.id,
    required this.scriptType,
    required this.direction,
    required this.decomposability,
    required this.positionalForms,
    required this.toneSystem,
    required this.needsScriptTrack,
    required this.transliteration,
    required this.inputMethods,
  });

  bool get isDecomposable => decomposability != Decomposability.atomic;

  bool get hasToneSystem =>
      toneSystem == ToneSystem.tonal || toneSystem == ToneSystem.vowelPoints;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/script_profile_test.dart
```
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/script_profile.dart test/core/script_profile_test.dart
git commit -m "feat(phase0): add ScriptProfile model with typed enums"
```

---

### Task 2: Drift table definitions and LearningDb

**Files:**
- Create: `lib/core/db/tables.dart`
- Create: `lib/core/db/learning_db.dart`
- Create (generated): `lib/core/db/learning_db.g.dart`
- Create: `test/core/db/learning_db_test.dart`

- [ ] **Step 1: Create `lib/core/db/tables.dart`**

```dart
import 'package:drift/drift.dart';

class Concepts extends Table {
  TextColumn get id => text()();
  TextColumn get glossKey => text()();
  TextColumn get partOfSpeech => text()();
  TextColumn get defaultAssetType =>
      text().withDefault(const Constant('none'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get conceptId =>
      text().references(Concepts, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // image|clip|icon|none
  TextColumn get path => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScriptProfileRow')
class ScriptProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get scriptType => text()(); // alphabet|syllabary|logographic|abugida|abjad|hangul
  TextColumn get direction =>
      text().withDefault(const Constant('ltr'))(); // ltr|rtl
  TextColumn get decomposability =>
      text()(); // atomic|radicals|jamo|consonantMatra|baseDiacritics
  BoolColumn get positionalForms =>
      boolean().withDefault(const Constant(false))();
  TextColumn get toneSystem =>
      text().withDefault(const Constant('none'))(); // none|tonal|pitchAccent|vowelPoints
  BoolColumn get needsScriptTrack =>
      boolean().withDefault(const Constant(false))();
  TextColumn get transliteration =>
      text().withDefault(const Constant('none'))();
  TextColumn get inputMethodsJson =>
      text().withDefault(const Constant('["keyboard"]'))(); // JSON array

  @override
  Set<Column> get primaryKey => {id};
}

class Languages extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get scriptProfileId =>
      text().references(ScriptProfiles, #id)();
  TextColumn get ttsVoice => text()();
  BoolColumn get enabled =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Lexemes extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get conceptId =>
      text().references(Concepts, #id)();
  TextColumn get writtenForm => text()();
  TextColumn get reading => text()();
  TextColumn get audioPath => text().nullable()();
  TextColumn get cefrBand =>
      text().withDefault(const Constant('A1'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Characters extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get glyph => text()();
  TextColumn get readingsJson => text()(); // JSON list of strings
  TextColumn get meaning => text()();
  TextColumn get strokeOrderAssetId => text().nullable()();
  TextColumn get mnemonicId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class CharComponents extends Table {
  TextColumn get id => text()();
  TextColumn get characterId =>
      text().references(Characters, #id, onDelete: KeyAction.cascade)();
  TextColumn get componentGlyph => text()();
  TextColumn get position => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class CanDoGoals extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get cefrBand => text()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class GrammarPoints extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get cefrBand => text()();
  IntColumn get sequenceIndex => integer()();
  TextColumn get canDoId =>
      text().references(CanDoGoals, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

class Sentences extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get cefrBand => text()();
  TextColumn get content => text()(); // the sentence text
  RealColumn get knownCoverage =>
      real().withDefault(const Constant(1.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LearnItems extends Table {
  TextColumn get id => text()();
  TextColumn get languageId =>
      text().references(Languages, #id, onDelete: KeyAction.cascade)();
  TextColumn get refType => text()(); // lexeme|character|grammar
  TextColumn get refId => text()();
  IntColumn get masteryRung =>
      integer().withDefault(const Constant(1))();
  RealColumn get ease =>
      real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get lapses => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {languageId, refType, refId}
      ];
}

class ReviewLog extends Table {
  TextColumn get id => text()();
  TextColumn get learnItemId =>
      text().references(LearnItems, #id, onDelete: KeyAction.cascade)();
  IntColumn get rung => integer()();
  TextColumn get result => text()(); // again|hard|good|easy
  DateTimeColumn get ts => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Create `lib/core/db/learning_db.dart`**

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'learning_db.g.dart';

final learningDbProvider = Provider<LearningDb>((ref) {
  final db = LearningDb();
  ref.onDispose(db.close);
  return db;
});

@DriftDatabase(tables: [
  Concepts,
  Assets,
  ScriptProfiles,
  Languages,
  Lexemes,
  Characters,
  CharComponents,
  CanDoGoals,
  GrammarPoints,
  Sentences,
  LearnItems,
  ReviewLog,
])
class LearningDb extends _$LearningDb {
  LearningDb() : super(_openConnection());

  LearningDb.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'learning.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 3: Run build_runner to generate `learning_db.g.dart`**

```bash
cd /home/uli/Projects/nihongo && dart run build_runner build --delete-conflicting-outputs
```
Expected: exits 0, generates `lib/core/db/learning_db.g.dart`. Fix any errors before continuing.

- [ ] **Step 4: Write test that the DB opens and is empty**

Create `test/core/db/learning_db_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';

void main() {
  late LearningDb db;

  setUp(() {
    db = LearningDb.forTesting();
  });

  tearDown(() async => db.close());

  test('fresh DB has no languages', () async {
    final rows = await db.select(db.languages).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no concepts', () async {
    final rows = await db.select(db.concepts).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no learn_items', () async {
    final rows = await db.select(db.learnItems).get();
    expect(rows, isEmpty);
  });
}
```

- [ ] **Step 5: Run test to confirm it passes**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/db/learning_db_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/core/db/ test/core/db/
git commit -m "feat(phase0): new LearningDb with 11-table Drift schema"
```

---

### Task 3: JA seed pack

**Files:**
- Create: `lib/packs/ja/ja_seed.dart`
- Modify: `test/core/db/learning_db_test.dart` (add seed tests)

- [ ] **Step 1: Add failing seed tests to `test/core/db/learning_db_test.dart`**

Add the import at the top of the file:
```dart
import 'package:nihongo_app/packs/ja/ja_seed.dart';
```

Add this group inside `main()`, after the existing tests:
```dart
  group('JA seed pack', () {
    test('creates exactly one language', () async {
      await seedJaPack(db);
      final rows = await db.select(db.languages).get();
      expect(rows.length, 1);
      expect(rows.first.name, 'Japanese');
    });

    test('script profile is syllabary with needsScriptTrack', () async {
      await seedJaPack(db);
      final rows = await db.select(db.scriptProfiles).get();
      expect(rows.length, 1);
      expect(rows.first.scriptType, 'syllabary');
      expect(rows.first.needsScriptTrack, isTrue);
      expect(rows.first.transliteration, 'romaji');
    });

    test('creates 5 concepts', () async {
      await seedJaPack(db);
      final rows = await db.select(db.concepts).get();
      expect(rows.length, 5);
    });

    test('creates 5 lexemes with correct written forms', () async {
      await seedJaPack(db);
      final rows = await db.select(db.lexemes).get();
      expect(rows.length, 5);
      final forms = rows.map((l) => l.writtenForm).toSet();
      expect(forms, containsAll({'犬', '猫', '水', '食べる', '何'}));
    });

    test('creates 5 hiragana vowel characters', () async {
      await seedJaPack(db);
      final rows = await db.select(db.characters).get();
      expect(rows.length, 5);
      final glyphs = rows.map((c) => c.glyph).toSet();
      expect(glyphs, containsAll({'あ', 'い', 'う', 'え', 'お'}));
    });

    test('seeding twice is idempotent', () async {
      await seedJaPack(db);
      await seedJaPack(db);
      final langs = await db.select(db.languages).get();
      expect(langs.length, 1);
      final concepts = await db.select(db.concepts).get();
      expect(concepts.length, 5);
    });
  });
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/db/learning_db_test.dart
```
Expected: FAIL — `seedJaPack` not found.

- [ ] **Step 3: Create `lib/packs/ja/ja_seed.dart`**

```dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';

Future<void> seedJaPack(LearningDb db) async {
  await db.transaction(() async {
    await db.into(db.scriptProfiles).insertOnConflictUpdate(
          ScriptProfilesCompanion(
            id: const Value('sp_ja_kana'),
            scriptType: const Value('syllabary'),
            direction: const Value('ltr'),
            decomposability: const Value('atomic'),
            positionalForms: const Value(false),
            toneSystem: const Value('pitchAccent'),
            needsScriptTrack: const Value(true),
            transliteration: const Value('romaji'),
            inputMethodsJson: Value(jsonEncode(['keyboard', 'ime'])),
          ),
        );

    await db.into(db.languages).insertOnConflictUpdate(
          LanguagesCompanion(
            id: const Value('lang_ja'),
            name: const Value('Japanese'),
            scriptProfileId: const Value('sp_ja_kana'),
            ttsVoice: const Value('ja-JP'),
            enabled: const Value(true),
          ),
        );

    final conceptRows = <(String, String, String, String)>[
      ('concept_dog', 'dog', 'noun', 'image'),
      ('concept_cat', 'cat', 'noun', 'image'),
      ('concept_water', 'water', 'noun', 'image'),
      ('concept_eat', 'eat', 'verb', 'clip'),
      ('concept_what', 'what', 'pronoun', 'none'),
    ];
    for (final (id, gloss, pos, assetType) in conceptRows) {
      await db.into(db.concepts).insertOnConflictUpdate(
            ConceptsCompanion(
              id: Value(id),
              glossKey: Value(gloss),
              partOfSpeech: Value(pos),
              defaultAssetType: Value(assetType),
            ),
          );
    }

    final lexemeRows = <(String, String, String, String)>[
      ('lex_ja_dog', 'concept_dog', '犬', 'いぬ'),
      ('lex_ja_cat', 'concept_cat', '猫', 'ねこ'),
      ('lex_ja_water', 'concept_water', '水', 'みず'),
      ('lex_ja_eat', 'concept_eat', '食べる', 'たべる'),
      ('lex_ja_what', 'concept_what', '何', 'なに'),
    ];
    for (final (id, conceptId, form, reading) in lexemeRows) {
      await db.into(db.lexemes).insertOnConflictUpdate(
            LexemesCompanion(
              id: Value(id),
              languageId: const Value('lang_ja'),
              conceptId: Value(conceptId),
              writtenForm: Value(form),
              reading: Value(reading),
              cefrBand: const Value('A1'),
            ),
          );
    }

    final charRows = <(String, String, List<String>, String)>[
      ('char_ja_a', 'あ', ['a'], 'vowel a'),
      ('char_ja_i', 'い', ['i'], 'vowel i'),
      ('char_ja_u', 'う', ['u'], 'vowel u'),
      ('char_ja_e', 'え', ['e'], 'vowel e'),
      ('char_ja_o', 'お', ['o'], 'vowel o'),
    ];
    for (final (id, glyph, readings, meaning) in charRows) {
      await db.into(db.characters).insertOnConflictUpdate(
            CharactersCompanion(
              id: Value(id),
              languageId: const Value('lang_ja'),
              glyph: Value(glyph),
              readingsJson: Value(jsonEncode(readings)),
              meaning: Value(meaning),
            ),
          );
    }

    await db.into(db.canDoGoals).insertOnConflictUpdate(
          CanDoGoalsCompanion(
            id: const Value('cando_ja_a1_kana'),
            languageId: const Value('lang_ja'),
            cefrBand: const Value('A1'),
            description:
                const Value('I can read and write hiragana vowels'),
          ),
        );
  });
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
cd /home/uli/Projects/nihongo && flutter test test/core/db/learning_db_test.dart
```
Expected: All 9 tests PASS (3 empty-DB + 6 seed).

- [ ] **Step 5: Commit**

```bash
git add lib/packs/ test/core/db/learning_db_test.dart
git commit -m "feat(phase0): JA seed pack — 5 concepts, 5 lexemes, 5 hiragana, idempotent"
```

---

### Task 4: Wire LearningDb at app startup

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Replace `lib/main.dart` with seeded version**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/learning_db.dart';
import 'core/purchases_service.dart';
import 'core/tts_service.dart';
import 'features/language_select/language_select_screen.dart';
import 'packs/ja/ja_seed.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('active_language') ?? 'ja';

  await TtsService.instance.init(locale: _ttsLocaleForCode(savedLang));

  try {
    await PurchasesService.init();
  } catch (_) {}

  final learningDb = LearningDb();
  final existingLangs = await learningDb.select(learningDb.languages).get();
  if (existingLangs.isEmpty) {
    await seedJaPack(learningDb);
  }

  runApp(
    ProviderScope(
      overrides: [
        activeLanguageProvider.overrideWith((ref) => savedLang),
        learningDbProvider.overrideWithValue(learningDb),
      ],
      child: const NihongoApp(),
    ),
  );
}

String _ttsLocaleForCode(String code) {
  switch (code) {
    case 'ko': return 'ko-KR';
    case 'es': return 'es-ES';
    case 'zh': return 'zh-CN';
    default: return 'ja-JP';
  }
}
```

- [ ] **Step 2: Run `flutter analyze`**

```bash
cd /home/uli/Projects/nihongo && flutter analyze
```
Expected: 0 errors. Fix any reported issues before continuing.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(phase0): seed LearningDb with JA pack on first launch"
```

---

### Task 5: Final verification

- [ ] **Step 1: Run full test suite**

```bash
cd /home/uli/Projects/nihongo && flutter test
```
Expected: All tests PASS (existing widget_test + 4 script_profile + 9 learning_db).

- [ ] **Step 2: Run flutter analyze**

```bash
cd /home/uli/Projects/nihongo && flutter analyze
```
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Confirm git is clean**

```bash
git status
```
Expected: `nothing to commit, working tree clean`.
