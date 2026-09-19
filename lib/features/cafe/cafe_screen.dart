import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../story/episode.dart';
import '../story/story_progress_store.dart';
import 'cafe_debrief_screen.dart';
import 'cafe_occupancy.dart';
import 'cafe_prompts.dart';
import 'cafe_scenes.dart';
import 'cafe_turn_screen.dart';

/// The café — the repetition mode that replaces the bare SRS feed (brief §4).
/// Occupancy is the due indicator: who is present depends on what is due,
/// computed ONCE on entry and stable for the session (PHASE_0 §7). Nothing
/// due → the café is calmly empty, no count, no "0 due" message (§4.3). The
/// café introduces nothing (INV-8) and has no progress of its own — no level,
/// no currency, no unlocks (INV-10). Tapping a present guest opens that
/// guest's turn ([CafeTurnScreen], P8); returning refreshes occupancy so a
/// finished batch of reviews is reflected without violating "fixed per
/// session" (still only once per guest visit, not on every rebuild).
///
/// Nachbesprechung (Spec Café-Nachbesprechung §3.6): Sind [debriefEpisode]
/// und [progressStore] gesetzt und ist die Nachbesprechung dieser Folge noch
/// offen, ist die Wirtin unabhängig von der Fälligkeit anwesend und ihr Tisch
/// trägt die Einladung ([wirtinDebriefInvite], Key `cafe-debrief-invite`) —
/// ein Satz, kein Zähler (INV-10). Ein Tipp darauf öffnet den
/// [CafeDebriefScreen]; mit [openDebriefOnEntry] geht er beim Betreten von
/// selbst auf (Weg „Ins Café" von der Endkarte, §3.2), aber nur einmal pro
/// Besuch. „Offen oder nicht" wird bei jedem `_load()` neu gelesen — also
/// auch nach der Rückkehr aus der Nachbesprechung, sodass die Einladung dann
/// von selbst verschwindet.
class CafeScreen extends StatefulWidget {
  final LearningDb db;
  final String languageId;
  final KnowledgeBridge? bridge;

  /// Alle gebündelten Folgen — Kontext für „Erklär's mir nochmal" im Turn.
  final List<Episode> episodes;

  /// Die Folge mit offener Nachbesprechung (von der Route ermittelt), sonst
  /// null. Zusammen mit [progressStore] macht sie die Wirtin anwesend und
  /// ihren Tisch zur Einladung (Spec Café-Nachbesprechung §3.6).
  final Episode? debriefEpisode;
  final StoryProgressStore? progressStore;

  /// True = die Nachbesprechung öffnet sich beim Betreten von selbst (Weg
  /// „Ins Café" von der Endkarte, §3.2). Danach: der normale Café-Raum.
  final bool openDebriefOnEntry;

  /// Licht der Szenen; null = aus der Uhr (Spec Café-Szenen-und-Stimmen
  /// §5.3). Der normale Besuch kennt keinen Regen.
  final CafeLight? light;

  const CafeScreen({
    super.key,
    required this.db,
    this.languageId = 'lang_ja',
    this.bridge,
    this.episodes = const [],
    this.debriefEpisode,
    this.progressStore,
    this.openDebriefOnEntry = false,
    this.light,
  });

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  CafeOccupancy? _occupancy;
  bool _debriefPending = false;
  bool _autoOpened = false;

  late final CafeLight _light = widget.light ?? lightFor(DateTime.now());

  /// Szene; fehlendes Asset → neutrale Fläche, nie Crash (CLAUDE.md §6).
  static Widget _scene(String asset, {required String keyName, double? height}) =>
      Image.asset(
        asset,
        key: ValueKey(keyName),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height ?? 160,
          color: const Color(0xFF2A3035),
        ),
      );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    final pending = await _isDebriefPending();
    if (!mounted) return;
    setState(() {
      _debriefPending = pending;
      _occupancy = CafeOccupancy.fromDueItems(due, pendingDebrief: pending);
    });
    if (pending && widget.openDebriefOnEntry && !_autoOpened) {
      _autoOpened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openDebrief();
      });
    }
  }

  Future<bool> _isDebriefPending() async {
    final episode = widget.debriefEpisode;
    final store = widget.progressStore;
    if (episode == null || store == null) return false;
    return store.isDebriefPending(episode.id);
  }

  Future<void> _openDebrief() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CafeDebriefScreen(
        db: widget.db,
        episode: widget.debriefEpisode!,
        progressStore: widget.progressStore!,
        languageId: widget.languageId,
        bridge: widget.bridge,
      ),
    ));
    if (mounted) _load();
  }

  static const _labels = {
    CafeGuest.wirtin: 'Die Wirtin',
    CafeGuest.schulkind: 'Das Schulkind',
    CafeGuest.vielredner: 'Der Vielredner',
    CafeGuest.gleichaltrige: 'Die Gleichaltrige',
  };

  static const _keys = {
    CafeGuest.wirtin: 'cafe-guest-wirtin',
    CafeGuest.schulkind: 'cafe-guest-schulkind',
    CafeGuest.vielredner: 'cafe-guest-vielredner',
    CafeGuest.gleichaltrige: 'cafe-guest-gleichaltrige',
  };

  @override
  Widget build(BuildContext context) {
    final occupancy = _occupancy;
    return Scaffold(
      key: const ValueKey('cafe-screen'),
      appBar: AppBar(title: const Text('Café')),
      body: occupancy == null
          ? const Center(child: CircularProgressIndicator())
          : occupancy.isEmpty
              ? ListView(
                  key: const ValueKey('cafe-empty'),
                  children: [
                    _scene(sceneAsset(CafeMotif.wirtinTresen, _light),
                        keyName: 'cafe-scene-empty', height: 200),
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Die Wirtin wischt den Tresen und nickt dir zu.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : ListView(
                  key: const ValueKey('cafe-guest-list'),
                  children: [
                    _scene(sceneAsset(CafeMotif.leer, _light),
                        keyName: 'cafe-scene-room', height: 200),
                    for (final guest in CafeGuest.values)
                      if (occupancy.present.contains(guest))
                        ListTile(
                          key: ValueKey(_keys[guest]!),
                          leading: SizedBox(
                            width: 96,
                            height: 64,
                            child: _scene(
                                sceneAsset(stammplatzOf(guest), _light),
                                keyName: 'cafe-scene-guest-${guest.name}',
                                height: 64),
                          ),
                          title: Text(_labels[guest]!),
                          subtitle: guest == CafeGuest.wirtin && _debriefPending
                              ? const Text(wirtinDebriefInvite,
                                  key: ValueKey('cafe-debrief-invite'))
                              : null,
                          onTap: () async {
                            if (guest == CafeGuest.wirtin && _debriefPending) {
                              await _openDebrief();
                              return;
                            }
                            await Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                              builder: (_) => CafeTurnScreen(
                                db: widget.db,
                                guest: guest,
                                languageId: widget.languageId,
                                bridge: widget.bridge,
                                episodes: widget.episodes,
                              ),
                            ));
                            // On return, the due state may have changed —
                            // recompute this session's occupancy (still
                            // once-per-visit, just refreshed after a turn
                            // set).
                            if (mounted) _load();
                          },
                        ),
                  ],
                ),
    );
  }
}
