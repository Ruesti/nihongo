import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../language_select/language_select_screen.dart';
export '../../app/knowledge_providers.dart' show learningDbProvider;
import 'curriculum.dart';
import 'journey_progress.dart';
import 'journey_service.dart';

/// The authored path for the active language, or null if none is bundled.
final curriculumProvider = FutureProvider<Curriculum?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  try {
    final raw = await rootBundle.loadString('assets/curriculum/$lang.json');
    return Curriculum.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null; // no curriculum bundled for this language yet
  }
});

final journeyProgressProvider = FutureProvider<JourneyProgress>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return JourneyProgress(prefs);
});

/// The learner's current step (skipping already-known lessons), or null when
/// the path is complete or no curriculum exists.
final currentStepProvider = FutureProvider<CurriculumStep?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  final curriculum = await ref.watch(curriculumProvider.future);
  if (curriculum == null) return null;
  final progress = await ref.watch(journeyProgressProvider.future);
  final service = JourneyService(
    curriculum: curriculum,
    learning: ref.watch(learningDbProvider),
    languageId: 'lang_$lang',
  );
  final index = await service.resolveStepIndex(progress.stepIndex(lang));
  if (index == null) return null;
  return curriculum.steps[index];
});
