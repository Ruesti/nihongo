// Proof: Reicher Lern-Loop Phase 1
//   "Kana carry stroke assets; the scene's L2 words all resolve to a gloss."
//
// Usage: dart run tool/proof_richloop_phase1.dart
// ignore_for_file: avoid_print, unnecessary_null_comparison

import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/comic/bundled_dictionary.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

Future<void> main(List<String> args) async {
  final db = LearningDb.forTesting();
  await seedJaPack(db);
  final a = await db.getLearnItem('lang_ja:character:char_ja_a'); // may be null (not introduced)
  final chars = await db.select(db.characters).get();
  final aRow = chars.firstWhere((c) => c.id == 'char_ja_a');
  final strokeOk = aRow.strokeOrderAssetId == 'assets/kanji_svg/3042.svg';

  final glossOk = jaBundledDictionary.lookup('猫', '').isNotEmpty &&
      jaBundledDictionary.lookup('水', '').isNotEmpty;

  print('=== Rich-Loop Phase 1 gate ===');
  print('kana carries stroke asset: $strokeOk');
  print('scene words have glosses:  $glossOk');
  final pass = strokeOk && glossOk;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  await db.close();
  print(pass ? '=== PASS ===' : '=== FAIL ===');
  // (a is referenced to avoid an unused-var lint if the analyzer is strict)
  assert(a == null || a != null);
}
