import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/lesson_step_screen.dart';
import 'package:nihongo_app/features/journey/trace_practice.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('a character with a stroke asset shows the trace beat after the encounter',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a',
        strokeOrderAssetId: const Value('assets/kanji_svg/3042.svg')));

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
          onDone: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Encounter first (glyph + Verstanden). Tap it → trace beat appears.
    expect(find.text('あ'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(TracePractice), findsOneWidget);
  });

  testWidgets(
      'a fast double-tap on "Weiter" does not skip the trace beat (regression)',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_ja_a', languageId: 'lang_ja', glyph: 'あ',
        readingsJson: jsonEncode(['a']), meaning: 'a',
        strokeOrderAssetId: const Value('assets/kanji_svg/3042.svg')));

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

    expect(find.text('あ'), findsOneWidget);
    // Fast double-tap: no pump() between the two taps, mirroring an
    // impatient learner tapping "Weiter" twice before the frame that
    // flips _tracing to true has actually rendered. Without the
    // _advancing guard held across the transition, the second tap would
    // re-enter _next() while _tracing is still false, skip the trace
    // beat entirely, and fall straight through to markEncountered.
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.tap(find.byKey(const ValueKey('encounter-next')));
    await tester.pump();
    await tester.pump();

    // The trace beat must still be shown...
    expect(find.byType(TracePractice), findsOneWidget);
    // ...and the lesson must NOT have advanced past it yet.
    expect(done, isFalse);
    final item = await db.getLearnItem('lang_ja:character:char_ja_a');
    expect(item!.masteryRung, 0); // introduce()'d, not yet markEncountered()'d
  });
}
