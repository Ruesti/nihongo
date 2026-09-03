import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/i18n/concept_meaning.dart';

void main() {
  test('returns the German gloss for a known concept', () {
    expect(meaningForConcept('concept_rain', fallback: 'rain'), 'Regen');
    expect(meaningForConcept('concept_sorry', fallback: 'sorry'),
        'Entschuldigung');
    expect(meaningForConcept('concept_dog', fallback: 'dog'), 'Hund');
  });

  test('falls back to the passed English glossKey for an unknown concept', () {
    expect(meaningForConcept('concept_unknown', fallback: 'whatever'),
        'whatever');
  });

  test('covers all 13 seeded concepts', () {
    const seeded = [
      'concept_dog', 'concept_cat', 'concept_water', 'concept_eat',
      'concept_what', 'concept_sorry', 'concept_rain', 'concept_umbrella',
      'concept_this', 'concept_broken', 'concept_yes', 'concept_here_you_go',
      'concept_thanks',
    ];
    for (final id in seeded) {
      expect(conceptGlossDe.containsKey(id), isTrue,
          reason: '$id has no German gloss');
      expect(conceptGlossDe[id]!, isNotEmpty);
    }
  });
}
