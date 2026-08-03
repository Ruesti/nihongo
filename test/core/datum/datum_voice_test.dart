import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/datum/datum_registry.dart';
import 'package:nihongo_app/core/datum/datum_voice.dart';
import 'package:nihongo_app/core/datum/observation.dart';

void main() {

  const backedLoad = Observation(
    kind: ObservationKind.loadWarning,
    facts: {'unknown_count': 3},
  );

  group('DatumVoice', () {
    test('enabled + a fully-backed observation speaks a line', () {
      final voice = DatumVoice(registry: _reg, enabled: true);
      final line = voice.say(backedLoad);

      expect(line, isNotNull);
      expect(line, contains('3'));
    });

    test('enabled + a missing fact stays silent (not a faked line)', () {
      final voice = DatumVoice(registry: _reg, enabled: true);
      const noCount =
          Observation(kind: ObservationKind.loadWarning, facts: {});

      expect(voice.say(noCount), isNull);
    });

    test('DISABLED stays silent for every observation kind', () {
      final voice = DatumVoice(registry: _reg, enabled: false);

      for (final kind in ObservationKind.values) {
        // Even with plausibly-complete facts, disabled emits nothing —
        // the app is fully functional without Datum (§0.24).
        final obs = Observation(kind: kind, facts: const {
          'episode_ref': 'Folge 4',
          'days_since': 23,
          'lemma': '本',
          'chapter': 'Kapitel 2',
          'weeks_ago': 6,
          'unknown_before': 41,
          'unknown_after': 8,
          'unknown_count': 3,
        });
        expect(voice.say(obs), isNull, reason: 'kind=$kind');
      }
    });

    test('reencounter line interpolates its measured facts', () {
      final voice = DatumVoice(registry: _reg, enabled: true);
      const obs = Observation(kind: ObservationKind.reencounter, facts: {
        'episode_ref': 'Folge 4',
        'days_since': 23,
      });

      final line = voice.say(obs);

      expect(line, contains('Folge 4'));
      expect(line, contains('23'));
    });
  });
}

// A registry instance usable in const DatumVoice (forLocale isn't const,
// so grab it once at top level).
final _reg = DatumRegistry.forLocale('de');
