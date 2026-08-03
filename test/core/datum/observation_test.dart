import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/datum/observation.dart';

void main() {
  group('ObservationKind wire names', () {
    test('every kind round-trips through its wire name', () {
      for (final kind in ObservationKind.values) {
        expect(ObservationKind.fromWire(kind.wireName), kind);
      }
    });

    test('wire names match the schema comment (snake_case)', () {
      expect(ObservationKind.predictionMiss.wireName, 'prediction_miss');
      expect(ObservationKind.deltaMeasured.wireName, 'delta_measured');
      expect(ObservationKind.loadWarning.wireName, 'load_warning');
    });

    test('fromWire rejects an unknown kind', () {
      expect(() => ObservationKind.fromWire('nope'), throwsArgumentError);
    });
  });

  group('Observation facts serialization', () {
    test('facts round-trip through JSON', () {
      const obs = Observation(kind: ObservationKind.reencounter, facts: {
        'episode_ref': 'Folge 4',
        'days_since': 23,
      });

      final restored =
          Observation.fromWire(obs.kind.wireName, obs.toFactsJson());

      expect(restored.kind, ObservationKind.reencounter);
      expect(restored.facts['episode_ref'], 'Folge 4');
      expect(restored.facts['days_since'], 23);
    });
  });
}
