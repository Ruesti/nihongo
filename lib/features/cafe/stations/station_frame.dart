import 'package:flutter/material.dart';

import '../../story/episode.dart';
import '../cafe_occupancy.dart';
import '../cafe_overlay.dart';
import '../cafe_portrait_library.g.dart';
import '../cafe_portraits.dart';
import '../cafe_scenes.dart';
import '../cafe_visit.dart';
import '../cafe_voice.dart';

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

/// Gemeinsamer Rahmen aller Stationen (Spec §3): Der Gast füllt als Bild
/// den ganzen Schirm, darüber liegen Zurück-Chip, Sprechblase mit seiner
/// Zeile und die Fläche mit dem Inhalt; unten „Weiter" und „Später weiter".
/// Die Zeile wird in der Stimme des Gasts gesprochen. Keine Zähler (INV-10).
class StationFrame extends StatefulWidget {
  final CafeStation station;
  final CafeLight light;
  final CafeMood mood;
  final int variant;
  final String line;
  final Widget child;
  final VoidCallback? onNext;
  final String nextLabel;
  final VoidCallback? onLater;
  final CafeVoice? voice;
  final Widget? bubbleTrailing;

  /// Nur für Tests einspeisbar; geht an [resolvePortrait].
  final Map<String, Map<String, List<int>>> files;

  const StationFrame({
    super.key,
    required this.station,
    required this.light,
    required this.mood,
    required this.variant,
    required this.line,
    required this.child,
    required this.onNext,
    this.nextLabel = 'Weiter',
    this.onLater,
    this.voice,
    this.bubbleTrailing,
    this.files = cafePortraitFiles,
  });

  @override
  State<StationFrame> createState() => _StationFrameState();
}

class _StationFrameState extends State<StationFrame> {
  @override
  void initState() {
    super.initState();
    widget.voice?.say(guestOf(widget.station), widget.line);
  }

  @override
  void didUpdateWidget(StationFrame old) {
    super.didUpdateWidget(old);
    if (old.line != widget.line) {
      widget.voice?.say(guestOf(widget.station), widget.line);
    }
  }

  @override
  void dispose() {
    widget.voice?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final format = orientation == Orientation.portrait
        ? PanelFormat.portrait
        : PanelFormat.landscape;
    final choice = resolvePortrait(guestOf(widget.station), widget.mood,
        widget.variant, format, widget.light,
        files: widget.files);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D21),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              choice.asset,
              key: const ValueKey('cafe-station-scene'),
              fit: choice.letterbox ? BoxFit.contain : BoxFit.cover,
              alignment: choice.isPortrait
                  ? Alignment.topCenter
                  : Alignment.centerLeft,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFF2A3035)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: CafeBackChip(
                onPressed: () => Navigator.of(context).maybePop()),
          ),
          CafeOverlay(
            bubble: GuestBubble(
              name: stationTitles[widget.station]!,
              line: widget.line,
              tail: tailFor(orientation),
              trailing: widget.bubbleTrailing,
            ),
            bottom: Row(
              children: [
                if (widget.onLater != null)
                  TextButton(
                    key: const ValueKey('cafe-station-later'),
                    onPressed: widget.onLater,
                    child: const Text('Später weiter'),
                  ),
                const Spacer(),
                FilledButton(
                  key: const ValueKey('cafe-station-next'),
                  onPressed: widget.onNext,
                  child: Text(widget.nextLabel),
                ),
              ],
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
