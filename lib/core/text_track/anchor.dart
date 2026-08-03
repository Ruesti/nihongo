import '../db/mining_db.dart';

/// The unified text-track positioning model (SPEC_MINING_PIPELINE.md
/// §5). "Reader and player are not two features. Both media types
/// reduce to a work with a positioned text track; only the positioning
/// axis differs." This sealed hierarchy *is* that axis, typed — the
/// exhaustive `switch` a consumer writes over it is the compiler
/// enforcing that every medium is handled.
sealed class Anchor {
  const Anchor();
}

/// EPUB / plain text: positioned by character offset in the work's flow.
class FlowAnchor extends Anchor {
  final int charStart;
  final int charEnd;

  const FlowAnchor({required this.charStart, required this.charEnd});
}

/// Subtitles (SRT/ASS): positioned by time interval. Audio is
/// extractable from this (§0.3.9, and see Phase 5 card assembly).
class TimeAnchor extends Anchor {
  final Duration start;
  final Duration end;

  const TimeAnchor({required this.start, required this.end});
}

/// Manga (OCR): positioned by a bounding box on a page. Phase 12 per
/// the §11 risk gate — modelled here so the unified track is genuinely
/// complete, not so it's exercised yet.
class SpatialAnchor extends Anchor {
  final String pageId;
  final String rectJson; // {left,top,right,bottom} — no Rect dep in core

  const SpatialAnchor({required this.pageId, required this.rectJson});
}

/// §5's `TextSpan_`: a work-positioned text unit, medium-independent.
/// Named [PositionedSpan] to avoid colliding with the Drift-generated
/// `TextSpan` row type (and Flutter's own `TextSpan`) — this is the
/// in-memory unified view a renderer consumes, decoupled from storage.
class PositionedSpan {
  final String id;
  final String workId;
  final int ordinal; // reading order, medium-independent
  final String text;
  final Anchor anchor;

  const PositionedSpan({
    required this.id,
    required this.workId,
    required this.ordinal,
    required this.text,
    required this.anchor,
  });

  /// The reduction itself: any stored [TextSpan] row (SRT-sourced,
  /// EPUB-sourced, or eventually OCR-sourced) collapses to one
  /// [PositionedSpan] here. The single place that reads `anchorType`
  /// and the medium-specific columns — everything downstream sees only
  /// the typed [Anchor], never the storage discriminator.
  factory PositionedSpan.fromRow(TextSpan row) {
    final anchor = switch (row.anchorType) {
      'flow' => FlowAnchor(
          charStart: row.charStart ?? 0,
          charEnd: row.charEnd ?? row.content.length,
        ),
      'time' => TimeAnchor(
          start: Duration(milliseconds: row.tStartMs ?? 0),
          end: Duration(milliseconds: row.tEndMs ?? 0),
        ),
      'spatial' => SpatialAnchor(
          pageId: row.pageId ?? '',
          rectJson: row.rectJson ?? '{}',
        ),
      _ => throw ArgumentError(
          'Unknown anchorType "${row.anchorType}" on span ${row.id}'),
    };
    return PositionedSpan(
      id: row.id,
      workId: row.workId,
      ordinal: row.ordinal,
      text: row.content,
      anchor: anchor,
    );
  }
}
