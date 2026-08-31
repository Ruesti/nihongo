import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

void main() {
  testWidgets('journey strings resolve in de and en', (tester) async {
    for (final (locale, expected) in [
      (const Locale('de'), 'Los geht\'s'),
      (const Locale('en'), 'Let\'s go'),
    ]) {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) => Text(AppLocalizations.of(c)!.journeyStart),
        ),
      ));
      expect(find.text(expected), findsOneWidget);
    }
  });
}
