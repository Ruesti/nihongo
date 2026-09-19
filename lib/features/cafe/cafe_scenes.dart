import 'cafe_occupancy.dart';

/// Die Szenen-Bibliothek des Cafés (Spec Café-Szenen-und-Stimmen §3.2/§5.3):
/// derselbe Raum im Licht der Stunde, die Gäste an ihren Stammplätzen und in
/// kleinen Momenten. Reine Funktionen über einer Tabelle — kein Zufall, kein
/// Dateisystem-Scan. Szenen sind Stimmung, kein Abrufreiz (I6 gilt für
/// Konzeptbilder) und kein Fortschritt (INV-10).
enum CafeLight { tag, regen, abend, nacht }

/// 06–17 Uhr Tag, 17–21 Abend, sonst Nacht. [rain] ersetzt nur den Tag
/// durch Regen — Abend und Nacht behalten ihr Licht (drinnen sieht man
/// nächtlichen Regen ohnehin nicht).
CafeLight lightFor(DateTime now, {bool rain = false}) {
  final h = now.hour;
  if (h >= 6 && h < 17) return rain ? CafeLight.regen : CafeLight.tag;
  if (h >= 17 && h < 21) return CafeLight.abend;
  return CafeLight.nacht;
}

/// Die Motive. Je Gast in der Reihenfolge Stammplatz, Moment 1, Moment 2 —
/// [turnScene] rotiert darüber. [stem] ist der Dateistamm.
enum CafeMotif {
  leer('leer', null),
  wirtinTresen('wirtin_tresen', CafeGuest.wirtin),
  wirtinTee('wirtin_tee', CafeGuest.wirtin),
  wirtinTisch('wirtin_tisch', CafeGuest.wirtin),
  schulkindNische('schulkind_nische', CafeGuest.schulkind),
  schulkindHausaufgaben('schulkind_hausaufgaben', CafeGuest.schulkind),
  schulkindKakao('schulkind_kakao', CafeGuest.schulkind),
  vielrednerZeitung('vielredner_zeitung', CafeGuest.vielredner),
  vielrednerGefaltet('vielredner_gefaltet', CafeGuest.vielredner),
  vielrednerFenster('vielredner_fenster', CafeGuest.vielredner),
  gleichaltrigeKaffee('gleichaltrige_kaffee', CafeGuest.gleichaltrige),
  gleichaltrigeHaende('gleichaltrige_haende', CafeGuest.gleichaltrige),
  gleichaltrigeFenster('gleichaltrige_fenster', CafeGuest.gleichaltrige);

  final String stem;
  final CafeGuest? guest;
  const CafeMotif(this.stem, this.guest);
}

/// Stammplatz je Gast — das Bild, auf das alles zurückfällt.
CafeMotif stammplatzOf(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => CafeMotif.wirtinTresen,
      CafeGuest.schulkind => CafeMotif.schulkindNische,
      CafeGuest.vielredner => CafeMotif.vielrednerZeitung,
      CafeGuest.gleichaltrige => CafeMotif.gleichaltrigeKaffee,
    };

const String cafeSceneDir = 'assets/comic/cafe';

/// Was wirklich gebündelt ist. Einzige Wahrheit; `cafe_scenes_assets_test`
/// erzwingt Tabelle ⇔ Dateien. Wächst mit jedem Render-Schritt (Plan Bilder
/// Task 7/8).
const Map<CafeMotif, Set<CafeLight>> cafeSceneLibrary = {
  CafeMotif.leer: {CafeLight.tag},
  CafeMotif.wirtinTresen: {CafeLight.tag},
  CafeMotif.schulkindNische: {CafeLight.tag},
  CafeMotif.vielrednerZeitung: {CafeLight.tag},
  CafeMotif.gleichaltrigeKaffee: {CafeLight.tag},
};

String _path(CafeMotif motif, CafeLight light) =>
    '$cafeSceneDir/${motif.stem}_${light.name}.jpg';

bool hasScene(CafeMotif motif, CafeLight light) =>
    cafeSceneLibrary[motif]?.contains(light) ?? false;

/// Rückfallkette über einer beliebigen Tabelle (testbar ohne die echte):
/// gewünscht → Stammplatz des Gastes im Licht → Stammplatz bei Tag → `leer`
/// bei Tag. Liefert immer einen Pfad; ob die Datei existiert, sichert der
/// strukturelle Test, den Rest fängt der `errorBuilder` (nie Crash).
String sceneAssetIn(Map<CafeMotif, Set<CafeLight>> library, CafeMotif motif,
    CafeLight light) {
  bool has(CafeMotif m, CafeLight l) => library[m]?.contains(l) ?? false;
  if (has(motif, light)) return _path(motif, light);
  final guest = motif.guest;
  final home = guest == null ? CafeMotif.leer : stammplatzOf(guest);
  if (has(home, light)) return _path(home, light);
  if (has(home, CafeLight.tag)) return _path(home, CafeLight.tag);
  return _path(CafeMotif.leer, CafeLight.tag);
}

String sceneAsset(CafeMotif motif, CafeLight light) =>
    sceneAssetIn(cafeSceneLibrary, motif, light);

/// Szene über einer Frage: der [ordinal]-te Block dieses Sprechers zeigt
/// Stammplatz, Moment 1, Moment 2, … rotierend — ein Bild pro Block, nicht
/// pro Frage (Spec §3.3).
String turnScene(CafeGuest speaker, CafeLight light, int ordinal) {
  final motifs = CafeMotif.values.where((m) => m.guest == speaker).toList();
  return sceneAsset(motifs[ordinal % motifs.length], light);
}
