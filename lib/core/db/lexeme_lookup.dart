import 'package:drift/drift.dart';

import 'learning_db.dart';

/// Lexem + Konzept (+ optional Bild-Asset) in einer Abfrage — die eine Stelle
/// für das Muster, das Café-Turn, Erklärungskarte und ExerciseLoader teilen.
/// Null, wenn Lexem oder Konzept fehlt. (Der `ExerciseLoader` zieht noch
/// nicht nach: sein `getSingle` wirft, statt null zu liefern — eigener
/// Schritt.)
class LexemeWithConcept {
  final Lexeme lexeme;
  final Concept concept;
  final Asset? imageAsset;

  const LexemeWithConcept({
    required this.lexeme,
    required this.concept,
    this.imageAsset,
  });
}

/// Liest das Lexem [lexemeId] mit seinem Konzept. Fehlt eines von beidem,
/// kommt null zurück — der Aufrufer überspringt das Item, statt abzustürzen
/// (Asset-Doktrin: fehlende Daten sind nie ein Absturz). [withImageAsset]
/// holt zusätzlich das Bild-Asset des Konzepts, sofern es eines gibt.
Future<LexemeWithConcept?> loadLexemeWithConcept(
  LearningDb db,
  String lexemeId, {
  bool withImageAsset = false,
}) async {
  final lexeme = await (db.select(db.lexemes)
        ..where((t) => t.id.equals(lexemeId)))
      .getSingleOrNull();
  if (lexeme == null) return null;
  final concept = await (db.select(db.concepts)
        ..where((t) => t.id.equals(lexeme.conceptId)))
      .getSingleOrNull();
  if (concept == null) return null;
  final imageAsset = !withImageAsset
      ? null
      : await (db.select(db.assets)
            ..where((t) =>
                t.conceptId.equals(lexeme.conceptId) & t.type.equals('image')))
          .getSingleOrNull();
  return LexemeWithConcept(
      lexeme: lexeme, concept: concept, imageAsset: imageAsset);
}
