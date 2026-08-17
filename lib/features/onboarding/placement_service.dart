import 'package:drift/drift.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../../data/kana_data.dart';
import 'onboarding_prefs.dart';

/// Turns a [PlacementProfile] into known-state, honestly: only confirmed
/// knowledge is written. Kana Ja/Nein is binary-safe; words come only from
/// the explicit micro-check. Nothing unconfirmed is ever marked known.
class PlacementService {
  static const _masteredRung = 3; // rung ≥ 3 → "known" (KnowledgeBridge)

  final LearningDb learning;
  final KnowledgeBridge? bridge;

  const PlacementService(this.learning, this.bridge);

  Future<void> apply(
    PlacementProfile profile, {
    required String languageId,
    required String languageCode,
  }) async {
    if (profile.fromZero) return; // a beginner declares nothing known

    if (profile.knowsHiragana) {
      await _masterCharacters(hiragana, languageId, languageCode);
    }
    if (profile.knowsKatakana) {
      await _masterCharacters(katakana, languageId, languageCode);
    }
    for (final lexemeId in profile.knownWordLexemeIds) {
      await learning.addLearnItemAtRung(
          languageId, RefType.lexeme, lexemeId, rung: _masteredRung);
      await bridge?.onLearnItemReviewed(
        learning,
        languageId: languageId,
        refType: 'lexeme',
        refId: lexemeId,
        newMasteryRung: _masteredRung,
        languageCode: languageCode,
      );
    }
  }

  Future<void> _masterCharacters(
    List<KanaEntry> kana,
    String languageId,
    String languageCode,
  ) async {
    for (final k in kana) {
      // Character refIds follow the pack's convention; look up the matching
      // Characters row by glyph so we mark the real learn-item.
      final row = await (learning.select(learning.characters)
            ..where((t) =>
                t.languageId.equals(languageId) & t.glyph.equals(k.kana)))
          .getSingleOrNull();
      if (row == null) continue;
      await learning.addLearnItemAtRung(
          languageId, RefType.character, row.id, rung: _masteredRung);
    }
  }
}
