import 'package:shared_preferences/shared_preferences.dart';

/// Where the learner stands on the guided path: a single step index per
/// language. Deliberately in SharedPreferences (not the DB) — no schema
/// migration needed; a DB table is an easy future upgrade if richer state
/// is ever required.
class JourneyProgress {
  final SharedPreferences _prefs;
  const JourneyProgress(this._prefs);

  String _key(String languageCode) => 'journey_step:$languageCode';

  int stepIndex(String languageCode) => _prefs.getInt(_key(languageCode)) ?? 0;

  Future<void> setStepIndex(String languageCode, int index) =>
      _prefs.setInt(_key(languageCode), index);
}
