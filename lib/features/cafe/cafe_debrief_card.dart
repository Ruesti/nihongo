import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/audio_button.dart';
import '../encounter/encounter_view.dart';
import '../story/episode.dart';
import 'cafe_debrief.dart';

/// Die Erklärungskarte der Wirtin (Spec Café-Nachbesprechung §3.3/§5.4): das
/// Begegnungs-Ritual ([EncounterView], unbenotet, nur „Verstanden") plus der
/// Café-Zusatz — die Stelle in der Folge, der Gebrauch und „man kann auch
/// sagen …". Deutsch, weil hier jemand hilft (Brief §4.4). Jeder Zusatz ist
/// optional; ohne Folge und ohne Erklärungsblock bleibt die nackte Begegnung.
class DebriefCardView extends StatelessWidget {
  final DebriefCardContent content;
  final VoidCallback onDone;

  const DebriefCardView({
    super.key,
    required this.content,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final panel = content.firstPanel;
    final note = content.note;
    final hasExtras = panel != null || note != null;
    // „Verstanden" ist eine angeheftete Fußzeile: die Karte kann mit Panel,
    // Gebrauch und zwei Varianten länger werden als der Schirm, der Knopf
    // darf deswegen nie unter der Falz verschwinden.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _scrollableCard(context, panel, note, hasExtras)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            key: const ValueKey('encounter-next'),
            onPressed: onDone,
            child: Text(AppLocalizations.of(context)!.encounterNext),
          ),
        ),
      ],
    );
  }

  Widget _scrollableCard(BuildContext context, StoryPanel? panel,
      DebriefNote? note, bool hasExtras) {
    return SingleChildScrollView(
      key: const ValueKey('cafe-debrief-card'),
      child: EncounterView(
        encounter: content.encounter,
        onDone: onDone,
        showButton: false,
        extras: !hasExtras
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (panel != null) ...[
                      Text('Hier hast du es zum ersten Mal gehört:',
                          style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.asset(
                          panel.asset,
                          key: const ValueKey('cafe-debrief-panel'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Container(color: const Color(0xFFEDEDED)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (note != null) ...[
                      Text(note.usage,
                          key: const ValueKey('cafe-debrief-usage')),
                      if (note.variants.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Man kann auch sagen:',
                            key: const ValueKey('cafe-debrief-variants-title'),
                            style: Theme.of(context).textTheme.labelMedium),
                        for (var i = 0; i < note.variants.length; i++)
                          _VariantRow(
                            key: ValueKey('cafe-debrief-variant-$i'),
                            variant: note.variants[i],
                          ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

/// Eine Variante: Form (hörbar), Lesung falls abweichend, Bedeutung, Notiz.
/// Nur Anzeige — keine Karteikarte, kein Turn (Variante ≠ Item, Spec §4).
class _VariantRow extends StatelessWidget {
  final DebriefVariant variant;

  const _VariantRow({super.key, required this.variant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant.form,
                    style: Theme.of(context).textTheme.titleMedium),
                if (variant.reading != variant.form)
                  Text(variant.reading,
                      style: Theme.of(context).textTheme.labelSmall),
                Text(variant.meaning),
                if (variant.note != null)
                  Text(variant.note!,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          AudioButton(text: variant.form, size: 28),
        ],
      ),
    );
  }
}
