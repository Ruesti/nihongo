import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Renders Japanese text with optional furigana (reading) above kanji.
/// Format for furigana: pass pairs of (kanji, reading).
class FuriganaText extends StatelessWidget {
  final List<FuriganaSpan> spans;
  final TextStyle? style;
  final bool showFurigana;
  final TextAlign textAlign;

  const FuriganaText({
    super.key,
    required this.spans,
    this.style,
    this.showFurigana = true,
    this.textAlign = TextAlign.start,
  });

  /// Simple constructor for plain Japanese text (no furigana).
  factory FuriganaText.plain(String text, {TextStyle? style}) {
    return FuriganaText(
      spans: [FuriganaSpan(text: text)],
      style: style,
    );
  }

  /// Parses a text with furigana notation like 食[た]べる → 食 with た above.
  factory FuriganaText.parse(String text, {TextStyle? style, bool showFurigana = true}) {
    final spans = <FuriganaSpan>[];
    final regex = RegExp(r'([^\[]+)\[([^\]]+)\]');
    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(FuriganaSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(FuriganaSpan(text: match.group(1)!, furigana: match.group(2)));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(FuriganaSpan(text: text.substring(lastEnd)));
    }
    return FuriganaText(
      spans: spans,
      style: style,
      showFurigana: showFurigana,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainStyle = style ?? AppTheme.jpBody;

    return Wrap(
      alignment: textAlign == TextAlign.center
          ? WrapAlignment.center
          : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: spans.map((span) {
        if (span.furigana != null && showFurigana) {
          return _FuriganaUnit(
            text: span.text,
            furigana: span.furigana!,
            mainStyle: mainStyle,
          );
        }
        return Text(span.text, style: mainStyle);
      }).toList(),
    );
  }
}

class _FuriganaUnit extends StatelessWidget {
  final String text;
  final String furigana;
  final TextStyle mainStyle;

  const _FuriganaUnit({
    required this.text,
    required this.furigana,
    required this.mainStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          furigana,
          style: AppTheme.furigana,
          textAlign: TextAlign.center,
        ),
        Text(text, style: mainStyle),
      ],
    );
  }
}

class FuriganaSpan {
  final String text;
  final String? furigana;

  const FuriganaSpan({required this.text, this.furigana});
}
