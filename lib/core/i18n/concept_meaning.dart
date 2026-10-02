/// German meanings for concepts, keyed by concept id — the runtime source of
/// the meaning shown to the (German-speaking) learner. The `concepts` table
/// itself keeps only the language-neutral English `glossKey` (invariant I4);
/// this map is the localization on top. Concepts absent here fall back to
/// their English `glossKey` via [meaningForConcept], so partial coverage is
/// safe (exactly today's behavior for anything not yet translated).
const Map<String, String> conceptGlossDe = {
  'concept_dog': 'Hund',
  'concept_cat': 'Katze',
  'concept_water': 'Wasser',
  'concept_eat': 'essen',
  'concept_what': 'was',
  'concept_sorry': 'Entschuldigung',
  'concept_rain': 'Regen',
  'concept_umbrella': 'Schirm',
  'concept_this': 'das hier',
  'concept_broken': 'kaputt',
  'concept_yes': 'ja',
  'concept_here_you_go': 'bitte',
  'concept_thanks': 'danke',
  'concept_station': 'Bahnhof',
  'concept_cold': 'kalt',
  'concept_shop': 'Laden',
  'concept_alone': 'allein',
  'concept_no_good': 'geht nicht / kaputt',
  'concept_how_much': 'wie viel?',
  'concept_no': 'nein',
  'concept_really': 'wirklich?',
  'concept_all_right': 'alles gut',
  'concept_here': 'hier',
};

/// The meaning to show for [conceptId]: the German gloss if known, else
/// [fallback] (the caller passes the concept's English `glossKey`).
String meaningForConcept(String conceptId, {required String fallback}) =>
    conceptGlossDe[conceptId] ?? fallback;
