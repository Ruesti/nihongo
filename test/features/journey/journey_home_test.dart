import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/journey_home.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the current chapter and a start CTA, no lesson grid',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [learningDbProvider.overrideWith((ref) => db)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: JourneyHome(),
      ),
    ));
    await tester.pumpAndSettle();

    // Calm chapter label + a single CTA; NOT the old "Lektionen" grid.
    expect(find.text('Kapitel 1'), findsOneWidget);
    expect(find.text('Los geht\'s'), findsOneWidget);
    expect(find.text('Lektionen'), findsNothing);
  });
}
