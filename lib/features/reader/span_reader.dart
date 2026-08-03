import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';

/// A thin, medium-agnostic renderer for one text span's tokens
/// (SPEC_MINING_PIPELINE.md §5): "A renderer knows how to draw spans
/// and report taps; it knows nothing about vocabulary, scheduling, or
/// Datum."
///
/// This widget imports exactly two things beyond Flutter itself: the
/// [Token] type (its input) and — nothing else. No database, no
/// scoring/FSRS/card-assembly pipeline, no Datum. That import list is
/// the "renderer contains zero vocabulary logic, verified by
/// inspection" gate criterion, made mechanically checkable rather than
/// asserted. It renders [Token]s and calls [onWordTap]; where those
/// tokens came from (EPUB flow or SRT time track) it cannot tell and
/// does not care.
///
/// Optional [furiganaByCharStart] lets a reading be drawn above a
/// token (keyed by the token's `charStart`) — still pure presentation,
/// the reading is supplied by the caller, not looked up here.
class SpanReader extends StatelessWidget {
  final List<Token> tokens;
  final void Function(Token token) onWordTap;
  final Map<int, String>? furiganaByCharStart;
  final TextStyle? style;

  const SpanReader({
    super.key,
    required this.tokens,
    required this.onWordTap,
    this.furiganaByCharStart,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return Wrap(
      spacing: 0,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final token in tokens)
          _TappableWord(
            token: token,
            reading: furiganaByCharStart?[token.charStart],
            style: baseStyle,
            onTap: () => onWordTap(token),
          ),
      ],
    );
  }
}

class _TappableWord extends StatelessWidget {
  final Token token;
  final String? reading;
  final TextStyle style;
  final VoidCallback onTap;

  const _TappableWord({
    required this.token,
    required this.reading,
    required this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reading != null)
            Text(reading!, style: style.copyWith(fontSize: (style.fontSize ?? 14) * 0.6)),
          Text(token.surface, style: style),
        ],
      ),
    );
  }
}
