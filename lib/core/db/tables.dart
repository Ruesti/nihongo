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
  TextColumn get scriptType =>
      text()(); // alphabet|syllabary|logographic|abugida|abjad|hangul
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
  IntColumn get consecutiveCorrect =>
      integer().withDefault(const Constant(0))();

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
