import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/bubble_gloss_card.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/episode.dart';

const _entries = [
  DictionaryEntry(id: 'lex_ja_eki', headword: 'えき', meaning: 'Bahnhof'),
  DictionaryEntry(id: 'lex_ja_kore', headword: 'これ', meaning: 'das hier'),
  DictionaryEntry(id: 'lex_ja_kasa', headword: 'かさ', meaning: 'Schirm'),
  DictionaryEntry(
      id: 'lex_ja_mise', headword: 'みせ', meaning: 'Laden, Geschäft'),
  DictionaryEntry(
      id: 'lex_ja_ame',
      headword: 'あめ',
      meaning: 'Regen',
      marginNote: 'unleserliche Notiz'),
];

StoryBubble _bubble(String text, List<Map<String, Object?>> tokens) =>
    StoryBubble.fromJson({
      'speakerId': 'mira',
      'text': text,
      'tokens': tokens,
    });

Future<List<String>> _pump(WidgetTester tester, StoryBubble bubble,
    {Set<String> known = const {}, VoidCallback? onShowAll}) async {
  final spoken = <String>[];
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: BubbleGlossCard(
        bubble: bubble,
        entries: _entries,
        knownIds: known,
        speak: (t) async => spoken.add(t),
        onShowAll: onShowAll,
      ),
    ),
  ));
  await tester.pump();
  return spoken;
}

void main() {
  testWidgets('zeigt je Wort der Blase eine Zeile: Japanisch + deutsche Bedeutung',
      (tester) async {
    final bubble = _bubble('これ？かさ？みせ！', [
      {'surface': 'これ', 'itemId': 'lex_ja_kore'},
      {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
      {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
    ]);
    await _pump(tester, bubble);

    expect(find.byKey(const ValueKey('bubble-gloss-card')), findsOneWidget);
    expect(find.text('これ？かさ？みせ！'), findsOneWidget);
    for (final id in ['lex_ja_kore', 'lex_ja_kasa', 'lex_ja_mise']) {
      expect(find.byKey(ValueKey('bubble-gloss-row-$id')), findsOneWidget);
    }
    expect(find.text('das hier'), findsOneWidget);
    expect(find.text('Schirm'), findsOneWidget);
    expect(find.text('Laden, Geschäft'), findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-gloss-empty')), findsNothing);
  });

  testWidgets('Lautsprecher je Zeile spricht das Wort, „anhören" die ganze Blase',
      (tester) async {
    final bubble = _bubble('これ？かさ？みせ！', [
      {'surface': 'これ', 'itemId': 'lex_ja_kore'},
      {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
      {'surface': 'みせ', 'itemId': 'lex_ja_mise'},
    ]);
    final spoken = await _pump(tester, bubble);

    await tester.tap(find.byKey(const ValueKey('bubble-gloss-speak-lex_ja_kasa')));
    await tester.pump();
    expect(spoken, ['かさ']);

    await tester.tap(find.byKey(const ValueKey('bubble-gloss-listen')));
    await tester.pump();
    expect(spoken, ['かさ', 'これ？かさ？みせ！']);
  });

  testWidgets('ein gelerntes Wort trägt den Haken, ein ungelerntes nicht',
      (tester) async {
    final bubble = _bubble('これ？かさ？', [
      {'surface': 'これ', 'itemId': 'lex_ja_kore'},
      {'surface': 'かさ', 'itemId': 'lex_ja_kasa'},
    ]);
    await _pump(tester, bubble, known: {'lex_ja_kasa'});

    expect(find.byKey(const ValueKey('bubble-gloss-known-lex_ja_kasa')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-gloss-known-lex_ja_kore')),
        findsNothing);
  });

  testWidgets('Kanji zeigt seine Lesung klein dazu', (tester) async {
    final bubble = _bubble('みなみまち駅', [
      {'surface': '駅', 'reading': 'えき', 'itemId': 'lex_ja_eki'},
    ]);
    await _pump(tester, bubble);

    expect(find.byKey(const ValueKey('bubble-gloss-row-lex_ja_eki')),
        findsOneWidget);
    expect(find.text('駅'), findsOneWidget);
    expect(find.text('えき'), findsOneWidget);
    expect(find.text('Bahnhof'), findsOneWidget);
  });

  testWidgets('doppelte und unbekannte Wörter: je Wort eine Zeile, '
      'Wörter ohne Eintrag fallen weg', (tester) async {
    final bubble = _bubble('あめ、あめ！', [
      {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
      {'surface': 'あめ', 'itemId': 'lex_ja_ame'},
      {'surface': 'ほげ', 'itemId': 'lex_ja_hoge'},
      {'surface': '！'},
    ]);
    await _pump(tester, bubble);

    expect(find.byKey(const ValueKey('bubble-gloss-row-lex_ja_ame')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-gloss-row-lex_ja_hoge')),
        findsNothing);
    expect(find.text('Regen'), findsOneWidget);
  });

  testWidgets('eine Blase ohne nachschlagbares Wort zeigt Text, „anhören" '
      'und einen Hinweis', (tester) async {
    final bubble = _bubble('……', const []);
    final spoken = await _pump(tester, bubble);

    expect(find.byKey(const ValueKey('bubble-gloss-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('bubble-gloss-listen')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bubble-gloss-listen')));
    expect(spoken, ['……']);
  });

  testWidgets('„alle Wörter der Folge" ruft onShowAll', (tester) async {
    var shown = 0;
    final bubble = _bubble('これ', [
      {'surface': 'これ', 'itemId': 'lex_ja_kore'},
    ]);
    await _pump(tester, bubble, onShowAll: () => shown++);

    await tester.tap(find.byKey(const ValueKey('bubble-gloss-all-words')));
    expect(shown, 1);
  });
}
