import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/vocab_check.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  test('loadVocabCheckItems returns the seeded lexemes with meaning', () async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'x'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_cat', glossKey: 'cat', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_cat', languageId: 'lang_ja', conceptId: 'c_cat',
        writtenForm: '猫', reading: 'ねこ'));

    final items = await loadVocabCheckItems(db, 'lang_ja');
    expect(items, hasLength(1));
    expect(items.single.lexemeId, 'lex_ja_cat');
    expect(items.single.writtenForm, '猫');
    expect(items.single.meaning, 'cat');
  });

  testWidgets('confirming a word returns its lexemeId', (tester) async {
    List<String>? result;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VocabCheckStep(
        items: const [
          VocabCheckItem(
              lexemeId: 'lex_ja_cat', writtenForm: '猫', reading: 'ねこ', meaning: 'cat'),
        ],
        onDone: (known) => result = known,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kenne ich'));
    await tester.pumpAndSettle();

    expect(result, ['lex_ja_cat']);
  });
}
