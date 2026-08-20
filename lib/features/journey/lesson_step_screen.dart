import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/knowledge_providers.dart';
export '../../app/knowledge_providers.dart' show learningDbProvider;
import '../../core/db/learning_db.dart';
import '../../core/ladder/exercise_content.dart';
import '../../core/ladder/exercise_loader.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/ladder/rung_defs.dart';
import '../../core/script_profile.dart';
import '../encounter/encounter_view.dart';
import 'curriculum.dart';

/// A kana script profile is enough: resolveExercise(0, ...) ignores the
/// profile and returns an EncounterContent for every refType.
const _encounterProfile = ScriptProfile(
  id: 'sp',
  scriptType: ScriptType.syllabary,
  direction: Direction.ltr,
  decomposability: Decomposability.atomic,
  positionalForms: false,
  toneSystem: ToneSystem.none,
  needsScriptTrack: true,
  transliteration: 'romaji',
  inputMethods: [InputMethod.keyboard],
);

/// Runs a LessonStep: for each referenced item, introduce it (rung 0), show
/// its encounter (see/hear/trace/meaning), then markEncountered (rung 0→1).
/// Ungraded — this is teaching, not testing. Calls [onDone] when all met.
class LessonStepScreen extends ConsumerStatefulWidget {
  final LessonStep step;
  final String languageId; // 'lang_ja'
  final VoidCallback onDone;

  const LessonStepScreen({
    super.key,
    required this.step,
    required this.languageId,
    required this.onDone,
  });

  @override
  ConsumerState<LessonStepScreen> createState() => _LessonStepScreenState();
}

class _LessonStepScreenState extends ConsumerState<LessonStepScreen> {
  late final List<(RefType, String)> _refs = [
    for (final id in widget.step.characterIds) (RefType.character, id),
    for (final id in widget.step.lexemeIds) (RefType.lexeme, id),
    for (final id in widget.step.grammarIds) (RefType.grammar, id),
  ];
  int _index = 0;
  ExerciseContent? _content;
  LearnItem? _item;
  bool _loading = true;
  bool _advancing = false;

  LearningDb get _db => ref.read(learningDbProvider);
  LadderReview get _review =>
      LadderReview(_db, bridge: ref.read(knowledgeBridgeProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_index >= _refs.length) {
      widget.onDone();
      return;
    }
    final (refType, refId) = _refs[_index];
    await _review.introduce(widget.languageId, refType, refId);
    final item =
        await _db.getLearnItem('${widget.languageId}:${refType.name}:$refId');
    if (item == null) {
      // Referenced content missing from the pack — skip it, never crash.
      _index++;
      await _load();
      return;
    }
    final content = await ExerciseLoader(_db).load(item, _encounterProfile);
    if (!mounted) return;
    if (content is! EncounterContent) {
      // Already learned (rung ≥ 1): no encounter to show — skip it, never
      // freeze on a permanent spinner with no button to advance.
      _index++;
      await _load();
      return;
    }
    setState(() {
      _item = item;
      _content = content;
      _loading = false;
    });
  }

  Future<void> _next() async {
    if (_advancing) return;
    _advancing = true;
    final item = _item;
    if (item != null) {
      await _review.markEncountered(item, languageCode: widget.languageId);
    }
    if (!mounted) return;
    _index++;
    if (_index >= _refs.length) {
      widget.onDone();
      return;
    }
    setState(() => _loading = true);
    await _load();
    _advancing = false;
  }

  @override
  Widget build(BuildContext context) {
    final content = _content;
    return Scaffold(
      body: SafeArea(
        child: (_loading || content is! EncounterContent)
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: EncounterView(
                  encounter: content.encounter,
                  onDone: _next,
                ),
              ),
      ),
    );
  }
}
