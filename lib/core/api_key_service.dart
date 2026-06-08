import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyService {
  static const _keyAnthropic = 'anthropic_api_key';

  static Future<void> save(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAnthropic, key.trim());
  }

  static Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyAnthropic);
    return (key != null && key.isNotEmpty) ? key : null;
  }

  static Future<bool> hasKey() async {
    final key = await get();
    return key != null;
  }

  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAnthropic);
  }
}
