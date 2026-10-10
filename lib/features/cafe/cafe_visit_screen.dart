import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import '../story/speak_evaluator.dart';
import '../story/story_progress_store.dart';
import 'cafe_scenes.dart';
import 'cafe_summary.dart';
import 'cafe_visit.dart';
import 'stations/schulmaedchen_station.dart';
import 'stations/station_frame.dart';
import 'stations/wirtin_station.dart';

/// Der Café-Besuch (Spec §2): ein Raum mit den vier Gästen und einer Leiste,
/// dann Station für Station. Weg 1 (`afterEpisode`) nimmt die Wörter der
/// Folge, Weg 2 (`free`) die fälligen Items. „Später weiter" speichert
/// Station und Item; der nächste Einstieg fragt nach Fortsetzen. Am Ende der
/// Abschluss der Wirtin in Worten — kein Zähler (INV-10).
class CafeVisitScreen extends StatefulWidget {
  final LearningDb db;
  final KnowledgeBridge? bridge;
  final String languageId;
  final Episode? episode; // Weg 1
  final List<Episode> episodes; // Weg 2: Panel-Kontext je Wort
  final StoryProgressStore store;
  final Speak speak;
  final Speak speakSlow;
  final SpeakEvaluator evaluator;
  final CafeLight? light;
  final Map<String, String> grammarNotes;

  const CafeVisitScreen.afterEpisode({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required Episode this.episode,
    required this.store,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    this.light,
    this.grammarNotes = const {},
  }) : episodes = const [];

  const CafeVisitScreen.free({
    super.key,
    required this.db,
    this.bridge,
    required this.languageId,
    required this.episodes,
    required this.store,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    this.light,
    this.grammarNotes = const {},
  }) : episode = null;

  String get visitId => episode?.id ?? 'free';

  @override
  State<CafeVisitScreen> createState() => _CafeVisitScreenState();
}

class _CafeVisitScreenState extends State<CafeVisitScreen> {
  CafeVisitPlan? _plan;
  CafeVisitPlan? _practice; // freiwillige Runde, wenn nichts fällig ist
  ({int station, int item})? _resume;
  late CafeLight _light;
  final _records = <VisitRecord>[];
  Set<String> _wobbly = const {};
  List<String>? _summary;

  @override
  void initState() {
    super.initState();
    _light = widget.light ?? lightFor(DateTime.now());
    _load();
  }

  Future<void> _load() async {
    final ep = widget.episode;
    CafeVisitPlan plan;
    CafeVisitPlan? practice;
    if (ep != null) {
      // Fortsetzen nach der Wirtin: ihre wackeligen Wörter wieder zuerst.
      _wobbly = await widget.store.cafeVisitWobbly(ep.id);
      plan = planAfterEpisode(ep, wobbly: _wobbly);
      if (plan.stations.isEmpty) {
        // Nichts zu üben: der Besuch ist erledigt, die Endkarte lädt nicht
        // erneut ein (sonst bliebe er ewig offen).
        await widget.store.markCafeVisitDone(ep.id);
      }
    } else {
      final due = (await widget.db.getDueItems(widget.languageId, limit: 500))
          .where((i) => i.refType == 'lexeme')
          .toList();
      final last = <String, String?>{
        for (final i in due) i.id: await widget.db.lastReviewResult(i.id),
      };
      plan = planFreeVisit(due, last);
      if (plan.stations.isEmpty) {
        final all = (await widget.db.learnItemsFor(widget.languageId))
            .where((i) => i.refType == 'lexeme')
            .toList();
        final p = planPracticeAnyway(all, seed: DateTime.now().day);
        if (p.stations.isNotEmpty) practice = p;
      }
    }
    final resume =
        ep == null ? null : await widget.store.cafeVisitPosition(widget.visitId);
    if (!mounted) return;
    setState(() {
      _plan = plan;
      _practice = practice;
      _resume = resume != null && resume.station < plan.stations.length ? resume : null;
    });
  }

  /// Nur Weg 1 merkt sich die Position. Der freie Besuch wird aus der
  /// Fälligkeitsliste neu gebaut — die ändert sich beim Bewerten, ein
  /// gespeicherter Index würde auf andere Wörter zeigen.
  Future<void> _persist(int station, int item) async {
    if (widget.episode == null) return;
    await widget.store.saveCafeVisitPosition(widget.visitId, station, item);
  }

  bool _running = false; // Doppeltipp auf Start/Weitermachen/Von vorn

  Future<void> _run({required int fromStation, required int fromItem}) async {
    if (_running) return;
    _running = true;
    try {
      await _runInner(fromStation: fromStation, fromItem: fromItem);
    } finally {
      _running = false;
    }
  }

  Future<void> _runInner({required int fromStation, required int fromItem}) async {
    var plan = _plan!;
    var left = false;
    for (var s = fromStation; s < plan.stations.length && !left; s++) {
      final sp = plan.stations[s];
      // Stationen 3/4 baut Plan B; bis dahin stehen sie nie im Plan — und
      // falls doch, werden sie übersprungen statt eine leere Seite zu zeigen.
      if (sp.station == CafeStation.vielredner ||
          sp.station == CafeStation.gleichaltrige) {
        continue;
      }
      final start = s == fromStation ? fromItem : 0;
      // Weg 1: eine Folge; Weg 2: die Stationen suchen je Wort die Folge,
      // die es eingeführt hat (episodes).
      final episode = widget.episode;
      if (!mounted) return;
      final done = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => switch (sp.station) {
          CafeStation.wirtin => WirtinStation(
              db: widget.db,
              episode: episode,
              episodes: widget.episodes,
              itemIds: sp.itemIds,
              startIndex: start,
              speak: widget.speak,
              speakSlow: widget.speakSlow,
              evaluator: widget.evaluator,
              grammarNotes: widget.grammarNotes,
              light: _light,
              onPosition: (i) => _persist(s, i),
              onDone: (w) {
                _wobbly = w;
                Navigator.of(context).pop(true);
              },
              onLater: () => Navigator.of(context).pop(false),
            ),
          CafeStation.schulmaedchen => SchulmaedchenStation(
              db: widget.db,
              bridge: widget.bridge,
              languageId: widget.languageId,
              episode: episode,
              episodes: widget.episodes,
              itemIds: sp.itemIds,
              startIndex: start,
              speak: widget.speak,
              evaluator: widget.evaluator,
              light: _light,
              onPosition: (i) => _persist(s, i),
              onDone: (r) {
                _records.addAll(r);
                Navigator.of(context).pop(true);
              },
              onLater: () => Navigator.of(context).pop(false),
            ),
          // oben übersprungen; der Switch muss trotzdem vollständig sein
          CafeStation.vielredner || CafeStation.gleichaltrige => const SizedBox(),
        },
      ));
      if (done != true) {
        left = true;
        break;
      }
      if (s + 1 < plan.stations.length) {
        await _persist(s + 1, 0);
      }
      // Weg 1: nach der Wirtin die Schulmädchen-Liste neu nach „wackelig" ordnen.
      // Die Menge wird gespeichert, damit ein Fortsetzen genauso ordnet.
      if (widget.episode != null && sp.station == CafeStation.wirtin) {
        await widget.store.saveCafeVisitWobbly(widget.episode!.id, _wobbly);
        _plan = planAfterEpisode(widget.episode!, wobbly: _wobbly);
        plan = _plan!;
      }
    }
    if (!mounted) return;
    if (left) {
      // „Später weiter": zurück zum Aufrufer (Lesen-Tab bzw. Café-Tab-Shell).
      // maybePop, weil die Shell-Route des Café-Tabs die einzige sein kann.
      await Navigator.of(context).maybePop();
      return;
    }
    if (widget.episode != null) {
      await widget.store.clearCafeVisitPosition(widget.visitId);
      await widget.store.markCafeVisitDone(widget.episode!.id);
    }
    if (!mounted) return;
    setState(() => _summary = summaryLines(_records, now: DateTime.now()));
  }

  Widget _guest(CafeStation s, {required bool active}) => Opacity(
        key: ValueKey('cafe-visit-guest-${s.name}'),
        opacity: active ? 1 : 0.4,
        child: Column(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Image.asset(
                sceneAsset(stammplatzOf(guestOf(s)), _light),
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF2A3035)),
              ),
            ),
            const SizedBox(height: 4),
            Text(stationTitles[s]!, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final summary = _summary;
    if (summary != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Die Wirtin')),
        body: ListView(
          key: const ValueKey('cafe-visit-summary'),
          padding: const EdgeInsets.all(24),
          children: [
            for (var i = 0; i < summary.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(summary[i],
                    key: ValueKey('cafe-visit-summary-line-$i'),
                    style: const TextStyle(fontSize: 18)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('cafe-visit-leave'),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(widget.episode != null ? 'Zurück zur Folge' : 'Café verlassen'),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Café')),
      body: plan == null
          ? const Center(child: CircularProgressIndicator())
          : plan.stations.isEmpty
              ? ListView(
                  key: const ValueKey('cafe-visit-empty'),
                  children: [
                    Image.asset(sceneAsset(CafeMotif.wirtinTresen, _light),
                        height: 200, width: double.infinity, fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            Container(height: 200, color: const Color(0xFF2A3035))),
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Die Wirtin wischt den Tresen und nickt dir zu.',
                          textAlign: TextAlign.center),
                    ),
                    if (_practice != null)
                      Center(
                        child: TextButton(
                          key: const ValueKey('cafe-visit-practice-anyway'),
                          onPressed: () {
                            _plan = _practice;
                            _run(fromStation: 0, fromItem: 0);
                          },
                          child: const Text('Trotzdem eine Runde mit dem Schulmädchen'),
                        ),
                      ),
                  ],
                )
              : ListView(
                  key: const ValueKey('cafe-visit-room'),
                  children: [
                    Image.asset(sceneAsset(CafeMotif.leer, _light),
                        height: 200, width: double.infinity, fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (_, _, _) =>
                            Container(height: 200, color: const Color(0xFF2A3035))),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final s in CafeStation.values)
                            _guest(s,
                                active: s == (_resume == null
                                    ? plan.stations.first.station
                                    : plan.stations[_resume!.station].station)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.episode != null
                            ? 'Es geht reihum: erst die Wirtin, dann die anderen.'
                            : 'Heute sitzen die da, bei denen etwas liegt.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_resume != null) ...[
                      Center(
                        child: FilledButton(
                          key: const ValueKey('cafe-visit-resume'),
                          onPressed: () => _run(
                              fromStation: _resume!.station, fromItem: _resume!.item),
                          child: Text(
                              'Weitermachen bei ${stationTitles[plan.stations[_resume!.station].station]!.toLowerCase().replaceFirst(RegExp('^(die|das|der) '), '')}'),
                        ),
                      ),
                      Center(
                        child: TextButton(
                          key: const ValueKey('cafe-visit-restart'),
                          onPressed: () => _run(fromStation: 0, fromItem: 0),
                          child: const Text('Von vorn'),
                        ),
                      ),
                    ] else
                      Center(
                        child: FilledButton(
                          key: const ValueKey('cafe-visit-start'),
                          onPressed: () => _run(fromStation: 0, fromItem: 0),
                          child: const Text('Setz dich'),
                        ),
                      ),
                  ],
                ),
    );
  }
}
