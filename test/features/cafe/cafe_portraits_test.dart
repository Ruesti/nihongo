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
  test('Rückfallkette: Stimmung → fragend → anderes Format → null', () {
    final files = {
      'wirtin_fragend': {
        'quer': [1, 2],
        'hoch': [1]
      },
      'wirtin_zufrieden': {
        'quer': [1]
      },
    };
    expect(
        resolvePortraitIn(files, CafeGuest.wirtin, CafeMood.zufrieden, 1,
                PanelFormat.landscape)!
            .asset,
        endsWith('wirtin_zufrieden_1_quer.jpg'));
    expect(
        resolvePortraitIn(files, CafeGuest.wirtin, CafeMood.zufrieden, 2,
                PanelFormat.landscape)!
            .asset,
        endsWith('wirtin_fragend_2_quer.jpg'));
    final other = resolvePortraitIn(
        files, CafeGuest.wirtin, CafeMood.zufrieden, 1, PanelFormat.portrait)!;
    expect(other.asset, endsWith('wirtin_zufrieden_1_quer.jpg'));
    expect(other.letterbox, isTrue);
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
