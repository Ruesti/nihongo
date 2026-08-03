import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/due_in_reading.dart';

Future<void> _seedCard(
  MiningDb db, {
  required String lemma,
  required DateTime due,
  String languageCode = 'ja',
}) async {
  final vocabId = 'vocab:$languageCode:$lemma';
  await db.into(db.vocabItems).insert(VocabItemsCompanion.insert(
        id: vocabId,
        languageCode: languageCode,
        lemma: lemma,
        pos: 'n',
        createdAt: DateTime.now().toUtc(),
      ));
  await db.into(db.cards).insert(CardsCompanion.insert(
        id: 'card:$vocabId',
        vocabItemId: vocabId,
        due: due,
        lastReview: due,
      ));
}

Token _tok(String lemma) =>
    Token(surface: lemma, lemma: lemma, pos: 'n', charStart: 0, charEnd: 1);

void main() {
  late MiningDb db;
  late DueInReading due;

  setUp(() {
    db = MiningDb.forTesting();
    due = DueInReading(db);
  });
  tearDown(() => db.close());

  final now = DateTime.utc(2026, 6, 1);

  group('DueInReading.dueInView', () {
    test('surfaces a due card whose lemma is in the current tokens',
        () async {
      await _seedCard(db, lemma: '本', due: DateTime.utc(2026, 5, 1)); // overdue

      final result = await due.dueInView(
        languageCode: 'ja',
        tokens: [_tok('本'), _tok('を'), _tok('読む')],
        now: now,
      );

      expect(result.map((d) => d.lemma), ['本']);
    });

    test('does NOT surface a due card whose lemma is not in view', () async {
      await _seedCard(db, lemma: '猫', due: DateTime.utc(2026, 5, 1));

      final result = await due.dueInView(
        languageCode: 'ja',
        tokens: [_tok('本'), _tok('を')],
        now: now,
      );

      expect(result, isEmpty);
    });

    test('does NOT surface a card that is not yet due', () async {
      await _seedCard(db, lemma: '本', due: DateTime.utc(2026, 12, 1)); // future

      final result = await due.dueInView(
        languageCode: 'ja',
        tokens: [_tok('本')],
        now: now,
      );

      expect(result, isEmpty);
    });

    test('only surfaces cards for the requested language', () async {
      await _seedCard(db, lemma: 'libro', due: DateTime.utc(2026, 5, 1),
          languageCode: 'es');

      final result = await due.dueInView(
        languageCode: 'ja',
        tokens: [_tok('libro')],
        now: now,
      );

      expect(result, isEmpty);
    });

    test('orders multiple due items most-overdue first', () async {
      await _seedCard(db, lemma: '古い', due: DateTime.utc(2026, 1, 1)); // most overdue
      await _seedCard(db, lemma: '新しい', due: DateTime.utc(2026, 5, 20));

      final result = await due.dueInView(
        languageCode: 'ja',
        tokens: [_tok('新しい'), _tok('古い')],
        now: now,
      );

      expect(result.map((d) => d.lemma), ['古い', '新しい']);
    });

    test('empty token list yields nothing', () async {
      await _seedCard(db, lemma: '本', due: DateTime.utc(2026, 5, 1));

      final result =
          await due.dueInView(languageCode: 'ja', tokens: [], now: now);

      expect(result, isEmpty);
    });
  });
}
