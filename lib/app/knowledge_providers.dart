import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/mining_db.dart';
import '../core/pipeline/knowledge_bridge.dart';

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
