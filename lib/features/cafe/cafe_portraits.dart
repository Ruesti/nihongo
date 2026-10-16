import '../story/episode.dart';
import 'cafe_occupancy.dart';
import 'cafe_portrait_library.g.dart';
import 'cafe_scenes.dart';

/// Stimmung des Gasts in einem Ansprache-Bild.
enum CafeMood { fragend, zufrieden, abwinkend }

/// Ordner der Ansprache-Bilder.
const String cafePortraitDir = 'assets/comic/cafe/ansprache';

/// Dateiname-Anfang des Gasts (= Enum-Name).
String portraitStem(CafeGuest g) => g.name;

/// Format im Dateinamen: `quer` (landscape) oder `hoch` (portrait).
String formatKey(PanelFormat f) => switch (f) {
      PanelFormat.landscape => 'quer',
      PanelFormat.portrait => 'hoch',
    };

/// Asset-Pfad für Gast, Stimmung, Variantennummer und Format.
String portraitPath(CafeGuest g, CafeMood m, int n, PanelFormat f) =>
    '$cafePortraitDir/${portraitStem(g)}_${m.name}_${n}_${formatKey(f)}.jpg';

/// Vorhandene Variantennummern laut Tabelle (leer, wenn es keine gibt).
List<int> availableVariants(Map<String, Map<String, List<int>>> files,
        CafeGuest g, CafeMood m, PanelFormat f) =>
    files['${portraitStem(g)}_${m.name}']?[formatKey(f)] ?? const [];

/// Wählt deterministisch eine Variante 1…[available]; ohne Auswahl 1.
int portraitVariant(String itemId, String visitKey, int available) =>
    available <= 0 ? 1 : ('$itemId|$visitKey'.hashCode.abs() % available) + 1;

/// Ergebnis der Bildwahl.
class PortraitChoice {
  final String asset;

  /// Bild passt nicht zum gewünschten Format und wird mit Rand gezeigt.
  final bool letterbox;

  /// false = Stammplatz-Szene oder Fläche statt Ansprache-Bild.
  final bool isPortrait;

  const PortraitChoice(
      {required this.asset, required this.letterbox, this.isPortrait = true});
}

PanelFormat _other(PanelFormat f) => f == PanelFormat.landscape
    ? PanelFormat.portrait
    : PanelFormat.landscape;

/// Rückfallkette (gleiche Nummer): gewünscht → fragend (gleiches Format) →
/// gewünscht im anderen Format → fragend im anderen Format → null. Ein
/// richtig formatiertes Bild schlägt ein richtig reagierendes; ein anderes
/// Format wird mit Rand gezeigt.
PortraitChoice? resolvePortraitIn(Map<String, Map<String, List<int>>> files,
    CafeGuest g, CafeMood m, int n, PanelFormat f) {
  bool has(CafeMood mood, PanelFormat fmt) =>
      availableVariants(files, g, mood, fmt).contains(n);
  PortraitChoice pick(CafeMood mood, PanelFormat fmt, bool letterbox) =>
      PortraitChoice(
          asset: portraitPath(g, mood, n, fmt), letterbox: letterbox);

  final o = _other(f);
  if (has(m, f)) return pick(m, f, false);
  if (has(CafeMood.fragend, f)) return pick(CafeMood.fragend, f, false);
  if (has(m, o)) return pick(m, o, true);
  if (has(CafeMood.fragend, o)) return pick(CafeMood.fragend, o, true);
  return null;
}

/// Wie [resolvePortraitIn], fällt aber auf die Stammplatz-Szene zurück.
PortraitChoice resolvePortrait(
    CafeGuest g, CafeMood m, int n, PanelFormat f, CafeLight light,
    {Map<String, Map<String, List<int>>> files = cafePortraitFiles}) {
  return resolvePortraitIn(files, g, m, n, f) ??
      PortraitChoice(
          asset: sceneAsset(stammplatzOf(g), light),
          letterbox: true,
          isPortrait: false);
}
