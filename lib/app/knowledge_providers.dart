import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/learning_db.dart';
import '../core/db/mining_db.dart';
import '../core/pipeline/knowledge_bridge.dart';

/// The curriculum-centric on-ramp store ([LearningDb] deliberately has no
/// `path_provider`/`flutter_riverpod` dependency of its own — see its doc
/// comment). `main()` always overrides this with the concrete instance
/// opened during boot via [LearningDb.at]; every test that touches an
/// on-ramp provider overrides it too, with an in-memory
/// `LearningDb.forTesting()`. The default builder is never expected to
/// run in practice.
final learningDbProvider = Provider<LearningDb>(
  (ref) => throw UnimplementedError('learningDbProvider must be overridden'),
);

/// The shared mining knowledge store, co-hosted by the lesson app so the
/// on-ramp can project into it (architecture C, DESIGN_ONRAMP_BRIDGE.md).
///
/// Null by default — present only once `main()` overrides it with an
/// opened [MiningDb]. Deliberately nullable rather than throw-if-unset so
/// any surface that reads the bridge simply degrades to the dormant seam
/// when mining isn't wired (e.g. a widget test that pumps a screen
/// without overriding it).
final miningDbProvider = Provider<MiningDb?>((ref) => null);

/// The bridge over the shared store, or null when mining isn't present.
/// The on-ramp review paths read this and pass it to `LadderReview`;
/// when null, projection is dormant and the on-ramp behaves as before.
final knowledgeBridgeProvider = Provider<KnowledgeBridge?>((ref) {
  final db = ref.watch(miningDbProvider);
  return db == null ? null : KnowledgeBridge(db);
});
