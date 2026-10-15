import 'package:flutter/material.dart';

import '../cafe_occupancy.dart';
import '../cafe_scenes.dart';
import '../cafe_visit.dart';

typedef Speak = Future<void> Function(String text);

const stationTitles = {
  CafeStation.wirtin: 'Die Wirtin',
  CafeStation.schulmaedchen: 'Das Schulmädchen',
  CafeStation.vielredner: 'Der alte Mann',
  CafeStation.gleichaltrige: 'Die Gleichaltrige',
};

CafeGuest guestOf(CafeStation s) => switch (s) {
      CafeStation.wirtin => CafeGuest.wirtin,
      CafeStation.schulmaedchen => CafeGuest.schulkind,
      CafeStation.vielredner => CafeGuest.vielredner,
      CafeStation.gleichaltrige => CafeGuest.gleichaltrige,
    };

/// Gemeinsamer Rahmen aller Stationen (Spec §3): Kopfbild des Gastes,
/// eine Zeile in seiner Stimme, der Inhalt, unten „Weiter" und „Später
/// weiter". Keine Zähler (INV-10).
class StationFrame extends StatelessWidget {
  final CafeStation station;
  final CafeLight light;
  final String voiceLine;
  final Widget child;
  final VoidCallback? onNext;
  final String nextLabel;
  final VoidCallback? onLater;

  const StationFrame({
    super.key,
    required this.station,
    required this.light,
    required this.voiceLine,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Weiter',
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stationTitles[station]!)),
      body: Column(
        children: [
          Image.asset(
            sceneAsset(stammplatzOf(guestOf(station)), light),
            key: const ValueKey('cafe-station-scene'),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) =>
                Container(height: 120, color: const Color(0xFF2A3035)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(voiceLine,
                  key: const ValueKey('cafe-station-voice'),
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ),
          Expanded(child: SingleChildScrollView(child: child)),
          SafeArea(
            top: false,
            child: Row(
              children: [
                if (onLater != null)
                  TextButton(
                    key: const ValueKey('cafe-station-later'),
                    onPressed: onLater,
                    child: const Text('Später weiter'),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton(
                    key: const ValueKey('cafe-station-next'),
                    onPressed: onNext,
                    child: Text(nextLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
