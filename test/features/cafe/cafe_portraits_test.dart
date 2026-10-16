import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_portraits.dart';
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/story/episode.dart';

void main() {
  test('portraitPath baut den Namen aus Gast, Stimmung, Nummer, Format', () {
    expect(
        portraitPath(
            CafeGuest.schulkind, CafeMood.abwinkend, 3, PanelFormat.portrait),
        'assets/comic/cafe/ansprache/schulkind_abwinkend_3_hoch.jpg');
  });
  test('portraitVariant ist deterministisch, 1-basiert und stabil', () {
    final a = portraitVariant('lex_ja_ame', 'folge_01', 5);
    expect(a, portraitVariant('lex_ja_ame', 'folge_01', 5));
    expect(a, inInclusiveRange(1, 5));
    expect(portraitVariant('x', 'y', 0), 1);
  });
  test('Rückfallkette: gewünscht → fragend → anderes Format → null', () {
    final files = {
      'wirtin_fragend': {
        'quer': [1, 2],
        'hoch': [2]
      },
      'wirtin_zufrieden': {
        'quer': [1]
      },
    };
    String? asset(CafeMood m, int n, PanelFormat f) =>
        resolvePortraitIn(files, CafeGuest.wirtin, m, n, f)?.asset;
    // (1) gewünscht
    expect(asset(CafeMood.zufrieden, 1, PanelFormat.landscape),
        endsWith('wirtin_zufrieden_1_quer.jpg'));
    // (2) fragend im gleichen Format schlägt gewünscht im anderen Format
    final f2 = resolvePortraitIn(
        files, CafeGuest.wirtin, CafeMood.zufrieden, 2, PanelFormat.portrait)!;
    expect(f2.asset, endsWith('wirtin_fragend_2_hoch.jpg'));
    expect(f2.letterbox, isFalse);
    // (3) gewünscht im anderen Format, wenn fragend im gleichen fehlt
    final other = resolvePortraitIn(
        files, CafeGuest.wirtin, CafeMood.zufrieden, 1, PanelFormat.portrait)!;
    expect(other.asset, endsWith('wirtin_zufrieden_1_quer.jpg'));
    expect(other.letterbox, isTrue);
    // (2) abwinkend fehlt ganz, fragend_2_quer ist da
    final f4 = resolvePortraitIn(
        files, CafeGuest.wirtin, CafeMood.abwinkend, 2, PanelFormat.landscape)!;
    expect(f4.asset, endsWith('wirtin_fragend_2_quer.jpg'));
    expect(f4.letterbox, isFalse);
    // (4) fragend im anderen Format
    final f4b = resolvePortraitIn({
      'wirtin_fragend': {
        'quer': [3]
      }
    }, CafeGuest.wirtin, CafeMood.abwinkend, 3, PanelFormat.portrait)!;
    expect(f4b.asset, endsWith('wirtin_fragend_3_quer.jpg'));
    expect(f4b.letterbox, isTrue);
    // (5) nichts da
    expect(
        resolvePortraitIn(files, CafeGuest.vielredner, CafeMood.fragend, 1,
            PanelFormat.portrait),
        isNull);
  });
  test('resolvePortrait fällt auf die Stammplatz-Szene zurück', () {
    final c = resolvePortrait(CafeGuest.vielredner, CafeMood.fragend, 1,
        PanelFormat.portrait, CafeLight.tag);
    expect(c.isPortrait, isFalse);
    expect(c.asset, sceneAsset(CafeMotif.vielrednerZeitung, CafeLight.tag));
  });
}
