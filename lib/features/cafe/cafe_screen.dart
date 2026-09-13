import 'package:flutter/material.dart';

import '../../core/db/learning_db.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import 'cafe_occupancy.dart';
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
class CafeScreen extends StatefulWidget {
  final LearningDb db;
  final String languageId;
  final KnowledgeBridge? bridge;

  const CafeScreen({
    super.key,
    required this.db,
    this.languageId = 'lang_ja',
    this.bridge,
  });

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen> {
  CafeOccupancy? _occupancy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final due = await widget.db.getDueItems(widget.languageId, limit: 500);
    if (!mounted) return;
    setState(() => _occupancy = CafeOccupancy.fromDueItems(due));
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

  static const _assets = <CafeGuest, String>{
    CafeGuest.wirtin: 'assets/comic/cafe/cafe_wirtin.jpg',
    CafeGuest.schulkind: 'assets/comic/cafe/cafe_schulkind.jpg',
    CafeGuest.vielredner: 'assets/comic/cafe/cafe_vielredner.jpg',
    CafeGuest.gleichaltrige: 'assets/comic/cafe/cafe_gleichaltrige.jpg',
  };

  /// Panel-Bild; fehlendes Asset zeigt einen neutralen Platzhalter, nie Crash.
  static Widget _panel(String asset, {double? height}) => Image.asset(
        asset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: height ?? 160,
          color: const Color(0xFF2A3035),
        ),
      );

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
                    _panel(_assets[CafeGuest.wirtin]!),
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
                    _panel('assets/comic/cafe/cafe_empty.jpg'),
                    for (final guest in CafeGuest.values)
                      if (occupancy.present.contains(guest))
                        ListTile(
                          key: ValueKey(_keys[guest]!),
                          leading: SizedBox(
                            width: 96,
                            height: 64,
                            child: _panel(_assets[guest]!, height: 64),
                          ),
                          title: Text(_labels[guest]!),
                          onTap: () async {
                            await Navigator.of(context)
                                .push(MaterialPageRoute<void>(
                              builder: (_) => CafeTurnScreen(
                                db: widget.db,
                                guest: guest,
                                languageId: widget.languageId,
                                bridge: widget.bridge,
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
