import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/purchases_service.dart';
import 'core/tts_service.dart';
import 'features/language_select/language_select_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Gespeicherte Spracheinstellung laden
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('active_language') ?? 'ja';

  // Initialize TTS mit gespeicherter Sprache
  await TtsService.instance.init(locale: _ttsLocaleForCode(savedLang));

  // Initialize RevenueCat (nur wenn echte API-Keys hinterlegt)
  try {
    await PurchasesService.init();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        activeLanguageProvider.overrideWith((ref) => savedLang),
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
    default: return 'ja-JP';
  }
}
