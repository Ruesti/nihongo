import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/encounter/encounter_view.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/lesson_step_screen.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('runs the encounter for each item then calls onDone',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a'));

    var done = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonStepScreen(
          step: const LessonStep(
              id: 'l1', chapterRef: 'K1',
              characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
          languageId: 'lang_ja',
          onDone: () => done = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('あ'), findsOneWidget); // the encounter renders
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pumpAndSettle();

    expect(done, isTrue); // single item → onDone after its encounter
    // The item is now introduced (rung ≥ 1).
    final item = await db.getLearnItem('lang_ja:character:char_ja_a');
    expect(item, isNotNull);
    expect(item!.masteryRung, greaterThanOrEqualTo(1));
  });

  testWidgets('skips an already-learned item instead of freezing',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a'));
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_ja_a',
        rung: 3);

    var done = false;
    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonStepScreen(
          step: const LessonStep(
              id: 'l1', chapterRef: 'K1',
              characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
          languageId: 'lang_ja',
          onDone: () => done = true,
        ),
      ),
    ));
    // Not pumpAndSettle: the already-learned item is skipped inside _load()
    // without ever clearing `_loading`, so a CircularProgressIndicator (an
    // indeterminate, always-animating widget) is left in the tree once
    // onDone() fires — pumpAndSettle would never converge on that. Pump a
    // bounded number of times instead, which is enough for the real
    // (in-memory) DB awaits in _load() to unwind.
    for (var i = 0; i < 20 && !done; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }

    expect(done, isTrue);
    expect(find.byType(EncounterView), findsNothing);
  });

  testWidgets('double-tap on next fires onDone exactly once', (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp_ja_kana', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp_ja_kana', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a'));

    var doneCount = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LessonStepScreen(
          step: const LessonStep(
              id: 'l1', chapterRef: 'K1',
              characterIds: ['char_ja_a'], lexemeIds: [], grammarIds: []),
          languageId: 'lang_ja',
          onDone: () => doneCount++,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('あ'), findsOneWidget); // the encounter renders
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(doneCount, 1);
  });
}
