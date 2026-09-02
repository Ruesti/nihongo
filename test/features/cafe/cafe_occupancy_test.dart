import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';

void main() {
  group('guestForRung', () {
    test('maps rung bands to guests, folding rung 0 into the Wirtin', () {
      expect(guestForRung(0), CafeGuest.wirtin);
      expect(guestForRung(1), CafeGuest.wirtin);
      expect(guestForRung(2), CafeGuest.wirtin);
      expect(guestForRung(3), CafeGuest.schulkind);
      expect(guestForRung(4), CafeGuest.vielredner);
      expect(guestForRung(5), CafeGuest.gleichaltrige);
    });
  });

  group('CafeOccupancy.fromDueItems (via a real due queue)', () {
    late LearningDb db;
    setUp(() => db = LearningDb.forTesting());
    tearDown(() async => db.close());

    Future<void> seedDue(String id, int rung) =>
        db.addLearnItemAtRung('lang_ja', RefType.lexeme, id, rung: rung);

    test('nothing due → empty café (no guests)', () async {
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).isEmpty, isTrue);
    });

    test('one due item at rung 3 → only the Schulkind is present', () async {
      await seedDue('lex_a', 3);
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).present, {CafeGuest.schulkind});
    });

    test('due items across rungs → exactly the matching guests present',
        () async {
      await seedDue('lex_a', 1); // Wirtin
      await seedDue('lex_b', 3); // Schulkind
      await seedDue('lex_c', 5); // Gleichaltrige
      final due = await db.getDueItems('lang_ja', limit: 500);
      final occ = CafeOccupancy.fromDueItems(due);
      expect(occ.present,
          {CafeGuest.wirtin, CafeGuest.schulkind, CafeGuest.gleichaltrige});
      expect(occ.present.contains(CafeGuest.vielredner), isFalse);
    });

    test('a rung-0 item (freshly introduced) puts the Wirtin in the café',
        () async {
      await seedDue('lex_new', 0);
      final due = await db.getDueItems('lang_ja', limit: 500);
      expect(CafeOccupancy.fromDueItems(due).present, {CafeGuest.wirtin});
    });
  });
}
