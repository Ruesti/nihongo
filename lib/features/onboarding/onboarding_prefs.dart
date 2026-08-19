import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlacementProfile {
  final bool fromZero;
  final bool knowsHiragana;
  final bool knowsKatakana;
  final List<String> knownWordLexemeIds;

  const PlacementProfile({
    required this.fromZero,
    required this.knowsHiragana,
    required this.knowsKatakana,
    required this.knownWordLexemeIds,
  });

  Map<String, dynamic> toJson() => {
        'fromZero': fromZero,
        'knowsHiragana': knowsHiragana,
        'knowsKatakana': knowsKatakana,
        'knownWordLexemeIds': knownWordLexemeIds,
      };

  factory PlacementProfile.fromJson(Map<String, dynamic> j) => PlacementProfile(
        fromZero: j['fromZero'] as bool? ?? true,
        knowsHiragana: j['knowsHiragana'] as bool? ?? false,
        knowsKatakana: j['knowsKatakana'] as bool? ?? false,
        knownWordLexemeIds:
            (j['knownWordLexemeIds'] as List?)?.cast<String>() ?? const [],
      );
}

class OnboardingPrefs {
  static const _completeKey = 'onboarding_complete';
  static const _profileKey = 'placement_profile_json';

  final SharedPreferences _prefs;
  const OnboardingPrefs(this._prefs);

  Future<bool> isComplete() async => _prefs.getBool(_completeKey) ?? false;

  Future<void> markComplete(PlacementProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await _prefs.setBool(_completeKey, true);
  }

  Future<PlacementProfile?> profile() async {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    return PlacementProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
