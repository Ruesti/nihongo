import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app/knowledge_boot.dart';
import 'app/knowledge_providers.dart';
import 'core/db/learning_db.dart';
import 'core/db/mining_db.dart';
import 'core/pipeline/knowledge_bridge.dart';
import 'core/purchases_service.dart';
import 'core/tts_service.dart';
import 'features/language_select/language_select_screen.dart';
import 'packs/ja/ja_seed.dart';

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
      await seedJaPack(learningDb);
    } catch (e) {
      debugPrint('Failed to seed JA pack: $e');
    }
  }

  // Boot-unification (DESIGN_ONRAMP_BRIDGE.md, architecture C): the lesson
  // app co-hosts the shared mining knowledge store so on-ramp mastery
  // projects into it. Opening it here (and overriding the provider below)
  // makes `knowledgeBridgeProvider` non-null, so `LadderReview` in the
  // review paths projects live. A one-time backfill hands the learner's
  // existing mastery over as mining's starting "known" set.
  final dir = await getApplicationDocumentsDirectory();
  final miningDb = MiningDb.at(File(p.join(dir.path, 'mining.db')));
  try {
    final langs = await learningDb.select(learningDb.languages).get();
    final bridged = [
      for (final l in langs.where((l) => l.enabled))
        (languageId: l.id, languageCode: l.id.replaceFirst('lang_', ''))
    ];
    await KnowledgeBoot(KnowledgeBridge(miningDb)).ensureBackfilled(
      learningDb,
      languages: bridged,
      isDone: (key) async => prefs.getBool(key) ?? false,
      markDone: (key) async {
        await prefs.setBool(key, true);
      },
    );
  } catch (e) {
    debugPrint('Knowledge backfill skipped: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        activeLanguageProvider.overrideWith((ref) => savedLang),
        learningDbProvider.overrideWith((ref) => learningDb),
        miningDbProvider.overrideWith((ref) => miningDb),
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
