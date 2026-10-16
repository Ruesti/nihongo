import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'cafe_voice.dart';

/// Richtung der Sprechblasen-Spitze: nach oben (hoch) oder nach links (quer).
enum TailDirection { up, left }

/// Hochformat: Spitze nach oben, Querformat: Spitze nach links (zur Person).
TailDirection tailFor(Orientation o) =>
    o == Orientation.portrait ? TailDirection.up : TailDirection.left;

const _bubbleFill = Color(0xF2FFF8E7);

/// Grund der Fläche und hinter Bildern (dunkel).
const cafeDark = Color(0xFF1A1D21);
const _overlayFill = Color(0xCC1A1D21);

/// Helles Rosa für Ränder/Schrift von Tasten und Kacheln auf der dunklen
/// Fläche (Kontrast ≥ 4,5:1 auch über einem hellen Bild).
const cafeOnDarkAccent = Color(0xFFFFB4A8);
const _appRed = Color(0xFFB5191C); // AppColors.red

/// Dunkles Theme für den Inhalt der Fläche: das App-Theme ist hell (Tinte
/// auf Papier) und wäre auf der dunklen Fläche kaum lesbar.
ThemeData cafeOverlayTheme(ThemeData base) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _appRed,
    brightness: Brightness.dark,
  ).copyWith(
    surface: cafeDark,
    onSurface: Colors.white,
    primary: cafeOnDarkAccent,
    onPrimary: cafeDark,
  );
  final keyStyle = ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.disabled)
            ? Colors.white38
            : cafeOnDarkAccent),
    side: WidgetStateProperty.resolveWith((states) => BorderSide(
        color: states.contains(WidgetState.disabled)
            ? Colors.white24
            : cafeOnDarkAccent)),
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: base.textTheme
        .apply(bodyColor: Colors.white, displayColor: Colors.white),
    iconTheme: const IconThemeData(color: Colors.white),
    // Eigene Vordergrundfarbe zuerst; Schrift/Abstände aus dem App-Theme.
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(foregroundColor: keyStyle.foregroundColor)
          .merge(base.textButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: keyStyle),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _appRed,
        foregroundColor: Colors.white,
      ),
    ),
  );
}
const _bubbleBorder = Color(0xFF444444);
const _tailSize = 12.0;

/// Halbtransparente Fläche über dem Gästebild (Hochformat unten, höchstens
/// halbe Höhe und so klein wie der Inhalt; Querformat rechts, ein Drittel der
/// Breite, mindestens 360 dp, höchstens die Hälfte, volle Höhe).
class CafeOverlay extends StatelessWidget {
  final Widget bubble;
  final Widget child;
  final Widget? bottom;
  const CafeOverlay({
    super.key,
    required this.bubble,
    required this.child,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    final darkTheme = cafeOverlayTheme(Theme.of(context));
    Widget dark(Widget w) => Theme(
          data: darkTheme,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: w,
          ),
        );

    Widget panel({required MainAxisSize mainAxisSize, required bool expand}) {
      final scroll = SingleChildScrollView(child: child);
      return DecoratedBox(
        key: const ValueKey('cafe-overlay'),
        decoration: const BoxDecoration(color: _overlayFill),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: Column(
            mainAxisSize: mainAxisSize,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Die Blase bleibt hell (eigene Farben), der Rest wird dunkel.
              bubble,
              expand
                  ? Expanded(child: dark(scroll))
                  : Flexible(child: dark(scroll)),
              if (bottom != null) dark(bottom!),
            ],
          ),
        ),
      );
    }

    if (landscape) {
      final w = math.max(size.width / 3, 360.0).clamp(0.0, size.width / 2);
      return Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: w,
          height: size.height,
          child: panel(mainAxisSize: MainAxisSize.max, expand: true),
        ),
      );
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          maxHeight: size.height / 2,
        ),
        child: panel(mainAxisSize: MainAxisSize.min, expand: false),
      ),
    );
  }
}

/// Sprechblase des Gasts: kleiner Name, darunter die Zeile, mit Spitze zur
/// Person. [trailing] steht rechts in der Namenszeile (z. B. Lautsprecher).
class GuestBubble extends StatelessWidget {
  final String name;
  final String line;
  final TailDirection tail;
  final Widget? trailing;
  const GuestBubble({
    super.key,
    required this.name,
    required this.line,
    required this.tail,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: _bubbleFill,
        border: Border.all(color: _bubbleBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Color(0xFF222222)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    key: const ValueKey('cafe-station-name'),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              ?trailing,
            ]),
            const SizedBox(height: 2),
            Text(line,
                key: const ValueKey('cafe-station-voice'),
                style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
    final tailPaint = CustomPaint(
      size: tail == TailDirection.up
          ? const Size(_tailSize * 2, _tailSize)
          : const Size(_tailSize, _tailSize * 2),
      painter: _TailPainter(tail),
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: tail == TailDirection.up
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Align(alignment: Alignment.centerLeft, child: tailPaint),
                ),
                body,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 16), child: tailPaint),
                Expanded(child: body),
              ],
            ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final TailDirection dir;
  _TailPainter(this.dir);

  @override
  void paint(Canvas canvas, Size s) {
    final path = Path();
    if (dir == TailDirection.up) {
      path
        ..moveTo(0, s.height)
        ..lineTo(s.width / 2, 0)
        ..lineTo(s.width, s.height);
    } else {
      path
        ..moveTo(s.width, 0)
        ..lineTo(0, s.height / 2)
        ..lineTo(s.width, s.height);
    }
    // Füllung schließt den Rahmen der Blase an der Ansatzkante nahtlos ab.
    canvas.drawPath(path..close(), Paint()..color = _bubbleFill);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _bubbleBorder);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.dir != dir;
}

/// Zurück-Chip oben links (halbtransparenter Kreis, wie im Reader). Die
/// Position legt der Aufrufer fest; die Aussparung für Statusleiste/Notch
/// steckt als [SafeArea] darin.
class CafeBackChip extends StatelessWidget {
  final VoidCallback onPressed;
  const CafeBackChip({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0x99000000),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            key: const ValueKey('cafe-back'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Zurück',
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// Lautsprecher in der Sprechblase: schaltet die Gästestimme an/aus und
/// bricht beim Ausschalten eine laufende Zeile ab.
class CafeVoiceToggle extends StatefulWidget {
  final CafeVoice? voice;
  final CafeVoicePrefs? prefs;
  const CafeVoiceToggle({super.key, this.voice, this.prefs});

  @override
  State<CafeVoiceToggle> createState() => _CafeVoiceToggleState();
}

class _CafeVoiceToggleState extends State<CafeVoiceToggle> {
  late final CafeVoicePrefs _prefs = widget.prefs ?? CafeVoicePrefs();
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _prefs.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    }).catchError((_) {});
  }

  Future<void> _toggle() async {
    final next = !_enabled;
    setState(() => _enabled = next);
    try {
      await _prefs.setEnabled(next);
    } catch (_) {
      // Speichern misslungen: Schalter bleibt trotzdem bedienbar.
    }
    if (!next) await widget.voice?.stop();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const ValueKey('cafe-voice-toggle'),
      tooltip: _enabled ? 'Gäste sprechen' : 'Gäste still',
      visualDensity: VisualDensity.compact,
      icon: Icon(_enabled ? Icons.volume_up : Icons.volume_off),
      onPressed: _toggle,
    );
  }
}
