import 'package:flutter/material.dart';

import '../../../core/db/learning_db.dart';
import '../../../core/db/lexeme_lookup.dart';
import '../../../core/i18n/concept_meaning.dart';
import '../../story/episode.dart';
import '../../story/speak_evaluator.dart';
import '../bubble_overlay.dart';
import '../cafe_debrief.dart';
import '../cafe_occupancy.dart';
import '../cafe_overlay.dart';
import '../cafe_scenes.dart';
import '../cafe_portraits.dart';
import '../cafe_visit.dart';
import '../cafe_voice.dart';
import '../word_decomposition.dart';
import 'station_frame.dart';

/// Ein geladenes Wort der Wirtin-Station.
class _WirtinWord {
  final String itemId;
  final String writtenForm;
  final String reading;
  final String meaning;
  final List<SoundUnit> units;
  final StoryPanel? panel;
  final StoryBubble? bubble;
  final String surface; // Form in der Blase (z. B. 駅), sonst writtenForm
  final String? usage;
  final String? grammar;
  const _WirtinWord({
    required this.itemId, required this.writtenForm, required this.reading,
    required this.meaning, required this.units, this.panel, this.bubble,
    required this.surface, this.usage, this.grammar,
  });
  // Die DB-Schriftform ist oft Kana; Kanji stehen in der Blase (Token).
  bool get hasKanji => surface != reading;
}

/// Station 1 „Auflösen" (Spec §3.1). Pro Wort: Panel mit hervorgehobener
/// Blase, Wort groß (Kanji + Kana), Laut-Kacheln mit Vorlesen, Bedeutung,
/// „warum sagt man das", Grammatiknotiz, Nachsprechen (2 Versuche, danach
/// immer weiter). Bewertet nichts; meldet am Ende die wackeligen Wörter.
class WirtinStation extends StatefulWidget {
  final LearningDb db;
  final Episode? episode;
  final List<Episode> episodes; // freier Besuch: Folge je Wort
  final List<String> itemIds;
  final int startIndex;
  final Speak speak;
  final Speak speakSlow;
  final SpeakEvaluator evaluator;
  final Map<String, String> grammarNotes;
  final CafeLight light;
  final void Function(int nextIndex) onPosition;
  final void Function(Set<String> wobbly) onDone;
  final VoidCallback onLater;
  final double threshold;

  /// Stimme der Wirtin (Zeilen der Blase); still, wenn nicht gesetzt.
  final CafeVoice voice;

  /// Schlüssel des Besuchs; legt zusammen mit dem Wort die Bildnummer fest.
  final String visitKey;

  const WirtinStation({
    super.key,
    required this.db,
    required this.episode,
    this.episodes = const [],
    required this.itemIds,
    required this.startIndex,
    required this.speak,
    required this.speakSlow,
    required this.evaluator,
    required this.grammarNotes,
    required this.light,
    required this.onPosition,
    required this.onDone,
    required this.onLater,
    this.threshold = 0.6,
    this.voice = const CafeVoice.silent(),
    this.visitKey = '',
  });

  @override
  State<WirtinStation> createState() => _WirtinStationState();
}

class _WirtinStationState extends State<WirtinStation> {
  int _index = 0;
  _WirtinWord? _word;
  int _attempts = 0;
  String? _feedback;
  bool _succeeded = false;
  bool _listening = false; // Erkennung läuft: Mikro gesperrt
  int _variant = 1; // Bildnummer des aktuellen Worts, über Versuche stabil
  final _wobbly = <String>{};

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _loadCurrent();
  }

  Future<_WirtinWord?> _load(String itemId) async {
    final found = await loadLexemeWithConcept(widget.db, itemId);
    if (found == null) return null;
    final ep = widget.episode ?? episodeIntroducing(widget.episodes, itemId);
    final panel = ep == null ? null : firstAppearancePanel(ep, itemId);
    StoryBubble? bubble;
    var surface = found.lexeme.writtenForm;
    if (panel != null) {
      for (final b in panel.bubbles) {
        for (final t in b.tokens) {
          if (t.itemId == itemId) {
            bubble = b;
            surface = t.surface;
            break;
          }
        }
        if (bubble != null) break;
      }
    }
    return _WirtinWord(
      itemId: itemId,
      writtenForm: found.lexeme.writtenForm,
      reading: found.lexeme.reading,
      meaning: meaningForConcept(found.concept.id, fallback: found.concept.glossKey),
      units: decompose(found.lexeme.reading),
      panel: panel,
      bubble: bubble,
      surface: surface,
      usage: ep?.debrief[itemId]?.usage,
      grammar: widget.grammarNotes[itemId],
    );
  }

  /// Liest vor; true nur, wenn das Wort zu Ende gesprochen wurde.
  Future<bool> _say(Speak fn, String text) async {
    try {
      return await fn(text);
    } catch (e) {
      debugPrint('wirtin: Vorlesen fehlgeschlagen: $e');
      return false;
    }
  }

  /// Wortaudio erst nach dem nächsten Frame anfragen: dann hat der Rahmen
  /// die neue Zeile der Wirtin schon in die Warteschlange gestellt — erst
  /// die Zeile, dann das Wort.
  void _afterLine(Future<void> Function() play) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play();
    });
  }

  /// Lädt die Bilder der übrigen Stimmungen vor (kein Leerbild beim Wechsel).
  void _precacheMoods() {
    try {
      final format = MediaQuery.orientationOf(context) == Orientation.portrait
          ? PanelFormat.portrait
          : PanelFormat.landscape;
      for (final mood in const [CafeMood.zufrieden, CafeMood.abwinkend]) {
        final choice = resolvePortrait(
            CafeGuest.wirtin, mood, _variant, format, widget.light);
        if (!choice.isPortrait) continue;
        precacheImage(AssetImage(choice.asset), context).catchError((_) {});
      }
    } catch (e) {
      debugPrint('wirtin: Vorladen fehlgeschlagen: $e');
    }
  }

  Future<void> _loadCurrent() async {
    while (_index < widget.itemIds.length) {
      _WirtinWord? w;
      try {
        w = await _load(widget.itemIds[_index]);
      } catch (e) {
        debugPrint('wirtin: Laden fehlgeschlagen: $e');
        w = null; // wie ein Item ohne Lexem: überspringen
      }
      if (w != null) {
        if (!mounted) return;
        setState(() {
          _word = w;
          _variant = portraitVariant(widget.itemIds[_index], widget.visitKey, 5);
          _attempts = 0;
          _feedback = null;
          _succeeded = false;
          _listening = false;
        });
        _precacheMoods();
        final reading = w.reading;
        _afterLine(() async {
          // Das langsame Wort nur, wenn das normale zu Ende lief: ein Stopp
          // vor dem Mikro bricht die ganze Kette ab (sonst spräche es ins
          // Mikro hinein).
          final done = await _say(widget.speak, reading);
          if (!done || !mounted || _listening) return;
          await _say(widget.speakSlow, reading);
        });
        return;
      }
      _index++; // Item ohne Lexem: überspringen (Review Focus 4)
    }
    widget.onDone(_wobbly);
  }

  Future<void> _attempt() async {
    if (_listening) return;
    final w = _word!;
    setState(() => _listening = true);
    await widget.voice.stop(); // Mikro darf die Stimme nicht hören
    double score;
    try {
      score = await widget.evaluator.evaluate(
          speakTarget(w.reading, w.writtenForm, w.surface));
    } catch (e) {
      debugPrint('wirtin: Erkennung fehlgeschlagen: $e');
      score = -1;
    }
    if (!mounted) return;
    setState(() => _listening = false);
    if (score < 0) {
      // Nichts gehört (kein Mikro, Stille): kein Versuch (Spec §8).
      setState(() => _feedback = 'Ich habe nichts gehört.');
      return;
    }
    _attempts++;
    if (score >= widget.threshold) {
      setState(() {
        _succeeded = true;
        _feedback = 'Genau so.';
      });
      return;
    }
    if (_attempts == 1) {
      setState(() => _feedback = 'Fast. Hör noch einmal, ich sage es langsam.');
      _afterLine(() => _say(widget.speakSlow, w.reading));
    } else {
      setState(() => _feedback = 'Das nehmen wir später noch einmal.');
    }
  }

  void _next() {
    final w = _word!;
    if (_attempts >= 1 && !_succeeded) _wobbly.add(w.itemId); // versucht, nicht geschafft
    _index++;
    widget.onPosition(_index);
    setState(() => _word = null);
    _loadCurrent();
  }

  static const _opener = 'Setz dich. Das hier hattest du in der Folge:';

  /// Stimmung: fragend, solange eine Antwort erwartet wird (auch beim
  /// Zuhören); zufrieden bei Erfolg, sonst abwinkend.
  CafeMood get _mood {
    if (_listening || _feedback == null) return CafeMood.fragend;
    return _succeeded ? CafeMood.zufrieden : CafeMood.abwinkend;
  }

  @override
  Widget build(BuildContext context) {
    final w = _word;
    if (w == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StationFrame(
      station: CafeStation.wirtin,
      light: widget.light,
      mood: _mood,
      variant: _variant,
      line: _feedback ?? _opener,
      voice: widget.voice,
      onNext: _next,
      onLater: widget.onLater,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (w.panel != null && w.bubble != null)
              // Miniatur im Querformat: Seitenverhältnis fest, höchstens
              // 40 % der Fläche hoch; das ganze Panel ist sichtbar und die
              // Blase sitzt richtig.
              CafeThumbnail(
                child: PanelWithBubble(
                  key: const ValueKey('wirtin-panel'),
                  panel: w.panel!,
                  bubble: w.bubble!,
                  targetSurface: w.surface,
                  mode: BubbleOverlayMode.highlight,
                  format: PanelFormat.landscape,
                ),
              ),
            const SizedBox(height: 16),
            if (w.hasKanji)
              Text(w.surface,
                  key: const ValueKey('wirtin-kanji'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 56)),
            GestureDetector(
              onTap: () => _say(widget.speak, w.reading),
              child: Text(w.reading,
                  key: const ValueKey('wirtin-word'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: w.hasKanji ? 28 : 44)),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                for (var i = 0; i < w.units.length; i++)
                  OutlinedButton(
                    key: ValueKey('wirtin-tile-$i'),
                    onPressed: () => _say(widget.speak, w.units[i].text),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(w.units[i].text, style: const TextStyle(fontSize: 28)),
                        Text(w.units[i].romaji, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(w.meaning,
                key: const ValueKey('wirtin-meaning'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20)),
            if (w.usage != null) ...[
              const SizedBox(height: 12),
              Text(w.usage!, key: const ValueKey('wirtin-usage')),
            ],
            if (w.grammar != null) ...[
              const SizedBox(height: 8),
              Text(w.grammar!,
                  key: const ValueKey('wirtin-grammar'),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.tonalIcon(
                  key: const ValueKey('wirtin-mic'),
                  icon: const Icon(Icons.mic),
                  label: const Text('nachsprechen'),
                  onPressed:
                      _succeeded || _attempts >= 2 || _listening ? null : _attempt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
