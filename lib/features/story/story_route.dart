import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/tts_service.dart';
import 'diegetic_encounter.dart';
import 'episode.dart';
import 'episode_srs_handoff.dart';
import 'episodes/folge_01_regen.dart';
import 'speak_evaluator.dart';
import 'story_progress_store.dart';
import 'story_reader_screen.dart';
import 'trace_evaluator.dart';

/// Folge 01, beim ersten Zugriff validiert. Ein Schema-Verstoss wirft —
/// und erscheint damit ehrlich als Fehler in der Route statt still
/// falschen Inhalt zu zeigen.
final storyEpisodeProvider = Provider<Episode>((ref) => loadFolge01());

/// Async-Abhaengigkeiten des Readers: Fortschritts-Store + die IDs, deren
/// Bedeutung aufgedeckt werden darf (= Budget-Items, die je eingefuehrt
/// wurden). autoDispose: bei jedem Betreten frisch berechnet, damit ein
/// zweiter Durchlauf die inzwischen eingefuehrten Woerter zeigt.
final storyReaderDepsProvider = FutureProvider.autoDispose<
    ({StoryProgressStore store, Set<String> knownIds})>((ref) async {
  final episode = ref.watch(storyEpisodeProvider);
  final learning = ref.watch(learningDbProvider);
  final languageId = 'lang_${episode.locale}';
  final prefs = await SharedPreferences.getInstance();
  final known = <String>{};
  for (final item in episode.budget.items) {
    final rowId = '$languageId:${item.refType.name}:${item.id}';
    if (await learning.getLearnItem(rowId) != null) known.add(item.id);
  }
  return (store: StoryProgressStore(prefs), knownIds: known);
});

/// W3: die echte Route um [StoryReaderScreen] — liest die Provider,
/// injiziert die Service-Singletons, mappt locale ('ja') auf die Pack-ID
/// ('lang_ja') und sichert die fire-and-forget-Callbacks des Readers ab.
/// Muster: CafeRoute (W2).
class StoryRoute extends ConsumerWidget {
  /// Test-only seam: overrides the real [SttSpeakEvaluator]/
  /// [KanaTraceEvaluator] so a headless widget test can drive a diegetic
  /// speak/trace moment to success without a real mic or trace canvas. The
  /// running app never passes these — it always gets the real defaults
  /// below, since `SttSpeakEvaluator()` isn't `const` and so can't be a
  /// constructor default value.
  final SpeakEvaluator? speakEvaluator;
  final TraceEvaluator? traceEvaluator;

  const StoryRoute({super.key, this.speakEvaluator, this.traceEvaluator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(storyEpisodeProvider);
    final learning = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final deps = ref.watch(storyReaderDepsProvider);
    final languageId = 'lang_${episode.locale}';

    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Folge nicht verfügbar:\n$e',
              textAlign: TextAlign.center),
        ),
      ),
      data: (d) {
        final handoff = EpisodeSrsHandoff(
          ladder: LadderReview(learning),
          languageId: languageId,
        );
        final encounter = DiegeticEncounter(
          ladder: LadderReview(learning, bridge: bridge),
          languageId: languageId,
          languageCode: episode.locale,
        );
        Future<void> encounterAll(List<String> itemIds) async {
          for (final id in itemIds) {
            // Folge 01 budgetiert nur Lexeme; Tokens tragen keine
            // refType-Info.
            // TODO(story): refType aus dem Budget ableiten, sobald eine
            // Folge Nicht-Lexem-Items diegetisch produziert.
            await encounter.encounter(RefType.lexeme, id);
          }
        }

        return StoryReaderScreen(
          episode: episode,
          progressStore: d.store,
          speak: (t) => TtsService.instance.speak(t),
          dictionaryEntries: folge01DictionaryEntries,
          knownIds: d.knownIds,
          onEpisodeComplete: () => handoff.introduceEpisode(episode).catchError(
              (Object e) => debugPrint('story: SRS-Handoff fehlgeschlagen: $e')),
          speakEvaluator: speakEvaluator ?? SttSpeakEvaluator(),
          onDiegeticSpeakSuccess: (ids) => encounterAll(ids).catchError(
              (Object e) => debugPrint('story: Speak-Encounter fehlgeschlagen: $e')),
          traceEvaluator: traceEvaluator ?? const KanaTraceEvaluator(),
          onDiegeticTraceSuccess: (ids) => encounterAll(ids).catchError(
              (Object e) => debugPrint('story: Trace-Encounter fehlgeschlagen: $e')),
        );
      },
    );
  }
}
