import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/ladder/ladder_review.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import 'cafe_debrief.dart';
import 'cafe_debrief_card.dart';
import 'cafe_guest_script.dart';
import 'cafe_occupancy.dart';
import 'cafe_prompts.dart';
import 'cafe_scenes.dart';
import 'cafe_speaker_plan.dart';
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
  final KnowledgeBridge? bridge;

  /// Vorgegebene Warteschlange statt Fälligkeits-Abfrage — Akt 2 der
  /// Nachbesprechung fragt die Items der Folge sofort ab („unmittelbares
  /// Abrufen, aber nie kalt", Spec Café-Nachbesprechung §3.4), auch wenn ihr
  /// erster Termin erst morgen wäre. Null = wie bisher: was fällig ist.
  final List<LearnItem>? initialQueue;

  /// Schlusszeile der Wirtin, wenn die Warteschlange abgearbeitet ist
  /// (Nachbesprechung). Null = nur der Knopf zurück ins Café.
  final String? doneLine;

  /// Folgen, aus denen die Erklärungskarte Stelle-in-der-Folge und
  /// Erklärungsblock ziehen darf (Nachbesprechung: die eine Folge; normaler
  /// Besuch: alle gebündelten). Leer = Karte zeigt, was sie hat (§3.5).
  final List<Episode> episodes;

  /// Sprecher je Turn der Warteschlange (Spec Café-Szenen-und-Stimmen
  /// §3.1): die Nachbesprechung übergibt `speakerPlan(...)`, der normale
  /// Besuch nichts. Null oder falsche Länge = überall [guest] wie bisher.
  /// Die Stimme ändert nie die Übungsform (§6) — die kommt aus der Sprosse.
  final List<CafeGuest>? speakers;

  /// Sitzungs-Offset, rotiert Übergabe, Einstieg und Stimm-Zeilen; die
  /// Nachbesprechung gibt den Minuten-Offset (Spec Café-Szenen-und-Stimmen
  /// §3.1, Final-Review 19.9. — sonst trifft die Übergabe/der Einstieg
  /// immer denselben Block und dieselbe Stimm-Zeile über alle Sitzungen).
  final int lineOffset;

  /// Licht der Szene; null = aus der Uhr. Die Nachbesprechung reicht das
  /// Licht mit Regen der Folge durch (Spec Café-Szenen-und-Stimmen §5.3).
  final CafeLight? light;

  const CafeTurnScreen({
    super.key,
    required this.db,
    required this.guest,
    this.languageId = 'lang_ja',
    this.bridge,
    this.initialQueue,
    this.doneLine,
    this.episodes = const [],
    this.speakers,
    this.lineOffset = 0,
    this.light,
  });

  @override
  State<CafeTurnScreen> createState() => _CafeTurnScreenState();
}

class _CafeTurnScreenState extends State<CafeTurnScreen> {
  late final LadderReview _ladder =
      LadderReview(widget.db, bridge: widget.bridge);

  List<LearnItem> _queue = [];
  int _index = 0;
  bool _loading = true;

  /// Ein Sprecher je Turn — aus [CafeTurnScreen.speakers] oder überall der
  /// Gast. Wird in [_load] gesetzt, sobald die Warteschlange steht.
  List<CafeGuest> _speakers = const [];

  /// Zeilen beim Blockwechsel (Übergabe der Wirtin, Einstieg des neuen
  /// Sprechers), als (Key, Text). Leer, wenn kein Wechsel ansteht.
  List<(String, String)> _blockIntro = const [];

  /// Der zuletzt tatsächlich gerenderte Sprecher (Final-Review 19.9., F4).
  /// `isSpeakerChange` (cafe_speaker_plan.dart) vergleicht Index-Nachbarn im
  /// Plan — überspringt `_prepareTurn` ein Item ohne Inhalt, verglich das
  /// mit dem übersprungenen Turn und verschluckte so den Wechsel. Der
  /// Vergleich mit dem zuletzt GERENDERTEN Sprecher übersteht das.
  CafeGuest? _lastRenderedSpeaker;

  CafeGuest get _speaker =>
      _index < _speakers.length ? _speakers[_index] : widget.guest;

  CafeGuestScript get _script => scriptFor(_speaker);

  late final CafeLight _light = widget.light ?? lightFor(DateTime.now());

  /// Szene des Sprechers, ein Bild pro Block (Spec §3.3); bei offener
  /// Tastatur nur ein Band, damit Wort und Eingabe Platz behalten (§8).
  Widget _sceneHeader(BuildContext context) {
    final asset =
        turnScene(_speaker, _light, speakerBlockOrdinal(_speakers, _index));
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SizedBox(
      height: keyboardOpen ? 72 : 200,
      width: double.infinity,
      child: Image.asset(
        asset,
        key: const ValueKey('cafe-turn-scene'),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(color: const Color(0xFF2A3035)),
      ),
    );
  }

  CafeTurnContent? _content;
  final _input = TextEditingController();
  bool _hintUsed = false;
  bool _revealed = false;
  String? _followUp;

  /// Sprosse 0 = noch nie erklärt: erst die Karte, dann der Turn — die Regel
  /// der Empfang-Spec („nie kalt"), jetzt auch im Café (Spec §3.5).
  DebriefCardContent? _encounterCard;

  /// Re-Entrancy-Guard für „Verstanden" auf der Begegnungskarte (Task 7
  /// Review-Auflage): der Knopf bleibt während der Awaits in [_encounterDone]
  /// aktiv, ein zweiter, schneller Tapp darf kein doppeltes markEncountered
  /// und kein doppeltes Queue-Update auslösen.
  bool _advancing = false;

  /// Re-Entrancy-Guard für „Erklär's mir nochmal": der Knopf bleibt während
  /// des Ladens aktiv, ein zweiter, schneller Tapp dürfte sonst eine zweite
  /// Karte über die erste legen.
  bool _explaining = false;

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
    final queue = widget.initialQueue ?? await _dueForGuest();
    if (!mounted) return;
    setState(() {
      _queue = List.of(queue);
      final plan = widget.speakers;
      _speakers = plan != null && plan.length == queue.length
          ? List.of(plan)
          : List.filled(queue.length, widget.guest);
      _loading = false;
    });
    await _prepareTurn();
  }

  Future<List<LearnItem>> _dueForGuest() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    return due
        .where((i) => guestForRung(i.masteryRung) == widget.guest)
        .toList();
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
    final item = _queue[_index];
    DebriefCardContent? encounterCard;
    if (item.masteryRung == 0) {
      encounterCard = await loadDebriefCard(widget.db, item,
          episode: episodeIntroducing(widget.episodes, item.refId));
      if (!mounted) return;
    }
    final speaker = _speaker;
    final intro = <(String, String)>[];
    final speakerChanged =
        _lastRenderedSpeaker != null && speaker != _lastRenderedSpeaker;
    if (speakerChanged) {
      if (_lastRenderedSpeaker == CafeGuest.wirtin) {
        intro.add(('cafe-turn-handover',
            wirtinHandoverLine(widget.lineOffset + _index ~/ cafeBlockSize)));
      }
      final entry = scriptFor(speaker).entry(
          widget.lineOffset + speakerBlockOrdinal(_speakers, _index));
      if (entry != null) intro.add(('cafe-turn-entry', entry));
    }
    setState(() {
      _content = content;
      _encounterCard = encounterCard;
      _blockIntro = intro;
      _hintUsed = false;
      _revealed = false;
      _followUp = null;
      _input.clear();
      _lastRenderedSpeaker = speaker;
    });
  }

  void _useHint() => setState(() {
        _hintUsed = true;
        _revealed = true;
      });

  Future<void> _encounterDone() async {
    if (_advancing) return;
    _advancing = true;
    try {
      final item = _queue[_index];
      await _ladder.markEncountered(item,
          languageCode: widget.languageId.replaceFirst('lang_', ''));
      // `submit` rechnet mit den Zeilenwerten — nach der Begegnung frisch lesen.
      final refreshed = await widget.db.getLearnItem(item.id);
      if (!mounted) return;
      setState(() {
        // `_content` wurde auf Sprosse 0 gebaut und bleibt absichtlich
        // stehen: kindForRung(0) == kindForRung(1) == recognition
        // (cafe_turn.dart), die Begegnung ändert die Turn-Form also nicht.
        if (refreshed != null) _queue[_index] = refreshed;
        _encounterCard = null;
      });
    } finally {
      _advancing = false;
    }
  }

  /// „Erklär's mir nochmal" (Spec §3.5): die volle Erklärungskarte — zählt
  /// als Hinweis (→ hinted → hard, Brief §4.4), nicht als Fehler, nicht
  /// folgenlos. Ohne Karte (Lexem fehlt) passiert nichts.
  Future<void> _explainAgain() async {
    if (_explaining) return;
    _explaining = true;
    try {
      final item = _queue[_index];
      final card = await loadDebriefCard(widget.db, item,
          episode: episodeIntroducing(widget.episodes, item.refId));
      if (card == null || !mounted) return;
      setState(() {
        _hintUsed = true;
        _revealed = true;
      });
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => SizedBox(
          key: const ValueKey('cafe-turn-explain-sheet'),
          height: MediaQuery.of(sheetContext).size.height * 0.85,
          child: DebriefCardView(
            content: card,
            onDone: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      );
    } finally {
      _explaining = false;
    }
  }

  // Only called for typed turns (recognition grades via the gewusst/nicht
  // self-report buttons, which pass an explicit flag to _grade).
  bool _isCorrect(CafeTurnContent content) =>
      _input.text.trim() == content.expectedAnswer.trim();

  Future<void> _submitOutcome(CafeOutcome outcome) async {
    // The mining store keys by BCP-47 code ('ja'), NOT the on-ramp pack id
    // ('lang_ja') — same convention as ReviewScreen (review_screen.dart:124)
    // and the KnowledgeBoot backfill (main.dart:56).
    await _ladder.submit(_queue[_index], resultForOutcome(outcome),
        languageCode: widget.languageId.replaceFirst('lang_', ''));
    if (!mounted) return;
    setState(() => _followUp = _script.followUp(outcome, _index));
  }

  Future<void> _grade({required bool answerCorrect}) async {
    if (_content == null) return;
    await _submitOutcome(
        outcomeFor(hintUsed: _hintUsed, answerCorrect: answerCorrect));
  }

  Future<void> _gradeFree() async {
    if (_content == null) return;
    // Freie Produktion (Sprosse 5) wird gehalten, nicht benotet: bewusst
    // kein [CafeOutcome.hinted], auch wenn ein Hinweis lief — beide Ausgänge
    // terminieren ohnehin als `hard` (Brief §4.4). Die Gleichaltrige hat
    // seit der Stimmen-Spec auch correct/wrong/hinted-Zeilen, aber die
    // gelten für Erkennen/Lesen in der Nachbesprechung, nicht hier.
    await _submitOutcome(CafeOutcome.freeProduced);
  }

  Future<void> _next() async {
    _index++;
    await _prepareTurn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('cafe-turn-screen'),
      appBar: AppBar(
        title: Text(_guestName(_content == null ? widget.guest : _speaker)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _content == null
              ? Center(
                  key: const ValueKey('cafe-turn-done'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.doneLine != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(widget.doneLine!,
                              key: const ValueKey('cafe-turn-done-line'),
                              textAlign: TextAlign.center),
                        ),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Zurück ins Café'),
                      ),
                    ],
                  ),
                )
              : _encounterCard != null
                  ? _buildEncounter(_encounterCard!)
                  : _buildTurn(_content!),
    );
  }

  Widget _buildEncounter(DebriefCardContent card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text('Das hier ist neu für dich — hör erst mal zu.',
              style: TextStyle(fontStyle: FontStyle.italic)),
        ),
        Expanded(
          child: DebriefCardView(
            key: const ValueKey('cafe-turn-encounter'),
            content: card,
            onDone: _encounterDone,
          ),
        ),
      ],
    );
  }

  Widget _buildTurn(CafeTurnContent content) {
    final followUp = _followUp;
    final isMonologue = content.kind == CafeExerciseKind.comprehension ||
        content.kind == CafeExerciseKind.freeProduction;
    final headerText = switch (content.kind) {
      CafeExerciseKind.comprehension =>
        vielrednerMonologue(content.writtenForm, _index),
      CafeExerciseKind.freeProduction =>
        gleichaltrigeOpener(content.writtenForm, _index),
      _ => content.promptText,
    };
    // Die Stimm-Zeile steht ÜBER dem Wort und setzt nichts ein (Spec §4);
    // Monolog und Eröffnung tragen ihre Stimme schon im Kopftext.
    final voiceLine = isMonologue
        ? null
        : _script.voiceLine(content.kind, widget.lineOffset + _index);
    // Übergabe + Einstieg + Stimm-Zeile + Tastatur können den Körper länger
    // machen als der Schirm (Final-Review 19.9., F5) — scrollen statt
    // überlaufen. Die Szene ist das erste Kind, randlos vor dem Padding
    // (Task 5 der Bilder-Spec).
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sceneHeader(context),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (key, line) in _blockIntro)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line,
                        key: ValueKey(key),
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                if (voiceLine != null) ...[
                  Text(voiceLine,
                      key: const ValueKey('cafe-turn-voice'),
                      style: const TextStyle(
                          fontStyle: FontStyle.italic, fontSize: 16)),
                  const SizedBox(height: 8),
                ],
                Text(headerText,
                    key: ValueKey(isMonologue
                        ? 'cafe-turn-monologue'
                        : 'cafe-turn-prompt'),
                    style: TextStyle(fontSize: isMonologue ? 18 : 28)),
                const SizedBox(height: 16),
                // Freie Produktion (Sprosse 5) hat keine erwartete Antwort —
                // dort stünde sonst nach einem Hinweis ein nacktes „→ ".
                if (_revealed && content.expectedAnswer.isNotEmpty)
                  Text('→ ${content.expectedAnswer}',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                if (followUp == null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const ValueKey('cafe-turn-explain'),
                      onPressed: _explainAgain,
                      child: const Text("Erklär's mir nochmal"),
                    ),
                  ),
                if (followUp == null)
                  ..._buildAnswerControls(content)
                else ...[
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerControls(CafeTurnContent content) {
    if (content.kind == CafeExerciseKind.recognition ||
        content.kind == CafeExerciseKind.comprehension) {
      return [
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
        ),
      ];
    }

    if (content.kind == CafeExerciseKind.freeProduction) {
      return [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('cafe-turn-free-input'),
                controller: _input,
                decoration: const InputDecoration(hintText: '…'),
              ),
            ),
            TextButton(
              key: const ValueKey('cafe-turn-free-submit'),
              onPressed: _gradeFree,
              child: const Text('sagen'),
            ),
          ],
        ),
      ];
    }

    // readingInput / productionInput: the P8 typed row + meaning-hint dodge.
    return [
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
            onPressed: () => _grade(answerCorrect: _isCorrect(content)),
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
    ];
  }
}

String _guestName(CafeGuest guest) => switch (guest) {
      CafeGuest.wirtin => 'Die Wirtin',
      CafeGuest.schulkind => 'Das Schulkind',
      CafeGuest.vielredner => 'Der Vielredner',
      CafeGuest.gleichaltrige => 'Die Gleichaltrige',
    };
