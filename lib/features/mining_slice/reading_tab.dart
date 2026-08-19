import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import '../../core/language_pack/language_pack.dart';
import '../comic/comic_pack.dart';
import '../comic/comic_reader_screen.dart';
import '../comic/comic_repository.dart';
import '../language_select/language_select_screen.dart';
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

/// A comic pack for the active language, or null when none is bundled.
/// Language-blind by construction (I8): it never branches on a language
/// code, only on whether `assets/comic/{code}_l0.json` exists — so an
/// unsupported language simply has no entry, with no `if (lang == 'ja')`
/// anywhere in this file.
final comicPackProvider = FutureProvider<ComicPack?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  final path = 'assets/comic/${lang}_l0.json';
  try {
    final raw = await rootBundle.loadString(path);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null; // no comic bundled for this language → text reader only
  }
});

/// MVP dictionary seam for the comic entry point: always empty, so the
/// gloss sheet honestly degrades to "no entry" rather than fabricating a
/// gloss. FOLLOW-UP: wire a real per-language dictionary here (reuse
/// whatever seam `SliceRepository`/`SlicePack` uses) once one is threaded
/// through to this tab.
class _EmptyComicDictionary implements Dictionary {
  const _EmptyComicDictionary();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

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
/// comic pack is bundled for the active language AND the shared mining
/// store is wired up, an additional opt-in entry into [ComicReaderScreen].
/// The text reader stays the default surface either way (§I8: no
/// language branch decides this — bundled-asset + db presence do).
class _ReadingTabBody extends ConsumerWidget {
  final SliceRepository repo;
  const _ReadingTabBody({required this.repo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(miningDbProvider);
    final comicPack = ref.watch(comicPackProvider).valueOrNull;

    Widget? comicEntry;
    if (db != null && comicPack != null) {
      comicEntry = FloatingActionButton(
        key: const ValueKey('comic-entry-fab'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ComicReaderScreen(
            repo: ComicRepository(
              db: db,
              pack: comicPack,
              dictionary: const _EmptyComicDictionary(),
            ),
            // TODO(follow-up): source from the active pack's
            // ScriptProfile.direction instead of a fixed ltr default.
            direction: TextDirection.ltr,
          ),
        )),
        child: const Icon(Icons.auto_stories),
      );
    }

    return Scaffold(
      body: OpeningGate(repo: repo),
      floatingActionButton: comicEntry,
    );
  }
}
