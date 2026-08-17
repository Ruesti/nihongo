import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/encounter/encounter_view.dart';
import 'package:nihongo_app/features/review/review_screen.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('a rung-0 due item shows the encounter, not a recognition test',
      (tester) async {
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    await db.into(db.scriptProfiles).insert(ScriptProfilesCompanion.insert(
        id: 'sp', scriptType: 'syllabary', decomposability: 'atomic'));
    await db.into(db.languages).insert(LanguagesCompanion.insert(
        id: 'lang_ja', name: 'JA', scriptProfileId: 'sp', ttsVoice: 'ja-JP'));
    await db.into(db.characters).insert(CharactersCompanion.insert(
        id: 'char_a',
        languageId: 'lang_ja',
        glyph: 'あ',
        readingsJson: jsonEncode(['a']),
        meaning: 'a'));
    await db.addLearnItemAtRung('lang_ja', RefType.character, 'char_a', rung: 0);

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReviewScreen(lang: 'ja'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(EncounterView), findsOneWidget);
    expect(find.text('あ'), findsOneWidget);
    // The recognition prompt / grade buttons must NOT be present.
    expect(find.text('Nochmal'), findsNothing);
  });
}
