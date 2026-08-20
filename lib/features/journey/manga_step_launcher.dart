import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import '../../core/language_pack/language_pack.dart' show Dictionary, Sense;
import '../comic/comic_pack.dart';
import '../comic/comic_reader_screen.dart';
import '../comic/comic_repository.dart';
import 'curriculum.dart';

/// Empty dictionary for the MVP — gloss sheet honestly degrades to "no entry".
/// Wiring a real per-language dictionary is a follow-up (same as reading_tab).
class _EmptyComicDictionary implements Dictionary {
  const _EmptyComicDictionary();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

/// Loads a ComicPack from a bundle asset path, or null if missing/malformed.
Future<ComicPack?> loadComicPackForStep(String comicAsset) async {
  try {
    final raw = await rootBundle.loadString(comicAsset);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Opens the manga reader for a MangaStep and returns when it is popped.
/// Returns `false` (no-op) if the pack can't load or mining DB is
/// unavailable — the caller must not treat that as a completed step.
/// Returns `true` once the reader push has completed.
Future<bool> openMangaStep(
  BuildContext context,
  WidgetRef ref,
  MangaStep step,
) async {
  final db = ref.read(miningDbProvider);
  final pack = await loadComicPackForStep(step.comicAsset);
  if (!context.mounted || db == null || pack == null) return false;
  await Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ComicReaderScreen(
      repo: ComicRepository(
        db: db,
        pack: pack,
        dictionary: const _EmptyComicDictionary(),
      ),
      direction: TextDirection.ltr,
    ),
  ));
  return true;
}
