import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/ladder/encounter.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/audio_button.dart';
import '../kanji_games/trace/kanji_svg_loader.dart';

/// Renders a rung-0 [Encounter] as an ungraded, multisensory first meeting.
/// A single "Weiter" button calls [onDone]. Missing assets degrade to
/// see + hear (never a crash — Asset-Doktrin §6).
class EncounterView extends StatelessWidget {
  final Encounter encounter;
  final VoidCallback onDone;

  const EncounterView({
    super.key,
    required this.encounter,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: _body(context),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton(
            key: const ValueKey('encounter-next'),
            onPressed: onDone,
            child: Text(l.encounterNext),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final e = encounter;
    return switch (e) {
      CharacterEncounter() => _character(context, e),
      LexemeEncounter() => _lexeme(context, e),
      GrammarEncounter() => _grammar(context, e),
    };
  }

  Widget _character(BuildContext context, CharacterEncounter e) {
    return Column(
      children: [
        Text(e.glyph, style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(e.reading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        AudioButton(text: e.audioText, size: 36),
        if (e.strokeOrderAssetId != null) ...[
          const SizedBox(height: 16),
          StrokeOrderView(assetPath: e.strokeOrderAssetId!),
        ],
        if (e.mnemonic != null) ...[
          const SizedBox(height: 12),
          Text(e.mnemonic!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _lexeme(BuildContext context, LexemeEncounter e) {
    return Column(
      children: [
        if (e.conceptImagePath != null && File(e.conceptImagePath!).existsSync())
          Image.file(File(e.conceptImagePath!), height: 140),
        Text(e.writtenForm, style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(e.reading, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(e.meaning, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 12),
        AudioButton(text: e.audioText, size: 36),
        if (e.exampleSentence != null) ...[
          const SizedBox(height: 12),
          Text(e.exampleSentence!,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _grammar(BuildContext context, GrammarEncounter e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.canDoDescription,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(e.plainExplanation,
            style: Theme.of(context).textTheme.bodyLarge),
        if (e.example.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(e.example, style: Theme.of(context).textTheme.bodyMedium),
        ],
        if (e.contrast != null) ...[
          const SizedBox(height: 8),
          Text(e.contrast!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Draws KanjiVG strokes progressively. Falls back to nothing if the asset
/// can't be parsed (loader returns null) — never a crash.
class StrokeOrderView extends StatelessWidget {
  final String assetPath;
  const StrokeOrderView({super.key, required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: KanjiSvgLoader.loadStrokes(assetPath),
      builder: (context, snapshot) {
        final strokes = snapshot.data;
        if (strokes == null || strokes.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _StrokePainter(strokes)),
        );
      },
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    // KanjiSvgLoader samples into a 300px canvas by default; scale to fit.
    final scale = size.width / 300.0;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx * scale, stroke.first.dy * scale);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx * scale, p.dy * scale);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => false;
}
