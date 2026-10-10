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

  static const _cafePosPrefix = 'cafe_visit_pos_';
  static const _cafeDonePrefix = 'cafe_visit_done_';

  /// „Später weiter" (Spec §2): Station und Item, bei denen der Besuch
  /// [visitId] (Folgen-ID oder `free`) abgebrochen wurde.
  Future<({int station, int item})?> cafeVisitPosition(String visitId) async {
    final raw = _prefs.getString('$_cafePosPrefix$visitId');
    if (raw == null) return null;
    final parts = raw.split(':');
    return (station: int.parse(parts[0]), item: int.parse(parts[1]));
  }

  Future<void> saveCafeVisitPosition(String visitId, int station, int item) =>
      _prefs.setString('$_cafePosPrefix$visitId', '$station:$item');

  Future<void> clearCafeVisitPosition(String visitId) async {
    await _prefs.remove('$_cafePosPrefix$visitId');
    await _prefs.remove('$_cafeWobblyPrefix$visitId');
  }

  static const _cafeWobblyPrefix = 'cafe_visit_wobbly_';

  /// Weg 1: die bei der Wirtin wackeligen Wörter, damit ein Fortsetzen die
  /// Schulmädchen-Liste genauso ordnet (wackelige zuerst).
  Future<void> saveCafeVisitWobbly(String episodeId, Set<String> ids) =>
      _prefs.setString('$_cafeWobblyPrefix$episodeId', ids.join(','));

  Future<Set<String>> cafeVisitWobbly(String episodeId) async {
    final raw = _prefs.getString('$_cafeWobblyPrefix$episodeId');
    if (raw == null || raw.isEmpty) return const {};
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  /// Weg 1 ist für diese Folge einmal zu Ende gegangen. Kein Fortschritt im
  /// Sinne von INV-10 — die Endkarte lädt nur nicht zweimal ein.
  Future<void> markCafeVisitDone(String episodeId) =>
      _prefs.setBool('$_cafeDonePrefix$episodeId', true);

  Future<bool> isCafeVisitPending(String episodeId) async =>
      await isCompleted(episodeId) &&
      !(_prefs.getBool('$_cafeDonePrefix$episodeId') ?? false);
}
