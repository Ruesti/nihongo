import '../../core/db/learning_db.dart';

/// The four café guests. Choosing a guest is choosing the difficulty rung
/// (brief §4.2): SM-2 picks the items, the guest picks the rung. Declared in
/// ascending-rung order so `CafeGuest.values` is a stable render order.
enum CafeGuest { wirtin, schulkind, vielredner, gleichaltrige }

/// Maps a due item's mastery rung to the guest who handles that band
/// (brief §4.2). Rung 0 (freshly introduced, not yet encountered) folds into
/// the Wirtin's gentle 1–2 band — she "zeigt und benennt Dinge", the right
/// home for a word's first café encounter.
CafeGuest guestForRung(int rung) {
  if (rung <= 2) return CafeGuest.wirtin;
  if (rung == 3) return CafeGuest.schulkind;
  if (rung == 4) return CafeGuest.vielredner;
  return CafeGuest.gleichaltrige; // rung 5 (and, defensively, any higher)
}

/// Who is present in the café right now. Occupancy IS the due indicator
/// (brief §4.3): a guest is present iff there is at least one due item in
/// their rung band. Nothing due → an empty [present] set → the café is calmly
/// empty (no count, no "0 due" message — that's the screen's job to render as
/// quiet emptiness, never a number).
class CafeOccupancy {
  final Set<CafeGuest> present;

  const CafeOccupancy(this.present);

  bool get isEmpty => present.isEmpty;

  factory CafeOccupancy.fromDueItems(List<LearnItem> dueItems) {
    return CafeOccupancy({
      for (final item in dueItems) guestForRung(item.masteryRung),
    });
  }
}
