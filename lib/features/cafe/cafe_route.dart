import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
import 'cafe_screen.dart';

/// Routes the café into the app in place of the bare SRS review feed
/// (brief §4 — the café replaces the review screen entirely). Pulls the
/// on-ramp [LearningDb] and the optional knowledge bridge from providers and
/// hands them to [CafeScreen], so café reviews project into the shared mining
/// store exactly as the old ReviewScreen did.
class CafeRoute extends ConsumerWidget {
  const CafeRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(learningDbProvider);
    final bridge = ref.watch(knowledgeBridgeProvider);
    return CafeScreen(db: db, bridge: bridge, languageId: 'lang_ja');
  }
}
