import 'observation.dart';

/// One Datum utterance template: a pattern string with `{fact}`
/// placeholders (SPEC_MINING_PIPELINE.md §6.3). Templates are data, not
/// authored strings scattered in the UI — new lines are a data change
/// and localisation is another table.
class DatumTemplate {
  final ObservationKind kind;
  final String pattern;

  const DatumTemplate(this.kind, this.pattern);

  static final _placeholder = RegExp(r'\{(\w+)\}');

  /// The fact names this pattern interpolates.
  Set<String> get requiredFacts =>
      _placeholder.allMatches(pattern).map((m) => m.group(1)!).toSet();
}

/// Renders [template] against [facts], or returns `null` if ANY fact
/// the pattern interpolates is absent. This is THE Phase 9 gate guard
/// (§6.3): "No line is permitted to render a value the engine did not
/// measure." A line the facts can't fully back is simply not emitted —
/// never a placeholder, never a blank, never an invented value.
String? renderTemplate(DatumTemplate template, Map<String, Object> facts) {
  for (final fact in template.requiredFacts) {
    if (!facts.containsKey(fact)) return null;
  }
  return template.pattern.replaceAllMapped(
    DatumTemplate._placeholder,
    (m) => facts[m.group(1)]!.toString(),
  );
}

/// The template registry, keyed by [ObservationKind], for one UI
/// locale (§0.8.25 — Datum speaks the user's UI language). Localisation
/// is adding another locale's table here, not touching any logic.
class DatumRegistry {
  final String locale;
  final Map<ObservationKind, List<DatumTemplate>> _byKind;

  DatumRegistry._(this.locale, this._byKind);

  List<DatumTemplate> templatesFor(ObservationKind kind) =>
      _byKind[kind] ?? const [];

  Iterable<DatumTemplate> get allTemplates => _byKind.values.expand((t) => t);

  factory DatumRegistry.forLocale(String locale) {
    final table = _tables[locale];
    if (table == null) {
      throw ArgumentError('No Datum templates for locale "$locale"');
    }
    return DatumRegistry._(locale, table);
  }

  static final _tables = <String, Map<ObservationKind, List<DatumTemplate>>>{
    'de': {
      ObservationKind.reencounter: const [
        DatumTemplate(ObservationKind.reencounter,
            'Dieses Wort tauchte zuletzt in {episode_ref} auf. Vor {days_since} Tagen. Damals nicht erkannt.'),
      ],
      ObservationKind.predictionMiss: const [
        DatumTemplate(ObservationKind.predictionMiss,
            'Ich hatte vorhergesagt, du kennst 「{lemma}」. Ich lag falsch. Ich passe an.'),
      ],
      ObservationKind.deltaMeasured: const [
        DatumTemplate(ObservationKind.deltaMeasured,
            '{chapter}. Vor {weeks_ago} Wochen: {unknown_before} Prozent unbekannt. Heute: {unknown_after}.'),
      ],
      ObservationKind.loadWarning: const [
        DatumTemplate(ObservationKind.loadWarning,
            '{unknown_count} unbekannte Wörter in diesem Satz. Ich würde weiterlesen.'),
      ],
      ObservationKind.firstReading: const [
        DatumTemplate(ObservationKind.firstReading,
            '{chapter} einmal gelesen. Noch kein Vergleich möglich.'),
      ],
    },
  };
}
