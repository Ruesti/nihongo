import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import '../story/story_progress_store.dart';
import 'cafe_debrief.dart';
import 'cafe_debrief_card.dart';
import 'cafe_occupancy.dart';
import 'cafe_prompts.dart';
import 'cafe_scenes.dart';
import 'cafe_speaker_plan.dart';
import 'cafe_turn_screen.dart';

/// Die Nachbesprechung einer Folge (Spec Café-Nachbesprechung §3.3–§3.6).
/// Akt 1: die Wirtin erklärt jedes Item der Folge (Erklärungskarte, nur
/// „Verstanden"; ein Sprosse-0-Item wird dabei begegnet → Sprosse 1). Akt 2:
/// dieselben Items als gewohnte Café-Turns ([CafeTurnScreen] mit
/// vorgegebener Warteschlange). Akt 2 spricht mit mehreren Stimmen:
/// [speakerPlan] verteilt die Turns blockweise auf die vier Gäste, die
/// Wirtin rahmt (Spec Café-Szenen-und-Stimmen §3.1). Item-Quelle ist
/// ausschließlich [debriefItemsFor] (Manifest ∩ Karteikasten, INV-8/INV-11).
/// Der Stand von Akt 1 wird im [StoryProgressStore] gemerkt — Abbruch setzt
/// beim ersten offenen Item fort; kein Zähler, kein Häkchen (INV-10).
class CafeDebriefScreen extends StatefulWidget {
  final LearningDb db;
  final Episode episode;
  final StoryProgressStore progressStore;
  final String languageId;
  final KnowledgeBridge? bridge;

  /// Licht der Szenen; null = Uhr plus Regen der Folge (Spec §5.3).
  final CafeLight? light;

  const CafeDebriefScreen({
    super.key,
    required this.db,
    required this.episode,
    required this.progressStore,
    this.languageId = 'lang_ja',
    this.bridge,
    this.light,
  });

  @override
  State<CafeDebriefScreen> createState() => _CafeDebriefScreenState();
}

enum _DebriefPhase { loading, explain, empty }

class _CafeDebriefScreenState extends State<CafeDebriefScreen> {
  late final LadderReview _ladder =
      LadderReview(widget.db, bridge: widget.bridge);

  List<LearnItem> _items = [];
  int _index = 0;
  DebriefCardContent? _card;
  _DebriefPhase _phase = _DebriefPhase.loading;
  bool _advancing = false;
  late final CafeLight _light = widget.light ??
      lightFor(DateTime.now(), rain: widget.episode.weather == 'rain');

  String get _languageCode => widget.languageId.replaceFirst('lang_', '');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items =
        await debriefItemsFor(widget.db, widget.episode, widget.languageId);
    final start = await widget.progressStore.debriefIndex(widget.episode.id);
    if (!mounted) return;
    _items = items;
    _index = start.clamp(0, items.length);
    if (items.isEmpty) {
      // Akt 1 ohne Items ist vollständig gesehen: sonst bliebe die
      // Nachbesprechung für immer offen und die Wirtin lüde ewig ein.
      await widget.progressStore.markDebriefDone(widget.episode.id);
      if (!mounted) return;
      setState(() => _phase = _DebriefPhase.empty);
      return;
    }
    await _prepareCard();
  }

  Future<void> _prepareCard() async {
    if (_index >= _items.length) {
      await _finishExplain();
      return;
    }
    final card = await loadDebriefCard(widget.db, _items[_index],
        episode: widget.episode);
    if (!mounted) return;
    if (card == null) {
      // Lexem/Konzept fehlt: überspringen, nicht abstürzen (Spec §5.3).
      _index++;
      await _prepareCard();
      return;
    }
    setState(() {
      _card = card;
      _phase = _DebriefPhase.explain;
    });
  }

  Future<void> _cardDone() async {
    // Re-Entrancy-Guard: „Verstanden" bleibt während der Awaits unten
    // aktiv (EncounterView bleibt unverändert) — ein zweiter, schneller Tapp
    // darf keine zweite Karte überspringen (derselbe Index, doppeltes
    // markEncountered, doppeltes _index++).
    if (_advancing) return;
    _advancing = true;
    try {
      final item = _items[_index];
      // Erst-Erklärung = Begegnung: Sprosse 0 → 1 wie in der Lektion. Items,
      // die ein diegetischer Moment schon auf Sprosse 1 gehoben hat, bleiben
      // unberührt — die Karte ist keine zweite Einführung (Spec §3.3).
      if (item.masteryRung == 0) {
        await _ladder.markEncountered(item, languageCode: _languageCode);
      }
      _index++;
      await widget.progressStore.saveDebriefIndex(widget.episode.id, _index);
      if (!mounted) return;
      await _prepareCard();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _finishExplain() async {
    await widget.progressStore.markDebriefDone(widget.episode.id);
    // Akt 2 fragt dieselben Items ab — frisch aus der DB, denn Akt 1 hat
    // Sprosse und Termin verändert und `submit` rechnet mit den Zeilenwerten.
    final refreshed = <LearnItem>[];
    for (final item in _items) {
      final row = await widget.db.getLearnItem(item.id);
      if (row != null) refreshed.add(row);
    }
    if (!mounted) return;
    // Nach Sitzung rotieren, nicht nach Item-Anzahl: an der Anzahl hängend
    // hörte man bei gleich langen Folgen immer denselben Satz — und immer
    // dieselbe Stimmen-Reihenfolge (Spec Café-Szenen-und-Stimmen §3.1).
    final sessionOffset = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => CafeTurnScreen(
        db: widget.db,
        guest: CafeGuest.wirtin,
        languageId: widget.languageId,
        bridge: widget.bridge,
        initialQueue: refreshed,
        speakers: speakerPlan(refreshed.length, sessionOffset: sessionOffset),
        lineOffset: sessionOffset,
        // Eigener Divisor statt desselben Offsets wie die Sprecherfolge:
        // sonst korrelierte die Schlusszeile immer mit derselben Stimmen-
        // Reihenfolge (Final-Review 19.9., F2).
        doneLine: wirtinDebriefClosing(sessionOffset ~/ 3),
        episodes: [widget.episode],
        light: _light,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('cafe-debrief-screen'),
      appBar: AppBar(title: const Text('Die Wirtin')),
      body: switch (_phase) {
        _DebriefPhase.loading =>
          const Center(child: CircularProgressIndicator()),
        _DebriefPhase.empty => Center(
            key: const ValueKey('cafe-debrief-empty'),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Die Wirtin nickt. Über diese Folge gibt es noch nichts '
                    'zu erzählen.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Zurück ins Café'),
                  ),
                ],
              ),
            ),
          ),
        _DebriefPhase.explain => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 96,
                width: double.infinity,
                child: Image.asset(
                  sceneAsset(CafeMotif.wirtinTisch, _light),
                  key: const ValueKey('cafe-debrief-band'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF2A3035)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Text(
                  wirtinDebriefLine(_index),
                  key: const ValueKey('cafe-debrief-line'),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              Expanded(
                child: DebriefCardView(content: _card!, onDone: _cardDone),
              ),
            ],
          ),
      },
    );
  }
}
