import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/dictionary.dart';
import 'package:nihongo_app/features/story/dictionary_groups.dart';
import 'package:nihongo_app/features/story/dictionary_sheet.dart';

import '../../fixtures/story/folge_01_dictionary_fixture.dart';

const _entries = [
  DictionaryEntry(
    id: 'lex_a',
    headword: 'あめ',
    meaning: 'Regen',
    marginNote: 'unleserliche Notiz',
  ),
  DictionaryEntry(id: 'lex_b', headword: 'かさ', meaning: 'Schirm'),
];

void main() {
  test('every Folge 01 dictionary entry is reachable via some gojūon group',
      () {
    for (final entry in folge01DictionaryEntries) {
      final reachable = dictionaryGroups.any(
        (g) => g.characters.contains(entry.headword[0]),
      );
      expect(
        reachable,
        isTrue,
        reason:
            '${entry.headword} (id: ${entry.id}) is not reachable via any dictionaryGroups row',
      );
    }
  });

  testWidgets('shows the gojūon group list first, not individual entries',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    expect(find.text('あ行'), findsOneWidget);
    expect(find.text('か行'), findsOneWidget);
    expect(find.text('あめ'), findsNothing);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets(
      'tapping a group shows only entries whose headword starts in that row',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();

    expect(find.text('あめ'), findsOneWidget);
    expect(find.text('かさ'), findsNothing);
  });

  testWidgets('the back button returns from entries to the group list',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();
    expect(find.text('あめ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dictionary-back')));
    await tester.pump();

    expect(find.text('あ行'), findsOneWidget);
    expect(find.text('あめ'), findsNothing);
  });

  testWidgets('a known entry shows its meaning; an unknown entry does not',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {'lex_a'}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();
    expect(find.text('Regen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dictionary-back')));
    await tester.pump();
    await tester.tap(find.text('か行'));
    await tester.pump();
    expect(find.text('Schirm'), findsNothing);
    expect(find.text('かさ'), findsOneWidget);
  });

  testWidgets('a margin note is always visible and has no gesture handler',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    await tester.tap(find.text('あ行'));
    await tester.pump();

    expect(find.text('unleserliche Notiz'), findsOneWidget);

    // Structural check: no GestureDetector wraps the note at all — this
    // would catch a future regression (e.g. a no-op GestureDetector added
    // "for consistency") that the behavioral check below cannot.
    expect(
      find.ancestor(
        of: find.text('unleserliche Notiz'),
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );

    // Behavioral check: tapping the note is a no-op — nothing new appears,
    // nothing throws.
    await tester.tap(find.text('unleserliche Notiz'));
    await tester.pump();
    expect(find.text('unleserliche Notiz'), findsOneWidget);
  });

  testWidgets(
      'an entry whose headword matches no gojūon row appears under "Weitere" instead of disappearing',
      (tester) async {
    const entries = [
      DictionaryEntry(id: 'lex_katakana', headword: 'コーヒー', meaning: 'Kaffee'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: entries, knownIds: const {'lex_katakana'}),
      ),
    ));

    expect(find.text('Weitere'), findsOneWidget);
    expect(find.text('コーヒー'), findsNothing);

    await tester.tap(find.text('Weitere'));
    await tester.pump();

    expect(find.text('コーヒー'), findsOneWidget);
    expect(find.text('Kaffee'), findsOneWidget);
  });

  testWidgets(
      'the "Weitere" group does not appear when every entry is reachable via a normal row',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: _entries, knownIds: const {}),
      ),
    ));

    expect(find.text('Weitere'), findsNothing);
  });

  testWidgets('an entry with an empty headword does not crash and lands in "Weitere"',
      (tester) async {
    const entries = [
      DictionaryEntry(id: 'lex_empty', headword: '', meaning: 'malformed'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(entries: entries, knownIds: const {}),
      ),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('Weitere'), findsOneWidget);
  });

  testWidgets(
      'reading the real Folge 01 fixture: すみません is unknown and shows no meaning',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(
          entries: folge01DictionaryEntries,
          knownIds: const {},
        ),
      ),
    ));

    await tester.tap(find.text('さ行'));
    await tester.pump();

    expect(find.text('すみません'), findsOneWidget);
    expect(find.text('Entschuldigung / Verzeihung'), findsNothing);
  });

  testWidgets(
      'reading the real Folge 01 fixture: どうぞ is reachable via た行 (voiced row)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DictionarySheet(
          entries: folge01DictionaryEntries,
          knownIds: const {'lex_ja_douzo'},
        ),
      ),
    ));

    await tester.tap(find.text('た行'));
    await tester.pump();

    expect(find.text('どうぞ'), findsOneWidget);
    expect(find.text('bitte / hier'), findsOneWidget);
  });
}
