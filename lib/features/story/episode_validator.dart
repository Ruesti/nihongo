import 'episode.dart';

class StoryValidationException implements Exception {
  final List<String> violations;
  const StoryValidationException(this.violations);

  @override
  String toString() =>
      'StoryValidationException:\n${violations.map((v) => '  - $v').join('\n')}';
}

/// Enforces INV-3 (no panel may use an item outside the episode's declared
/// budget) and INV-4 (every non-singleton budgeted item must occur ≥2 times
/// across the episode). Throws [StoryValidationException] listing every
/// violation found; does not stop at the first one.
///
/// INV-4 counts total occurrences (bubble tokens plus interaction
/// `targetItemIds` hits), not distinct panels: since Folge01 V2 (dense,
/// 10-panel format — docs/story/DREHBUCH_FOLGE_01_V2.md), a single panel
/// legitimately carries several exchanged lines belonging to one narrative
/// beat (e.g. a diagnosis scene repeating a word 3x in one panel), and a
/// diegetic speak/trace `target` can be the sole carrier of a word's
/// repetition (the Dichte-Test in folge_01_dichte_test.dart uses the same
/// occurrence-based math).
///
/// INV-18/INV-19 (Spec Mira schweigt §3.1): `priorItemIds` sind die Budget-Ids
/// aller früheren Folgen. Ein Token mit einer dieser Ids ist auch für INV-3
/// erlaubt (wiederverwendete Wörter stehen nicht im Budget der neuen Folge).
void validateEpisode(Episode episode, {Set<String> priorItemIds = const {}}) {
  final violations = <String>[];
  final budgetIds = {for (final item in episode.budget.items) item.id};
  final occurrencesByItem = <String, int>{};
  // Oberflächen aller Budget-Items, wie sie in der Folge stehen — die Menge,
  // gegen die Varianten der Nachbesprechung geprüft werden (§5.6).
  final budgetSurfaces = <String>{};

  // Structural check: panel indices must be unique across the whole episode
  final seenPanelIndices = <int>{};
  for (final panel in episode.allPanels) {
    if (!seenPanelIndices.add(panel.index)) {
      violations.add(
        'Duplicate panel index ${panel.index}: panel indices must be '
        'unique across the whole episode (structural).',
      );
    }
  }

  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      for (final token in bubble.tokens) {
        final itemId = token.itemId;
        if (itemId == null) continue;
        if (!budgetIds.contains(itemId) && !priorItemIds.contains(itemId)) {
          violations.add(
            'Panel ${panel.index}: token "${token.surface}" references item '
            '"$itemId", which is not in the episode budget (INV-3).',
          );
          continue;
        }
        if (!budgetIds.contains(itemId)) continue; // früheres Wort: erlaubt, nicht gezählt
        budgetSurfaces.add(token.surface);
        occurrencesByItem[itemId] = (occurrencesByItem[itemId] ?? 0) + 1;
      }
    }
    for (final interaction in panel.interactions) {
      for (final itemId in interaction.targetItemIds ?? const <String>[]) {
        occurrencesByItem[itemId] = (occurrencesByItem[itemId] ?? 0) + 1;
      }
    }
  }

  for (final item in episode.budget.items) {
    final count = occurrencesByItem[item.id] ?? 0;
    final minRequired = item.singleton ? 1 : 2;
    if (count < minRequired) {
      violations.add(
        'Item "${item.id}" occurs $count time(s) but requires at '
        'least $minRequired (singleton=${item.singleton}) (INV-4).',
      );
    }
  }

  // Nachbesprechung (Spec Café-Nachbesprechung §5.6): Die Wirtin erklärt nur
  // Budget-Items; Varianten („man kann auch sagen") sind Wissen am Item, keine
  // Items — höchstens zwei, und keine Variante darf selbst ein Budget-Item
  // dieser Folge sein (dann gehört sie ins Budget, nicht in die Randnotiz).
  //
  // Bewusste Abweichung: Geprüft wird gegen [budgetSurfaces] — die
  // Token-Oberflächen der Budget-Items —, nicht gegen `lexemes.writtenForm`.
  // Das Folgen-JSON hat keinen Zugriff auf die Lexem-Tabelle, die Oberflächen
  // in der Folge sind der Stellvertreter dafür, der im Prozess verfügbar ist.
  // Zwei Folgen daraus: ein Item, das nur über `targetItemIds` eines
  // Sprechmoments getragen wird, steuert keine Oberfläche bei und wird so
  // nicht erkannt; und eine Variante, die zwar ein Budget-Item ist, aber in
  // der Folge in einer anderen Schreibung steht, rutscht durch. Die exakte
  // Prüfung gegen `writtenForm` gehört in einen späteren Schritt mit
  // DB-Zugriff (Spec §5.6, Notiz).
  for (final entry in episode.debrief.entries) {
    final itemId = entry.key;
    final note = entry.value;
    if (!budgetIds.contains(itemId)) {
      violations.add(
        'Debrief "$itemId" erklärt ein Item, das nicht im Budget dieser Folge '
        'steht (Nachbesprechung erklärt nur Eingeführtes, INV-8/INV-11).',
      );
    }
    if (note.variants.length > 2) {
      violations.add(
        'Debrief "$itemId" nennt ${note.variants.length} Varianten; erlaubt '
        'sind höchstens 2 (keine Varianten-Kaskade).',
      );
    }
    for (final v in note.variants) {
      if (budgetSurfaces.contains(v.form)) {
        violations.add(
          'Debrief "$itemId": Variante "${v.form}" ist selbst ein Budget-Item '
          'dieser Folge — dann gehört sie ins Budget, nicht in „man kann auch '
          'sagen".',
        );
      }
    }
  }

  // INV-18 (Spec Mira schweigt §3.1): Mira spricht nur Wörter früherer Folgen.
  final cjk = RegExp(r'[぀-ヿ一-鿿]');
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      if (bubble.speakerId != kProtagonist) continue;
      var rest = bubble.text;
      for (final token in bubble.tokens) {
        final id = token.itemId;
        if (id == null || !priorItemIds.contains(id)) {
          violations.add(
            'Panel ${panel.index}: Mira sagt „${token.surface}" — das Wort '
            'stammt nicht aus einer früheren Folge (INV-18).',
          );
        }
        rest = rest.replaceFirst(token.surface, '');
      }
      if (cjk.hasMatch(rest)) {
        violations.add(
          'Panel ${panel.index}: Miras Blase „${bubble.text}" enthält '
          'Japanisch außerhalb ihrer Wörter (INV-18).',
        );
      }
    }
  }

  // INV-19: Ein Sprechziel muss vorher von jemand anderem gesagt worden
  // sein — in einer früheren Folge, einem früheren Panel oder einer Blase
  // desselben Panels (Blasen werden vor der Interaktion gelesen).
  final heardSoFar = <String>{...priorItemIds};
  for (final panel in episode.allPanels) {
    for (final bubble in panel.bubbles) {
      if (bubble.speakerId == kProtagonist) continue;
      for (final t in bubble.tokens) {
        if (t.itemId != null) heardSoFar.add(t.itemId!);
      }
    }
    for (final it in panel.interactions) {
      if (it.type != InteractionType.speak) continue;
      for (final id in it.targetItemIds ?? const <String>[]) {
        if (!heardSoFar.contains(id)) {
          violations.add(
            'Panel ${panel.index}: Sprechmoment „${it.target}" — Mira hat das '
            'Wort vorher von niemandem gehört (INV-19).',
          );
        }
      }
    }
  }

  // Stumme Momente (Spec Mira schweigt §4.2): Mira wollte etwas sagen und
  // konnte nicht. Ein Panel mit `silent` hat genau eine „…“-Blase von Mira
  // und genau ein Ziel; das Ziel liegt im Budget dieser oder einer früheren Folge und
  // wird in der Folge von jemand anderem gesagt (auch nach dem Moment).
  final heardInEpisode = <String>{
    for (final p in episode.allPanels)
      for (final b in p.bubbles)
        if (b.speakerId != kProtagonist)
          for (final t in b.tokens)
            if (t.itemId != null) t.itemId!,
  };
  for (final panel in episode.allPanels) {
    final silents =
        panel.interactions.where((i) => i.type == InteractionType.silent).toList();
    // Nur Mira schweigt: eine „…“-Blase zählt nur, wenn sie ihr gehört.
    for (final b in panel.bubbles) {
      if (b.isSilence && b.speakerId != kProtagonist) {
        violations.add('Panel ${panel.index}: „…"-Blase von „${b.speakerId}"; '
            'schweigen kann nur Mira (stummer Moment).');
      }
      // Eine tokenlose Mira-Blase ist genau „…“ — keine Variante wie "..."
      // oder „……“, die sonst als tippbare Blase durchrutschen würde.
      if (b.speakerId == kProtagonist && b.tokens.isEmpty && !b.isSilence) {
        violations.add('Panel ${panel.index}: Miras Blase „${b.text}" hat '
            'keine Wörter und ist nicht genau „…" (stummer Moment).');
      }
    }
    final silences = panel.bubbles
        .where((b) => b.isSilence && b.speakerId == kProtagonist)
        .length;
    if (silents.isEmpty) {
      if (silences > 0) {
        violations.add('Panel ${panel.index}: „…"-Blase ohne Interaktion '
            'silent (stummer Moment).');
      }
      continue;
    }
    if (silents.length > 1) {
      violations.add('Panel ${panel.index}: ${silents.length} stumme Momente; '
          'erlaubt ist einer je Panel (stummer Moment).');
    }
    if (silences != 1) {
      violations.add('Panel ${panel.index}: $silences „…"-Blasen; ein stummer '
          'Moment braucht genau eine (stummer Moment).');
    }
    for (final it in silents) {
      final ids = it.targetItemIds ?? const <String>[];
      if (ids.length != 1) {
        violations.add('Panel ${panel.index}: stummer Moment braucht genau ein '
            'Ziel, hat ${ids.length} (stummer Moment).');
        continue;
      }
      final id = ids.single;
      if (!budgetIds.contains(id) && !priorItemIds.contains(id)) {
        violations.add('Panel ${panel.index}: Ziel „$id" ist weder im Budget '
            'noch aus einer früheren Folge (stummer Moment).');
      }
      if (!heardInEpisode.contains(id)) {
        violations.add('Panel ${panel.index}: Ziel „$id" sagt in dieser Folge '
            'niemand (stummer Moment).');
      }
    }
  }

  if (violations.isNotEmpty) {
    throw StoryValidationException(violations);
  }
}
