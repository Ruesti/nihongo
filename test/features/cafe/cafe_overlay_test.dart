import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_overlay.dart';

Widget app({required Widget child}) => MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          Container(),
          CafeOverlay(
            bubble: const GuestBubble(
                name: 'Wirtin', line: 'いらっしゃいませ', tail: TailDirection.up),
            child: child,
          ),
        ]),
      ),
    );

void setSize(WidgetTester t, Size s) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
}

void main() {
  const key = ValueKey('cafe-overlay');

  testWidgets('hoch: unten, volle Breite, höchstens halbe Höhe', (t) async {
    setSize(t, const Size(400, 1400));
    await t.pumpWidget(app(child: const SizedBox(height: 2000)));
    final r = t.getRect(find.byKey(key));
    expect(r.width, 400);
    expect(r.height, lessThanOrEqualTo(700));
    expect(r.bottom, 1400);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('hoch: kurzer Inhalt schrumpft die Fläche', (t) async {
    setSize(t, const Size(400, 1400));
    await t.pumpWidget(app(child: const SizedBox(height: 100)));
    final r = t.getRect(find.byKey(key));
    expect(r.height, lessThan(700));
    expect(r.bottom, 1400);
    expect(r.width, 400);
  });

  testWidgets('quer: rechts, ein Drittel, volle Höhe', (t) async {
    setSize(t, const Size(1400, 640));
    await t.pumpWidget(app(child: const SizedBox(height: 2000)));
    final r = t.getRect(find.byKey(key));
    expect(r.right, 1400);
    expect(r.height, 640);
    expect(r.width, closeTo(466.7, 1));
  });

  testWidgets('quer schmal: Breite wird auf 360 angehoben', (t) async {
    setSize(t, const Size(800, 400));
    await t.pumpWidget(app(child: const SizedBox(height: 2000)));
    expect(t.getRect(find.byKey(key)).width, 360);
  });

  testWidgets('Blase zeigt Name und Zeile', (t) async {
    setSize(t, const Size(400, 1400));
    await t.pumpWidget(app(child: const SizedBox(height: 100)));
    expect(t.widget<Text>(find.byKey(const ValueKey('cafe-station-name'))).data,
        'Wirtin');
    expect(
        t.widget<Text>(find.byKey(const ValueKey('cafe-station-voice'))).data,
        'いらっしゃいませ');
  });

  test('tailFor', () {
    expect(tailFor(Orientation.portrait), TailDirection.up);
    expect(tailFor(Orientation.landscape), TailDirection.left);
  });

  testWidgets('Zurück-Chip ruft onPressed', (t) async {
    var n = 0;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: CafeBackChip(onPressed: () => n++))));
    await t.tap(find.byKey(const ValueKey('cafe-back')));
    expect(n, 1);
  });
}
