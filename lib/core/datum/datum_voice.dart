import 'datum_registry.dart';
import 'observation.dart';

/// Datum's voice: turns an [Observation] into a line, or into silence.
/// There are exactly two reasons it stays silent, and both are
/// load-bearing (SPEC_MINING_PIPELINE.md §6, §0.24):
///
///  1. **Disabled.** The whole layer is off. It emits nothing for any
///     input, so the app is fully functional without it — Datum is an
///     ornament on state that is legible without it (§0.24).
///  2. **Un-backable.** Even enabled, if no template for the
///     observation's kind has *all* its interpolated facts present,
///     nothing is emitted (§6.3). A line the engine can't fully back is
///     not spoken — never faked.
class DatumVoice {
  final DatumRegistry registry;
  final bool enabled;

  const DatumVoice({required this.registry, this.enabled = true});

  /// The line for [observation], or `null` for silence.
  String? say(Observation observation) {
    if (!enabled) return null;
    for (final template in registry.templatesFor(observation.kind)) {
      final line = renderTemplate(template, observation.facts);
      if (line != null) return line;
    }
    return null;
  }
}
