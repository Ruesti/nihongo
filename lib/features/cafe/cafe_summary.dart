import 'cafe_turn.dart';

/// Ein bewertetes Item dieses Besuchs (Schulmädchen; ab Plan B auch alter
/// Mann). [firstTry] = beim ersten Versuch richtig.
class VisitRecord {
  final String itemId;
  final String writtenForm;
  final CafeOutcome outcome;
  final bool firstTry;
  final DateTime? dueAt;
  const VisitRecord({
    required this.itemId,
    required this.writtenForm,
    required this.outcome,
    required this.firstTry,
    this.dueAt,
  });
}

String _join(List<String> words) {
  if (words.length == 1) return words.single;
  return '${words.sublist(0, words.length - 1).join(', ')} und ${words.last}';
}

/// Abschluss in Worten (Spec §4): „sitzen" = beim ersten Versuch richtig;
/// alles andere „kommt wieder" — morgen / in ein paar Tagen (≥ 3 Tage).
/// Nie Zahlen, nie Häkchen (INV-10); hier wird nichts gezählt.
List<String> summaryLines(List<VisitRecord> records, {required DateTime now}) {
  if (records.isEmpty) return const ['Das war es für heute.'];
  final sitzen = <String>[];
  final morgen = <String>[];
  final tage = <String>[];
  for (final r in records) {
    if (r.outcome == CafeOutcome.correct && r.firstTry) {
      sitzen.add(r.writtenForm);
      continue;
    }
    final days = r.dueAt == null ? 1 : r.dueAt!.difference(now).inDays;
    (days >= 3 ? tage : morgen).add(r.writtenForm);
  }
  final lines = <String>[];
  if (sitzen.isNotEmpty) {
    lines.add('${_join(sitzen)} ${sitzen.length == 1 ? 'sitzt' : 'sitzen'}.');
  }
  if (morgen.isNotEmpty) {
    lines.add('${_join(morgen)} ${morgen.length == 1 ? 'kommt' : 'kommen'} morgen wieder.');
  }
  if (tage.isNotEmpty) {
    lines.add('${_join(tage)} ${tage.length == 1 ? 'kommt' : 'kommen'} in ein paar Tagen wieder.');
  }
  return lines;
}
