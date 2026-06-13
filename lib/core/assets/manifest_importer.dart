import 'package:drift/drift.dart';
import 'package:nihongo_app/core/db/learning_db.dart';

/// Imports asset records from a CSV manifest into the assets table.
///
/// CSV format (header optional, lines starting with # are comments):
///   concept_id,gloss_key,asset_type,prompt,status
///
/// Only rows with status=generated are imported. status=todo rows are skipped —
/// the DB only holds assets that actually exist on disk.
class ManifestImporter {
  final LearningDb _db;

  ManifestImporter(this._db);

  Future<int> importCsv(String csvContent) async {
    int imported = 0;

    for (final raw in csvContent.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final parts = line.split(',');
      if (parts.length < 5) continue;

      final conceptId = parts[0].trim();
      final assetType = parts[2].trim();
      final status = parts[4].trim();

      if (status != 'generated') continue;

      final path = _pathFor(conceptId, assetType);

      await _db.into(_db.assets).insertOnConflictUpdate(
            AssetsCompanion(
              id: Value('asset_$conceptId'),
              conceptId: Value(conceptId),
              type: Value(assetType),
              path: Value(path),
            ),
          );
      imported++;
    }

    return imported;
  }

  static String _pathFor(String conceptId, String type) => switch (type) {
        'image' => 'assets/$conceptId.webp',
        'clip' => 'assets/$conceptId.mp4',
        'icon' => 'assets/$conceptId.svg',
        _ => '',
      };
}
