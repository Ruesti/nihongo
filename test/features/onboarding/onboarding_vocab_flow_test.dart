import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/onboarding/onboarding_flow.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('prior-knowledge path reaches the vocab check and marks a word known',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'x'));
    await db.into(db.concepts).insert(
        ConceptsCompanion.insert(id: 'c_cat', glossKey: 'cat', partOfSpeech: 'n'));
    await db.into(db.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_cat', languageId: 'lang_ja', conceptId: 'c_cat',
        writtenForm: '猫', reading: 'ねこ'));

    var finished = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingFlow(onFinished: () => finished = true),
      ),
    ));

    await tester.tap(find.text('Weiter')); // welcome
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter')); // method
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ich kann schon etwas')); // placement → startpoint
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weiter')); // startpoint (no kana checked) → vocab check
    await tester.pumpAndSettle();

    // Vocab check appears; confirm the word.
    expect(find.text('猫'), findsOneWidget);
    await tester.tap(find.text('Kenne ich'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    // The confirmed word is now a mastered learn-item (rung ≥ 3).
    final item = await db.getLearnItem('lang_ja:lexeme:lex_ja_cat');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(3));
  });
}
