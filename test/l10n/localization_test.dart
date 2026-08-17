import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/l10n/app_localizations.dart';

Widget _app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Text(AppLocalizations.of(context)!.welcomeTitle),
      ),
    );

void main() {
  testWidgets('resolves German string for de locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('de')));
    expect(find.text('Willkommen.'), findsOneWidget);
  });

  testWidgets('resolves English string for en locale', (tester) async {
    await tester.pumpWidget(_app(const Locale('en')));
    expect(find.text('Welcome.'), findsOneWidget);
  });

  test('both locales are supported', () {
    final codes =
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(codes.containsAll({'en', 'de'}), isTrue);
  });
}
