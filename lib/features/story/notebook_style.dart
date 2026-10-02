import 'package:flutter/material.dart';

/// Der Notizbuch-Look der Wörterkarte und der Wortliste (Uli, 2.10.: „optisch
/// schön, zum Rest passend, wie ein altes Notizbuch"). Farben aus der
/// Papier-Palette der App (`AppColors`), Linien wie in einem Schulheft,
/// Lochung am linken Rand, rote Randlinie. Japanisch in Klee One
/// (Schulheft-Handschrift), Deutsch in Caveat (Füller) — beide gebündelt
/// unter assets/fonts/, damit es ohne Netz läuft.
abstract final class Notebook {
  static const paper = Color(0xFFF4EDE0);
  static const paperDark = Color(0xFFEDE4D3);
  static const binding = Color(0xFFE6DCC8);
  static const hole = Color(0xFFCBBFA8);
  static const line = Color(0xFFD6C9B5);
  static const ink = Color(0xFF1A1410);
  static const ink2 = Color(0xFF6B5F52);
  static const pencil = Color(0xFF8C8072);
  static const red = Color(0xFF8A1315);
  static const marginLine = Color(0x59B5191C);

  static const jaFont = 'KleeOne';
  static const handFont = 'Caveat';

  /// Abstand der Linien; jede Zeile des Inhalts ist genau so hoch, damit der
  /// Text auf der Linie sitzt.
  static const lineHeight = 44.0;

  /// Breite der Lochleiste links.
  static const bindingWidth = 30.0;

  /// X der roten Randlinie und linker Innenabstand des Inhalts.
  static const marginX = 66.0;
  static const contentLeft = 76.0;

  static const ja = TextStyle(
    fontFamily: jaFont,
    color: ink,
    fontSize: 24,
    height: 1.1,
  );

  static const hand = TextStyle(
    fontFamily: handFont,
    color: ink,
    fontSize: 24,
    height: 1.0,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const handBold = TextStyle(
    fontFamily: handFont,
    color: ink,
    fontSize: 30,
    height: 1.0,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.1,
    color: ink2,
  );
}

/// Eine Notizbuchseite: Papier mit Linien, Lochleiste, roter Randlinie. Der
/// [child] liegt rechts der Randlinie; seine Zeilen sollten
/// [Notebook.lineHeight] hoch sein, dann sitzt der Text auf den Linien. Die
/// Linien beginnen unter [topPadding].
class NotebookPaper extends StatelessWidget {
  final Widget child;
  final double topPadding;
  final double rightPadding;
  final double bottomPadding;

  const NotebookPaper({
    super.key,
    required this.child,
    this.topPadding = 14,
    this.rightPadding = 12,
    this.bottomPadding = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _RuledPainter(topPadding: topPadding),
          ),
        ),
        const Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: Notebook.bindingWidth,
          child: _BindingStrip(),
        ),
        const Positioned(
          left: Notebook.marginX,
          top: 0,
          bottom: 0,
          width: 1,
          child: ColoredBox(color: Notebook.marginLine),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              Notebook.contentLeft, topPadding, rightPadding, bottomPadding),
          child: child,
        ),
      ],
    );
  }
}

class _RuledPainter extends CustomPainter {
  final double topPadding;
  const _RuledPainter({required this.topPadding});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Notebook.paper);
    final paint = Paint()
      ..color = Notebook.line
      ..strokeWidth = 1;
    for (var y = topPadding + Notebook.lineHeight - 0.5;
        y < size.height;
        y += Notebook.lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter old) => old.topPadding != topPadding;
}

class _BindingStrip extends StatelessWidget {
  const _BindingStrip();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Notebook.binding,
        border: Border(right: BorderSide(color: Notebook.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxHeight / 70).floor().clamp(3, 12);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: Notebook.hole,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x59000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Eine Wortzeile im Notizbuch: Japanisch (bei Kanji mit kleiner Lesung
/// darüber), deutsche Bedeutung in Handschrift, Lautsprecher rechts, roter
/// Haken am Rand bei gelernten Wörtern.
class NotebookWordRow extends StatelessWidget {
  final String surface;
  final String? reading;
  final String meaning;
  final bool known;
  final VoidCallback onSpeak;
  final Key rowKey;
  final Key speakKey;
  final Key knownKey;

  const NotebookWordRow({
    super.key,
    required this.surface,
    required this.reading,
    required this.meaning,
    required this.known,
    required this.onSpeak,
    required this.rowKey,
    required this.speakKey,
    required this.knownKey,
  });

  @override
  Widget build(BuildContext context) {
    final showReading = reading != null && reading != surface;
    return SizedBox(
      key: rowKey,
      height: Notebook.lineHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (known)
            Positioned(
              left: -28,
              bottom: 8,
              child: Icon(Icons.check, key: knownKey, size: 18,
                  color: Notebook.red),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 110),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5, right: 10),
                  child: showReading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(reading!,
                                  style: Notebook.ja.copyWith(
                                      fontSize: 11, color: Notebook.ink2)),
                            ),
                            Text(surface, style: Notebook.ja),
                          ],
                        )
                      : Text(surface, style: Notebook.ja),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(meaning,
                      style: Notebook.hand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              IconButton(
                key: speakKey,
                icon: const Icon(Icons.volume_up_outlined),
                color: Notebook.ink2,
                tooltip: '$surface anhören',
                onPressed: onSpeak,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Eine Zeile Fließtext auf der Linie (Untertitel, Hinweis, Randnotiz).
class NotebookLine extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double tilt;
  final Key? textKey;

  const NotebookLine(this.text,
      {super.key, required this.style, this.tilt = 0, this.textKey});

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          key: textKey,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
    return SizedBox(
      height: Notebook.lineHeight,
      child: Align(
        alignment: Alignment.bottomLeft,
        child: tilt == 0
            ? child
            : Transform.rotate(angle: tilt, alignment: Alignment.bottomLeft,
                child: child),
      ),
    );
  }
}
