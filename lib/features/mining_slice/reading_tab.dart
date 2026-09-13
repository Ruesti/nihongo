import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/knowledge_providers.dart';
import 'opening_gate.dart';
import 'slice_pack.dart';
import 'slice_repository.dart';

/// Builds and seeds the reading repository over the SHARED mining store —
/// the very [MiningDb] the on-ramp projects into (`miningDbProvider`).
/// Content is seeded; demo knowledge is NOT, so the reader's "known"
/// picture is the learner's real one (from the on-ramp), never fabricated.
final readingRepositoryProvider = FutureProvider<SliceRepository?>((ref) async {
  final db = ref.watch(miningDbProvider);
  if (db == null) return null;
  final raw = await rootBundle.loadString('assets/slice/rashomon_slice.json');
  final pack = SlicePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  final repo = SliceRepository(db: db, pack: pack);
  await repo.seed(includeDemoKnowledge: false);
  return repo;
});

/// The reading / mining surface as a tab in the one app, rather than a
/// separate entry point (`main_mining.dart` stays only as a standalone
/// demo). Same OpeningScreen → reader flow, backed by the shared
/// knowledge store — so lessons and reading are one journey over one
/// knowledge truth.
class ReadingTab extends ConsumerWidget {
  const ReadingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(readingRepositoryProvider).when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: Center(
              child: Text('Lesen nicht verfügbar:\n$e',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (repo) => repo == null
              ? const Scaffold(
                  body: Center(child: Text('Mining ist nicht konfiguriert.')))
              : _ReadingTabBody(repo: repo),
        );
  }
}

/// Hosts the default text-reading surface ([OpeningGate]) and, when a
/// Comic-Einstieg: der FAB öffnet die Story-Engine-Folge (Folge 01 „Regen",
/// `/story`) — nicht mehr den alten ComicPack-Reader (Neko no hi). Der
/// Textleser bleibt die Standardfläche.
class _ReadingTabBody extends ConsumerWidget {
  final SliceRepository repo;
  const _ReadingTabBody({required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comicEntry = FloatingActionButton(
      key: const ValueKey('comic-entry-fab'),
      tooltip: 'Folge 01 lesen',
      onPressed: () => context.push('/story'),
      child: const Icon(Icons.auto_stories),
    );

    return Scaffold(
      body: OpeningGate(repo: repo),
      floatingActionButton: comicEntry,
    );
  }
}
