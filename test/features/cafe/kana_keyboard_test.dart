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
}
