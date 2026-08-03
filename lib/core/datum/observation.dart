import 'dart:convert';

/// The kinds of thing Datum can remark on (SPEC_MINING_PIPELINE.md
/// §6.3). Each maps to one or more templates in the registry. Adding a
/// kind is a data change (a new enum value + its templates), never
/// scattered authored strings in the UI.
enum ObservationKind {
  reencounter,
  predictionMiss,
  deltaMeasured,
  loadWarning;

  String get wireName => switch (this) {
        ObservationKind.reencounter => 'reencounter',
        ObservationKind.predictionMiss => 'prediction_miss',
        ObservationKind.deltaMeasured => 'delta_measured',
        ObservationKind.loadWarning => 'load_warning',
      };

  static ObservationKind fromWire(String s) => switch (s) {
        'reencounter' => ObservationKind.reencounter,
        'prediction_miss' => ObservationKind.predictionMiss,
        'delta_measured' => ObservationKind.deltaMeasured,
        'load_warning' => ObservationKind.loadWarning,
        _ => throw ArgumentError('Unknown ObservationKind "$s"'),
      };
}

/// §6.3's `Observation`: a kind plus the facts available about it. Every
/// fact here must trace to a real record the engine measured — this
/// type is the boundary where that guarantee is carried into the
/// utterance layer. A Datum line may interpolate a fact ONLY if it is
/// present in [facts]; the registry enforces that, never inventing a
/// value the engine did not measure (§6.3, the Phase 9 gate).
class Observation {
  final ObservationKind kind;
  final Map<String, Object> facts;

  const Observation({required this.kind, required this.facts});

  String toFactsJson() => jsonEncode(facts);

  factory Observation.fromWire(String kind, String factsJson) => Observation(
        kind: ObservationKind.fromWire(kind),
        facts: (jsonDecode(factsJson) as Map<String, dynamic>).cast<String, Object>(),
      );
}
