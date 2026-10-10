import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/kana_keyboard.dart';

void main() {
  test('normalizeKana entfernt Leerzeichen und Satzzeichen', () {
    expect(normalizeKana(' あめ！ '), 'あめ');
    expect(normalizeKana('ここ、ここ。'), 'ここここ');
    expect(normalizeKana('あめ…'), 'あめ');
  });

  test('applyDakuten kreist か → が → か, は → ば → ぱ → は', () {
    expect(applyDakuten('か'), 'が');
    expect(applyDakuten('が'), 'か');
    expect(applyDakuten('は'), 'ば');
    expect(applyDakuten('ば'), 'ぱ');
    expect(applyDakuten('ぱ'), 'は');
    expect(applyDakuten('あ'), 'あ');
    expect(applyDakuten(''), '');
  });

  test('applySmall macht das letzte Zeichen klein und zurück', () {
    expect(applySmall('じよ'), 'じょ');
    expect(applySmall('じょ'), 'じよ');
    expect(applySmall('つ'), 'っ');
    expect(applySmall('か'), 'か');
  });

  testWidgets('だいじょうぶ lässt sich über das Raster tippen', (tester) async {
    var value = '';
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: KanaKeyboard(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    Future<void> tap(String key) async {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$key')));
      await tester.tap(find.byKey(ValueKey('kana-key-$key')));
      await tester.pump();
    }

    await tap('た');
    await tap('dakuten'); // だ
    await tap('い');
    await tap('し');
    await tap('dakuten'); // じ
    await tap('よ');
    await tap('small'); // ょ
    await tap('う');
    await tap('ふ');
    await tap('dakuten'); // ぶ
    expect(value, 'だいじょうぶ');

    await tap('backspace');
    expect(value, 'だいじょう');
  });

  testWidgets('auf einem 360-dp-Gerät passen alle zehn Spalten nebeneinander',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: KanaKeyboard(value: '', onChanged: (_) {}),
        ),
      ),
    ));
    final a = tester.getRect(find.byKey(const ValueKey('kana-key-あ')));
    final wa = tester.getRect(find.byKey(const ValueKey('kana-key-わ')));
    expect(wa.left, greaterThanOrEqualTo(0));
    expect(a.right, lessThanOrEqualTo(360));
    expect(a.width, lessThanOrEqualTo(KanaKeyboard.keyExtent));
  });

  testWidgets('breit genug: Tasten 38×38, Raster 5 × 38 hoch', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: KanaKeyboard(value: '', onChanged: (_) {})),
    ));
    final a = tester.getSize(find.byKey(const ValueKey('kana-key-あ')));
    expect(a, const Size(38, 38));
    final o = tester.getRect(find.byKey(const ValueKey('kana-key-お')));
    final top = tester.getRect(find.byKey(const ValueKey('kana-key-あ')));
    expect(o.bottom - top.top, 5 * 38);
  });
}
