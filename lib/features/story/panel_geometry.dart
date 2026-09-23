import 'dart:ui';

import 'episode.dart' show PanelFormat;

/// Seitenverhältnisse der ausgelieferten Bilder (Spec Manga-Vollbild §3.1).
/// Konstanten, damit der Reader kein Bild dekodieren muss, um Tippflächen
/// zu platzieren.
const double kLandscapeAspect = 1920 / 1072;
const double kPortraitAspect = 1080 / 1936;

double aspectOf(PanelFormat format) =>
    format == PanelFormat.portrait ? kPortraitAspect : kLandscapeAspect;

/// Höher als breit → Hochformat; quadratisch zählt als quer.
PanelFormat formatForSize(Size screen) =>
    screen.height > screen.width ? PanelFormat.portrait : PanelFormat.landscape;

/// Rechteck, das ein Bild mit Seitenverhältnis [aspect] (Breite/Höhe) unter
/// `BoxFit.cover` auf [screen] einnimmt: eine Achse füllt den Schirm genau,
/// die andere steht symmetrisch über (Beschnitt gleichmäßig an beiden
/// Rändern).
Rect coverRect(Size screen, double aspect) {
  final heightIfWidthFills = screen.width / aspect;
  final double w, h;
  if (heightIfWidthFills >= screen.height) {
    w = screen.width;
    h = heightIfWidthFills;
  } else {
    h = screen.height;
    w = screen.height * aspect;
  }
  return Rect.fromLTWH((screen.width - w) / 2, (screen.height - h) / 2, w, h);
}

/// Bildet ein normiertes Rechteck (0..1 im Bild) in Schirmkoordinaten ab.
Rect mapToScreen(Rect normalized, Rect imageRect) => Rect.fromLTWH(
      imageRect.left + normalized.left * imageRect.width,
      imageRect.top + normalized.top * imageRect.height,
      normalized.width * imageRect.width,
      normalized.height * imageRect.height,
    );
