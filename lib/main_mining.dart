import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'core/db/mining_db.dart';
import 'features/mining_slice/slice_app.dart';
import 'features/mining_slice/slice_pack.dart';
import 'features/mining_slice/slice_repository.dart';

/// Separate entry point for the mining vertical slice
/// (SPEC_MINING_PIPELINE.md). It boots the real [MiningDb], seeds it from
/// the prebaked slice asset, and shows the opening → reader flow. Kept
/// apart from `main.dart` (the legacy lesson app) so the two coexist
/// while the app is migrated:
///
///   flutter run -t lib/main_mining.dart
///
/// No native tokenizer / full JMdict here: the slice consumes prebaked
/// Lindera tokens + JMdict senses (see `tool/prebake_slice.dart`), so it
/// runs on any Flutter target with no native build. Wiring Lindera into
/// a device build and shipping a full dictionary are their own phases.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final raw = await rootBundle.loadString('assets/slice/rashomon_slice.json');
  final pack = SlicePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  final dir = await getApplicationDocumentsDirectory();
  final db = MiningDb.at(File(p.join(dir.path, 'mining_slice.db')));
  final repo = SliceRepository(db: db, pack: pack);
  await repo.seed();

  runApp(SliceApp(repo: repo));
}
