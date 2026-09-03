import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import 'cafe_guest_script.dart';
import 'cafe_occupancy.dart';
import 'cafe_turn.dart';

/// One guest's café turns (brief §4.5). Drives the guest's due SM-2 items:
/// show a prompt, take an answer, auto-grade (correct / wrong / hinted-via-tap,
/// §4.4), update the ladder ([LadderReview.submit]), and react with a rotating
/// followUp — until the queue is empty. Introduces nothing (INV-8), awards no
/// café score (INV-10).
class CafeTurnScreen extends StatefulWidget {
  final LearningDb db;
  final CafeGuest guest;
  final String languageId;

  const CafeTurnScreen({
    super.key,
    required this.db,
    required this.guest,
    this.languageId = 'lang_ja',
  });

  @override
  State<CafeTurnScreen> createState() => _CafeTurnScreenState();
}

class _CafeTurnScreenState extends State<CafeTurnScreen> {
  late final LadderReview _ladder = LadderReview(widget.db);
  late final CafeGuestScript _script = scriptFor(widget.guest);

  List<LearnItem> _queue = [];
  int _index = 0;
  bool _loading = true;

  CafeTurnContent? _content;
  final _input = TextEditingController();
  bool _hintUsed = false;
  bool _revealed = false;
  String? _followUp;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    final mine =
        due.where((i) => guestForRung(i.masteryRung) == widget.guest).toList();
    if (!mounted) return;
    setState(() {
      _queue = mine;
      _loading = false;
    });
    await _prepareTurn();
  }

  Future<void> _prepareTurn() async {
    if (_index >= _queue.length) {
      if (mounted) setState(() => _content = null);
      return;
    }
    final content = await CafeTurnContent.forItem(widget.db, _queue[_index]);
    if (!mounted) return;
    if (content == null) {
      // Skip an item whose lexeme/concept is missing.
      _index++;
      await _prepareTurn();
      return;
    }
    setState(() {
      _content = content;
      _hintUsed = false;
      _revealed = false;
      _followUp = null;
      _input.clear();
    });
  }

  void _useHint() => setState(() {
        _hintUsed = true;
        _revealed = true;
      });

  // Only called for typed turns (recognition grades via the gewusst/nicht
  // self-report buttons, which pass an explicit flag to _grade).
  bool _isCorrect(CafeTurnContent content) =>
      _input.text.trim() == content.expectedAnswer.trim();

  Future<void> _grade({required bool answerCorrect}) async {
    final content = _content;
    if (content == null) return;
    final outcome =
        outcomeFor(hintUsed: _hintUsed, answerCorrect: answerCorrect);
    await _ladder.submit(_queue[_index], resultForOutcome(outcome),
        languageCode: widget.languageId);
    if (!mounted) return;
    setState(() => _followUp = _script.followUp(outcome, _index));
  }

  Future<void> _next() async {
    _index++;
    await _prepareTurn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('cafe-turn-screen'),
      appBar: AppBar(title: Text(_guestName(widget.guest))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _content == null
              ? Center(
                  key: const ValueKey('cafe-turn-done'),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zurück ins Café'),
                  ),
                )
              : _buildTurn(_content!),
    );
  }

  Widget _buildTurn(CafeTurnContent content) {
    final followUp = _followUp;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content.promptText,
              key: const ValueKey('cafe-turn-prompt'),
              style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 16),
          if (_revealed)
            Text('→ ${content.expectedAnswer}',
                style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (followUp == null) ...[
            if (content.kind == CafeExerciseKind.recognition)
              Row(
                children: [
                  TextButton(
                    key: const ValueKey('cafe-turn-reveal'),
                    onPressed: () => setState(() => _revealed = true),
                    child: const Text('zeigen'),
                  ),
                  const Spacer(),
                  TextButton(
                    key: const ValueKey('cafe-turn-known'),
                    onPressed: () => _grade(answerCorrect: true),
                    child: const Text('gewusst'),
                  ),
                  TextButton(
                    key: const ValueKey('cafe-turn-unknown'),
                    onPressed: () => _grade(answerCorrect: false),
                    child: const Text('nicht'),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('cafe-turn-input'),
                      controller: _input,
                      decoration: const InputDecoration(hintText: '…'),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('cafe-turn-submit'),
                    onPressed: () =>
                        _grade(answerCorrect: _isCorrect(content)),
                    child: const Text('sagen'),
                  ),
                ],
              ),
              // The meaning hint is a dodge only for a typed turn (where you
              // must PRODUCE something and could peek). Recognition's answer
              // IS the meaning, so revealing it there is the normal check via
              // "zeigen", not a dodge.
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const ValueKey('cafe-turn-hint'),
                  onPressed: _hintUsed ? null : _useHint,
                  child: const Text('Bedeutung zeigen'),
                ),
              ),
            ],
          ] else ...[
            Text(followUp, key: const ValueKey('cafe-turn-followup')),
            const SizedBox(height: 12),
            TextButton(
              key: const ValueKey('cafe-turn-next'),
              onPressed: _next,
              child: const Text('weiter'),
            ),
          ],
        ],
      ),
    );
  }
}

String _guestName(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => 'Die Wirtin',
      CafeGuest.schulkind => 'Das Schulkind',
      CafeGuest.vielredner => 'Der Vielredner',
      CafeGuest.gleichaltrige => 'Die Gleichaltrige',
    };
