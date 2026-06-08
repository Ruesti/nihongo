import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database.dart';
import '../../../core/srs.dart';
import '../../../models/srs_card.dart';
import '../../../core/theme.dart';
import '../../../core/tts_service.dart';
import '../kanji_data.dart';
import 'memory_card.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  final int pairCount;
  final MemoryCardType pairType;

  const MemoryScreen({
    super.key,
    this.pairCount = 6,
    this.pairType = MemoryCardType.meaning,
  });

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  late List<MemoryCardData> _cards;
  int? _firstFlipped;
  int? _secondFlipped;
  int _moves = 0;
  int _matchesFound = 0;
  bool _checking = false;
  bool _done = false;
  bool _showMismatch = false;
  late DateTime _startTime;
  late List<KanjiEntry> _usedKanji;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final pool = kanjiN5.toList()..shuffle();
    _usedKanji = pool.take(widget.pairCount).toList();
    _startTime = DateTime.now();

    final cards = <MemoryCardData>[];
    for (final k in _usedKanji) {
      // Kanji card
      cards.add(MemoryCardData(
        pairId: k.kanji,
        type: MemoryCardType.kanji,
        content: k.kanji,
      ));
      // Pair card (meaning or reading)
      final pairContent = widget.pairType == MemoryCardType.meaning
          ? k.meaningDe.split(',').first.trim()
          : k.kunyomi.split('、').first.trim();
      cards.add(MemoryCardData(
        pairId: k.kanji,
        type: widget.pairType,
        content: pairContent,
      ));
    }
    _cards = cards..shuffle();
  }

  void _onCardTap(int index) {
    if (_checking) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;
    if (_firstFlipped == index) return;

    setState(() => _cards[index].isFlipped = true);
    TtsService.instance.speak(card.type == MemoryCardType.kanji ? card.content : '');

    if (_firstFlipped == null) {
      setState(() => _firstFlipped = index);
    } else {
      final first = _firstFlipped!;
      setState(() {
        _secondFlipped = index;
        _moves++;
        _checking = true;
      });

      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        if (_cards[first].pairId == _cards[index].pairId) {
          setState(() {
            _cards[first].isMatched = true;
            _cards[index].isMatched = true;
            _matchesFound++;
            _firstFlipped = null;
            _secondFlipped = null;
            _checking = false;
            _showMismatch = false;
          });
          _recordKanjiInSrs(_cards[first].pairId);
          if (_matchesFound >= widget.pairCount) {
            setState(() => _done = true);
            _saveBesttime();
          }
        } else {
          setState(() => _showMismatch = true);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            setState(() {
              _cards[first].isFlipped = false;
              _cards[index].isFlipped = false;
              _firstFlipped = null;
              _secondFlipped = null;
              _checking = false;
              _showMismatch = false;
            });
          });
        }
      });
    }
  }

  Future<void> _recordKanjiInSrs(String kanji) async {
    final db = ref.read(dbProvider);
    final entry =
        _usedKanji.firstWhere((k) => k.kanji == kanji, orElse: () => kanjiN5.first);
    final cardId = entry.cardId;
    final existing = await db.getSrsCard(cardId);
    if (existing == null) {
      await db.upsertSrsCard(SrsCard(
        id: 0,
        cardId: cardId,
        front: entry.kanji,
        back: entry.meaningDe,
        reading: entry.kunyomi,
        ease: 2.5,
        interval: 0,
        reps: 1,
        dueAt: DateTime.now()
            .add(const Duration(days: 1))
            .millisecondsSinceEpoch,
        cardType: 'kanji',
        languageCode: 'ja',
      ));
    } else {
      await db.upsertSrsCard(srsGrade(existing, 2));
    }
  }

  Future<void> _saveBesttime() async {
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    final db = ref.read(dbProvider);
    final gridKey = '${widget.pairCount}pairs';
    final typeKey = widget.pairType.name;
    await db.saveMemoryResult(gridKey, typeKey, _moves, elapsed);
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      return _ResultScreen(
        moves: _moves,
        seconds: elapsed,
        pairCount: widget.pairCount,
        onReplay: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MemoryScreen()),
        ),
        onBack: () => Navigator.of(context).pop(),
      );
    }

    // Grid: 3x4 for 6 pairs (12 cards), 4x4 for 8 pairs (16 cards)
    final cols = widget.pairCount <= 6 ? 3 : 4;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paare finden'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$_moves Züge · $_matchesFound/${widget.pairCount} ✓',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, i) {
            final card = _cards[i];
            final isMismatch = _showMismatch &&
                (i == _firstFlipped || i == _secondFlipped);
            return MemoryCardWidget(
              key: ValueKey(card.pairId + card.type.name + i.toString()),
              card: card,
              onTap: () => _onCardTap(i),
              showPulse: isMismatch,
            );
          },
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final int moves;
  final int seconds;
  final int pairCount;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  const _ResultScreen({
    required this.moves,
    required this.seconds,
    required this.pairCount,
    required this.onReplay,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final timeStr = m > 0 ? '${m}m ${s}s' : '${s}s';

    return Scaffold(
      appBar: AppBar(title: const Text('Fertig!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🀄', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                '$pairCount Paare gefunden!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'Zeit', value: timeStr),
                    _Stat(label: 'Züge', value: '$moves'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onReplay,
                  child: const Text('Nochmal'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Zurück'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.red),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.ink2),
        ),
      ],
    );
  }
}
