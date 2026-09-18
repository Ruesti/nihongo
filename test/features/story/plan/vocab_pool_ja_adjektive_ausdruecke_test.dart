import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/story/plan/pool_checks.dart';
import 'package:nihongo_app/features/story/plan/pool_entry.dart';
import 'package:nihongo_app/features/story/plan/vocab_pool_ja_adjektive_ausdruecke.dart';

void main() {
  test('Liste F ist regelkonform', () {
    expect(checkPool(vocabPoolJaAdjektiveAusdruecke), isEmpty);
  });

  test('Liste F hat die geplante Größe', () {
    expect(vocabPoolJaAdjektiveAusdruecke.length, inInclusiveRange(155, 180));
  });

  test('Liste F trägt die festen Folge-01-Ausdrücke', () {
    final byId = {for (final e in vocabPoolJaAdjektiveAusdruecke) e.id: e};
    for (final id in [
      'lex_ja_sumimasen', 'lex_ja_hai', 'lex_ja_douzo', 'lex_ja_arigatou',
      'lex_ja_iie', 'lex_ja_hontou', 'lex_ja_daijoubu', 'lex_ja_dame',
      'lex_ja_kore', 'lex_ja_ikura',
    ]) {
      expect(byId[id]?.plannedEpisode, 1, reason: id);
      expect(byId[id]?.status, PoolStatus.ausgeliefert, reason: id);
    }
    expect(byId['lex_ja_what']?.written, '何');
    expect(byId['lex_ja_hontou']?.written, '本当');
  });

  test('Liste F kennt keine Varianten als eigene Items', () {
    final kana = vocabPoolJaAdjektiveAusdruecke.map((e) => e.kana).toSet();
    expect(kana, isNot(contains('ありがとうございます')));
    expect(kana, isNot(contains('ほんとうに')));
    expect(kana, isNot(contains('おはようございます')));
    expect(kana, isNot(contains('わかりました')));
    expect(kana, isNot(contains('がんばって')));
    // すみません ist eine feste Ausdrucksform (Folge-01-Wort, "Entschuldigung"),
    // keine frei konjugierte höfliche Verbform wie わかりました; bleibt hier
    // bewusst ausgenommen.
    final politeForms = kana.where((k) =>
        (k.endsWith('ました') || k.endsWith('ません')) && k != 'すみません');
    expect(politeForms, isEmpty,
        reason: 'höfliche Verbformen sind keine Items');
  });
}
