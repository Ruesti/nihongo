import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../story/episode.dart';
import '../story/episode_registry.dart';
import '../story/story_progress_store.dart';
import 'cafe_screen.dart';

/// Was das Café über Folgen wissen muss: der Fortschritts-Store und *alle*
/// Folgen mit offener Nachbesprechung, in Registry-Reihenfolge (Spec
/// Café-Nachbesprechung §3.6). autoDispose: bei jedem Betreten frisch — nach
/// einer erledigten Nachbesprechung ist die Einladung beim nächsten Besuch
/// weg.
final cafeDebriefProvider = FutureProvider.autoDispose<
    ({StoryProgressStore store, List<Episode> pending})>((ref) async {
  final episodes = ref.watch(storyEpisodesProvider);
  final store = StoryProgressStore(await SharedPreferences.getInstance());
  final pending = <Episode>[];
  for (final episode in episodes) {
    if (await store.isDebriefPending(episode.id)) pending.add(episode);
  }
  return (store: store, pending: pending);
});

/// Welche offene Nachbesprechung das Café zeigt: die angefragte, wenn sie
/// offen ist (Weg „Ins Café" von der Endkarte — sonst landete man in der
/// Nachbesprechung einer ganz anderen Folge), sonst die erste offene, sonst
/// keine.
Episode? chooseDebriefEpisode(List<Episode> pending, String? requestedId) {
  for (final episode in pending) {
    if (episode.id == requestedId) return episode;
  }
  return pending.isEmpty ? null : pending.first;
}

/// Routes the café into the app in place of the bare SRS review feed
/// (brief §4 — the café replaces the review screen entirely). Pulls the
/// on-ramp [LearningDb] and the optional knowledge bridge from providers and
/// hands them to [CafeScreen], so café reviews project into the shared mining
/// store exactly as the old ReviewScreen did.
class CafeRoute extends ConsumerWidget {
  /// Folge, deren Nachbesprechung beim Betreten von selbst aufgehen soll
  /// (Weg „Ins Café" von der Endkarte). Ist sie nicht offen — nicht zu Ende
  /// gelesen oder schon nachbesprochen —, ist es ein normaler Besuch.
  final String? debriefEpisodeId;

  const CafeRoute({super.key, this.debriefEpisodeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    final episodes = ref.watch(storyEpisodesProvider);
    final deps = ref.watch(cafeDebriefProvider);
    return deps.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // Ohne Prefs (sollte nie passieren) bleibt das Café das Café — nur
      // ohne Einladung. Stumm bleibt der Fehler trotzdem nicht.
      error: (e, _) {
        debugPrint('cafe: Nachbesprechungs-Stand nicht lesbar: $e');
        return CafeScreen(
            db: db, bridge: bridge, languageId: 'lang_ja', episodes: episodes);
      },
      data: (d) {
        final chosen = chooseDebriefEpisode(d.pending, debriefEpisodeId);
        return CafeScreen(
          db: db,
          bridge: bridge,
          languageId: 'lang_ja',
          episodes: episodes,
          debriefEpisode: chosen,
          progressStore: d.store,
          openDebriefOnEntry:
              debriefEpisodeId != null && chosen?.id == debriefEpisodeId,
        );
      },
    );
  }
}
