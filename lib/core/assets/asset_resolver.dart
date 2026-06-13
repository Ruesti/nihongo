import 'package:nihongo_app/core/db/learning_db.dart';

class AssetResolver {
  final LearningDb _db;

  AssetResolver(this._db);

  /// Resolves the asset for a lexeme at the given mastery rung.
  ///
  /// I1: production rungs (3-5) always return null — never show image during
  ///     active production exercises (anti-crutch).
  /// I4: asset is looked up by conceptId, not lexeme or language — one asset
  ///     library serves all packs.
  /// I6: returns the first (stable) asset — no regeneration per review.
  /// Graceful: missing or type='none' assets return null, never throw.
  Future<Asset?> resolve(Lexeme lexeme, int rung) async {
    if (rung >= 3) return null; // I1

    final rows = await (_db.select(_db.assets)
          ..where((t) => t.conceptId.equals(lexeme.conceptId))
          ..limit(1))
        .get();

    if (rows.isEmpty) return null;
    if (rows.first.type == 'none') return null;
    return rows.first;
  }
}
