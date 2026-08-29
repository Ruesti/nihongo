import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which panel a reader last reached in an episode, keyed by
/// [Episode.id]. One integer per episode — the position is an index into
/// [Episode.allPanels], not a [StoryPanel.index] value.
class StoryProgressStore {
  static const _keyPrefix = 'story_progress_';

  final SharedPreferences _prefs;
  const StoryProgressStore(this._prefs);

  Future<int?> lastPosition(String episodeId) async {
    return _prefs.getInt('$_keyPrefix$episodeId');
  }

  Future<void> savePosition(String episodeId, int position) async {
    await _prefs.setInt('$_keyPrefix$episodeId', position);
  }
}
