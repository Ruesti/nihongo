import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/tts_service.dart';
import '../../packs/ja/folge_01_dictionary.dart';
import '../../packs/ja/pilot_01_regen.dart';
import '../language_select/language_select_screen.dart' show activeLanguageProvider;
import 'diegetic_encounter.dart';
import 'episode.dart';
import 'episode_srs_handoff.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'story_reader_screen.dart';
import 'trace_evaluator.dart';

/// Routes the story reader into the app (W3). Pulls the on-ramp db, the
/// optional knowledge bridge, and the active language from providers,
/// resolves SharedPreferences + the learner's introduced-item ids, and builds
/// the reader with every service wired: TTS, the speak/trace evaluators, the
/// episode-complete SRS handoff, and the diegetic speak/trace encounters. A
/// full-screen pushed route (no bottom nav) — reading is immersive.
class StoryRoute extends ConsumerWidget {
  const StoryRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final code = ref.watch(activeLanguageProvider); // BCP-47, e.g. 'ja'
    final languageId = 'lang_$code';
    final episode = Episode.fromJson(pilot01RegenJson);

    return FutureBuilder<(SharedPreferences, Set<String>)>(
      future: _load(db, languageId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final (prefs, knownIds) = snap.data!;
        final ladder = LadderReview(db, bridge: bridge);
        final handoff =
            EpisodeSrsHandoff(ladder: ladder, languageId: languageId);
        final encounter =
            DiegeticEncounter(ladder: ladder, languageId: languageId);

        Future<void> encounterAll(List<String> itemIds) async {
          for (final id in itemIds) {
            await encounter.encounter(RefType.lexeme, id);
          }
        }

        return StoryReaderScreen(
          episode: episode,
          progressStore: StoryProgressStore(prefs),
          speak: TtsService.instance.speak,
          dictionaryEntries: folge01DictionaryEntries,
          knownIds: knownIds,
          onEpisodeComplete: () =>
              handoff.introduceEpisode(episode).catchError((_) {}),
          speakEvaluator: SttSpeakEvaluator(),
          onDiegeticSpeakSuccess: (ids) => encounterAll(ids).catchError((_) {}),
          traceEvaluator: const KanaTraceEvaluator(),
          onDiegeticTraceSuccess: (ids) => encounterAll(ids).catchError((_) {}),
        );
      },
    );
  }

  Future<(SharedPreferences, Set<String>)> _load(
      LearningDb db, String languageId) async {
    final prefs = await SharedPreferences.getInstance();
    final rows = await (db.select(db.learnItems)
          ..where((t) => t.languageId.equals(languageId)))
        .get();
    return (prefs, rows.map((r) => r.refId).toSet());
  }
}
