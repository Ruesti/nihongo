import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/tts_service.dart';
import '../story/episode.dart';
import '../story/episode_registry.dart';
import '../story/speak_evaluator.dart';
import '../story/story_progress_store.dart';
import 'cafe_visit_screen.dart';

/// Was die Route wissen muss: der Fortschritts-Store und ob für
/// [episodeId] ein Besuch nach der Folge offen ist (Spec §2, Weg 1).
final cafeVisitProvider = FutureProvider.autoDispose
    .family<({StoryProgressStore store, Episode? pending}), String?>(
        (ref, episodeId) async {
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  final episodes = ref.watch(storyEpisodesProvider);
  if (episodeId == null) {
    // Café-Tab: ein mit „Später weiter" unterbrochener Weg-1-Besuch geht
    // vor; ohne gespeicherte Position bleibt es beim freien Besuch.
    for (final e in episodes) {
      if (await store.isCafeVisitPending(e.id) &&
          await store.cafeVisitPosition(e.id) != null) {
        return (store: store, pending: e);
      }
    }
    return (store: store, pending: null);
  }
  for (final e in episodes) {
    if (e.id == episodeId && await store.isCafeVisitPending(e.id)) {
      return (store: store, pending: e);
    }
  }
  return (store: store, pending: null);
});

/// Einstieg ins Café: mit [episodeId] (Endkarte „Ins Café") Weg 1, wenn der
/// Besuch dieser Folge noch offen ist; ohne [episodeId] (Café-Tab) Weg 1 für
/// die erste offene Folge mit „Später weiter"-Position, sonst Weg 2 (freier
/// Besuch). Dienste: TTS, Spracherkennung — die Stationen laufen ohne sie
/// weiter, nur ohne Ton bzw. ohne Erkennung.
class CafeRoute extends ConsumerWidget {
  final String? episodeId;
  const CafeRoute({super.key, this.episodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final episodes = ref.watch(storyEpisodesProvider);
    final deps = ref.watch(cafeVisitProvider(episodeId));
    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Café nicht verfügbar:\n$e', textAlign: TextAlign.center)),
      ),
      data: (d) {
        final pending = d.pending;
        if (pending != null) {
          return CafeVisitScreen.afterEpisode(
            db: db,
            bridge: bridge,
            languageId: 'lang_ja',
            episode: pending,
            store: d.store,
            speak: (t) => TtsService.instance.speak(t),
            speakSlow: (t) => TtsService.instance.speakSlow(t),
            evaluator: SttSpeakEvaluator(),
          );
        }
        return CafeVisitScreen.free(
          db: db,
          bridge: bridge,
          languageId: 'lang_ja',
          episodes: episodes,
          store: d.store,
          speak: (t) => TtsService.instance.speak(t),
          speakSlow: (t) => TtsService.instance.speakSlow(t),
          evaluator: SttSpeakEvaluator(),
        );
      },
    );
  }
}
