import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/learning_db.dart';
import 'core/db/seed_all.dart';
import 'core/purchases_service.dart';
import 'core/tts_service.dart';
import 'features/language_select/language_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('active_language') ?? 'ja';

  await TtsService.instance.init(locale: _ttsLocaleForCode(savedLang));

  try {
    await PurchasesService.init();
  } catch (_) {}

  final learningDb = LearningDb();
  final existingLangs = await learningDb.select(learningDb.languages).get();
  if (existingLangs.isEmpty) {
    try {
      await seedAllPacks(learningDb);
    } catch (e) {
      debugPrint('Failed to seed language packs: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        activeLanguageProvider.overrideWith((ref) => savedLang),
        learningDbProvider.overrideWith((ref) => learningDb),
      ],
      child: const NihongoApp(),
    ),
  );
}

String _ttsLocaleForCode(String code) {
  switch (code) {
    case 'ko': return 'ko-KR';
    case 'es': return 'es-ES';
    case 'zh': return 'zh-CN';
    case 'ar': return 'ar-SA';
    case 'hi': return 'hi-IN';
    default: return 'ja-JP';
  }
}
