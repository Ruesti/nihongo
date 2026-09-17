import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which panel a reader last reached in an episode, keyed by
/// [Episode.id]. One integer per episode — the position is an index into
/// [Episode.allPanels], not a [StoryPanel.index] value.
class StoryProgressStore {
  static const _keyPrefix = 'story_progress_';
  static const _completedPrefix = 'story_completed_';

  final SharedPreferences _prefs;
  const StoryProgressStore(this._prefs);

  Future<int?> lastPosition(String episodeId) async {
    return _prefs.getInt('$_keyPrefix$episodeId');
  }

  Future<void> savePosition(String episodeId, int position) async {
    await _prefs.setInt('$_keyPrefix$episodeId', position);
  }

  /// Merkt, dass die Folge einmal zu Ende gelesen wurde. Eine
  /// abgeschlossene Folge startet beim nächsten Öffnen bei der
  /// Titelkarte (Spec Reader-Erleben §2.7).
  Future<void> markCompleted(String episodeId) async =>
      await _prefs.setBool('$_completedPrefix$episodeId', true);

  Future<bool> isCompleted(String episodeId) async =>
      _prefs.getBool('$_completedPrefix$episodeId') ?? false;

  static const _debriefIndexPrefix = 'story_debrief_index_';
  static const _debriefDonePrefix = 'story_debrief_done_';

  /// Nachbesprechung, Akt 1: Index der nächsten noch nicht erklärten Karte
  /// (Spec Café-Nachbesprechung §3.6 — Abbruch setzt beim ersten offenen
  /// Item fort). 0, wenn noch nichts erklärt wurde.
  Future<int> debriefIndex(String episodeId) async =>
      _prefs.getInt('$_debriefIndexPrefix$episodeId') ?? 0;

  Future<void> saveDebriefIndex(String episodeId, int index) async =>
      await _prefs.setInt('$_debriefIndexPrefix$episodeId', index);

  /// Akt 1 vollständig gesehen. Kein Fortschritt im Sinne von INV-10: schaltet
  /// nichts frei, wird nirgends gezählt — die Wirtin erklärt nur nicht zweimal.
  Future<void> markDebriefDone(String episodeId) async =>
      await _prefs.setBool('$_debriefDonePrefix$episodeId', true);

  Future<bool> isDebriefDone(String episodeId) async =>
      _prefs.getBool('$_debriefDonePrefix$episodeId') ?? false;

  /// Offen = Folge zu Ende gelesen UND Akt 1 noch nicht vollständig gesehen
  /// (§3.6). Vor dem Folgen-Ende ist eine Nachbesprechung nie offen (INV-11).
  Future<bool> isDebriefPending(String episodeId) async =>
      await isCompleted(episodeId) && !await isDebriefDone(episodeId);
}
