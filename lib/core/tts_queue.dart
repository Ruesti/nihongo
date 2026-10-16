/// Wird von [TtsQueue.run] geworfen, wenn ein wartender Auftrag per
/// [TtsQueue.cancelPending] verworfen wurde, bevor er an der Reihe war.
class TtsJobCancelled implements Exception {
  const TtsJobCancelled();

  @override
  String toString() => 'TtsJobCancelled';
}

/// Warteschlange für den einen Sprachmotor des Geräts: Aufträge laufen
/// strikt nacheinander in Aufrufreihenfolge (FIFO). Ein Fehler in einem
/// Auftrag bricht die Kette nicht ab.
class TtsQueue {
  Future<void> _tail = Future<void>.value();
  int _generation = 0;

  /// Hängt [job] hinten an und liefert dessen Ergebnis. Wurde vor dem Start
  /// [cancelPending] aufgerufen, läuft der Auftrag nicht und die Zukunft
  /// endet mit [TtsJobCancelled].
  Future<T> run<T>(Future<T> Function() job) {
    final generation = _generation;
    final result = _tail.then((_) {
      if (generation != _generation) throw const TtsJobCancelled();
      return job();
    });
    // Die Kette selbst schluckt Fehler; der Aufrufer sieht sie über [result].
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Verwirft alle noch nicht gestarteten Aufträge; ein laufender Auftrag
  /// läuft zu Ende (anhalten muss der Aufrufer selbst).
  void cancelPending() => _generation++;
}

/// Wie lange ein Auftrag höchstens auf das Ende einer Äußerung wartet, bevor
/// er sie als hängend behandelt (der Sprachmotor meldet Fehler nicht immer
/// zurück): 3 s Grundzeit plus 200 ms je Zeichen.
Duration ttsTimeoutFor(String text) =>
    const Duration(seconds: 3) + Duration(milliseconds: 200 * text.length);
