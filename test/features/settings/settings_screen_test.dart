import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const noGerman = 'Auf diesem Gerät ist keine deutsche Stimme installiert.';

  Future<void> pumpCard(WidgetTester t, Future<bool> Function() hasGerman) =>
      t.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GuestVoiceCard(hasGerman: hasGerman)),
        ),
      );

  testWidgets('Schalter speichert cafe_voice_enabled', (t) async {
    SharedPreferences.setMockInitialValues({});
    await pumpCard(t, () async => true);
    await t.pumpAndSettle();
    expect(find.text('Gäste sprechen'), findsOneWidget);
    expect(find.text(noGerman), findsNothing);
    await t.tap(find.byKey(const ValueKey('settings-cafe-voice')));
    await t.pumpAndSettle();
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(CafeVoicePrefs.key), false);
  });

  testWidgets('Untertitel erscheint ohne deutsche Stimme', (t) async {
    SharedPreferences.setMockInitialValues({});
    await pumpCard(t, () async => false);
    await t.pumpAndSettle();
    expect(find.text(noGerman), findsOneWidget);
  });

  testWidgets('Plattformfehler heißt: kein Untertitel', (t) async {
    SharedPreferences.setMockInitialValues({});
    await pumpCard(t, () async => throw StateError('boom'));
    await t.pumpAndSettle();
    expect(find.text(noGerman), findsNothing);
  });
}
