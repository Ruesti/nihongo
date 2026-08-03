import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/datum/datum_registry.dart';

/// A facts map with every required fact of [template] present, filled
/// with placeholder measured values — the "fully backed" case.
Map<String, Object> _fullFacts(DatumTemplate t) =>
    {for (final f in t.requiredFacts) f: 'x'};

void main() {
  final registry = DatumRegistry.forLocale('de');
  final templates = registry.allTemplates.toList();

  test('the registry actually has templates (registry is live)', () {
    expect(templates, isNotEmpty);
  });

  group('THE Phase 9 gate — no line renders an unmeasured fact', () {
    test(
        'for EVERY template, removing ANY one required fact makes it emit '
        'nothing (never a placeholder, never invented)', () {
      for (final template in templates) {
        for (final missing in template.requiredFacts) {
          final facts = _fullFacts(template)..remove(missing);
          final line = renderTemplate(template, facts);
          expect(line, isNull,
              reason: 'template "${template.pattern}" emitted a line while '
                  'fact "$missing" was absent');
        }
      }
    });

    test('a fully-backed template renders with NO leftover {placeholder}',
        () {
      for (final template in templates) {
        final line = renderTemplate(template, _fullFacts(template));
        expect(line, isNotNull);
        expect(RegExp(r'\{\w+\}').hasMatch(line!), isFalse,
            reason: 'template "${template.pattern}" left an '
                'un-interpolated placeholder');
      }
    });

    test('an empty facts map emits nothing for any template with facts', () {
      for (final template in templates) {
        if (template.requiredFacts.isEmpty) continue;
        expect(renderTemplate(template, const {}), isNull);
      }
    });

    test('extra unused facts do not break rendering', () {
      for (final template in templates) {
        final facts = _fullFacts(template)..['irrelevant'] = 'y';
        expect(renderTemplate(template, facts), isNotNull);
      }
    });
  });

  group("Datum's voice rules (§6.2) — enforced across all templates", () {
    test('no template uses exclamation marks', () {
      for (final t in templates) {
        expect(t.pattern.contains('!'), isFalse, reason: t.pattern);
      }
    });

    test('no template contains emoji or other symbol pictographs', () {
      final emoji = RegExp(
          r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2190}-\u{21FF}]',
          unicode: true);
      for (final t in templates) {
        expect(emoji.hasMatch(t.pattern), isFalse, reason: t.pattern);
      }
    });

    test('no template uses streak / praise / effort language', () {
      final banned = RegExp(
          r'(streak|serie|in folge|super|toll|großartig|weiter so|geschafft|glückwunsch)',
          caseSensitive: false);
      for (final t in templates) {
        expect(banned.hasMatch(t.pattern), isFalse, reason: t.pattern);
      }
    });
  });

  test('forLocale rejects an unknown locale', () {
    expect(() => DatumRegistry.forLocale('zz'), throwsArgumentError);
  });
}
