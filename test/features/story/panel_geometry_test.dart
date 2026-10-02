import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/episode.dart' show PanelFormat;
import 'package:nihongo_app/features/story/panel_geometry.dart';

void main() {
  test('Format folgt der Schirmlage', () {
    expect(formatForSize(const Size(1080, 2340)), PanelFormat.portrait);
    expect(formatForSize(const Size(2340, 1080)), PanelFormat.landscape);
    expect(formatForSize(const Size(1000, 1000)), PanelFormat.landscape);
  });

  test('Seitenverhältnisse sind die Auslieferungsgrößen der Spec', () {
    expect(aspectOf(PanelFormat.landscape), closeTo(1920 / 1072, 1e-9));
    expect(aspectOf(PanelFormat.portrait), closeTo(1080 / 1936, 1e-9));
  });

  test('S23 hochkant: Hochbild füllt die Höhe, Überstand links/rechts symmetrisch',
      () {
    final r = coverRect(const Size(1080, 2340), kPortraitAspect);
    expect(r.height, closeTo(2340, 1e-6));
    expect(r.width, closeTo(2340 * kPortraitAspect, 1e-6)); // ≈ 1305,4
    expect(r.left, closeTo((1080 - r.width) / 2, 1e-6)); // ≈ −112,7
    expect(r.top, closeTo(0, 1e-9));
    expect(r.center.dx, closeTo(540, 1e-6));
  });

  test('S23 quer: Querbild füllt die Breite, Überstand oben/unten symmetrisch',
      () {
    final r = coverRect(const Size(2340, 1080), kLandscapeAspect);
    expect(r.width, closeTo(2340, 1e-6));
    expect(r.height, closeTo(2340 / kLandscapeAspect, 1e-6)); // ≈ 1306,5
    expect(r.top, closeTo((1080 - r.height) / 2, 1e-6)); // ≈ −113,3
    expect(r.left, closeTo(0, 1e-9));
  });

  test('Tablet 4:3 quer: Querbild füllt die Höhe, Überstand seitlich', () {
    final r = coverRect(const Size(1600, 1200), kLandscapeAspect);
    expect(r.height, closeTo(1200, 1e-6));
    expect(r.width, closeTo(1200 * kLandscapeAspect, 1e-6));
    expect(r.left, lessThan(0));
  });

  test(
      'containRect: Hochschirm mit Querbild wird eingepasst (Letterbox), '
      'Balken oben/unten', () {
    final r = containRect(const Size(1080, 2340), kLandscapeAspect);
    expect(r.width, closeTo(1080, 1e-6));
    expect(r.height, closeTo(1080 / kLandscapeAspect, 1e-6)); // ≈ 603
    expect(r.left, closeTo(0, 1e-9));
    expect(r.top, closeTo(868.5, 0.5));
  });

  test(
      'containRect: Querschirm mit Hochbild wird eingepasst (Letterbox), '
      'Balken links/rechts', () {
    final r = containRect(const Size(2340, 1080), kPortraitAspect);
    expect(r.height, closeTo(1080, 1e-6));
    expect(r.width, closeTo(1080 * kPortraitAspect, 1e-6)); // ≈ 602,5
    expect(r.top, closeTo(0, 1e-9));
    expect(r.left, closeTo(868.7, 0.5));
  });

  test('normiertes Rechteck wird relativ zum Bildrechteck abgebildet', () {
    final image = Rect.fromLTWH(-100, 0, 1300, 2340);
    final hit = mapToScreen(const Rect.fromLTWH(0.1, 0.5, 0.4, 0.1), image);
    expect(hit.left, closeTo(-100 + 130, 1e-6));
    expect(hit.top, closeTo(1170, 1e-6));
    expect(hit.width, closeTo(520, 1e-6));
    expect(hit.height, closeTo(234, 1e-6));
  });
}
