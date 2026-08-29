import '../../core/ladder/rung_defs.dart' show RefType;

/// A reference to a budgeted vocabulary/grammar item within an episode.
/// Within P1 this is a free-standing content slug; binding it to a real
/// LearnItem row is a later (P5) concern.
class ItemRef {
  final String id;
  final RefType refType;

  /// True only for items the brief explicitly exempts from the ≥2-panel
  /// repetition rule (INV-4).
  final bool singleton;

  const ItemRef({
    required this.id,
    required this.refType,
    this.singleton = false,
  });

  factory ItemRef.fromJson(Map<String, dynamic> j) => ItemRef(
        id: j['id'] as String,
        refType: RefType.values.byName(j['refType'] as String),
        singleton: j['singleton'] as bool? ?? false,
      );
}

/// A kana/kanji glyph budgeted for an episode (distinct from vocabulary
/// items — see docs/story/BRIEF_STORY_ENGINE.md §2).
class GlyphRef {
  final String glyph;
  const GlyphRef(this.glyph);
  factory GlyphRef.fromJson(Map<String, dynamic> j) =>
      GlyphRef(j['glyph'] as String);
}

class EpisodeBudget {
  final List<ItemRef> items;
  final List<GlyphRef> glyphs;

  const EpisodeBudget({required this.items, required this.glyphs});

  factory EpisodeBudget.fromJson(Map<String, dynamic> j) => EpisodeBudget(
        items: [
          for (final i in (j['items'] as List? ?? const []))
            ItemRef.fromJson(i as Map<String, dynamic>),
        ],
        glyphs: [
          for (final g in (j['glyphs'] as List? ?? const []))
            GlyphRef.fromJson(g as Map<String, dynamic>),
        ],
      );
}

/// A point in normalized (0..1) panel space.
class StoryPoint {
  final double x, y;
  const StoryPoint(this.x, this.y);

  factory StoryPoint.fromJson(Map<String, dynamic> j) => StoryPoint(
        (j['x'] as num).toDouble(),
        (j['y'] as num).toDouble(),
      );
}

/// A bubble hit-area. Empty until real panel artwork exists to trace it
/// against (deferred to the panel-reader phase, P2/P3).
class StoryPolygon {
  final List<StoryPoint> points;
  const StoryPolygon(this.points);

  factory StoryPolygon.fromJson(List<dynamic>? j) => StoryPolygon([
        for (final p in (j ?? const []))
          StoryPoint.fromJson(p as Map<String, dynamic>),
      ]);
}

class StoryToken {
  final String surface;
  final String? reading;
  final String? itemId;

  /// False only for locked kanji (INV-7) — tapping does nothing, no hint,
  /// no lock message. True for every kana token.
  final bool lookupable;

  const StoryToken({
    required this.surface,
    this.reading,
    this.itemId,
    required this.lookupable,
  });

  factory StoryToken.fromJson(Map<String, dynamic> j) => StoryToken(
        surface: j['surface'] as String,
        reading: j['reading'] as String?,
        itemId: j['itemId'] as String?,
        lookupable: j['lookupable'] as bool? ?? true,
      );
}

class StoryBubble {
  final String speakerId;
  final String text;
  final String? audioRef;
  final StoryPolygon hitArea;
  final List<StoryToken> tokens;

  const StoryBubble({
    required this.speakerId,
    required this.text,
    this.audioRef,
    required this.hitArea,
    required this.tokens,
  });

  factory StoryBubble.fromJson(Map<String, dynamic> j) => StoryBubble(
        speakerId: j['speakerId'] as String,
        text: j['text'] as String,
        audioRef: j['audioRef'] as String?,
        hitArea: StoryPolygon.fromJson(j['hitArea'] as List?),
        tokens: [
          for (final t in (j['tokens'] as List? ?? const []))
            StoryToken.fromJson(t as Map<String, dynamic>),
        ],
      );
}

/// A learner's-native-language thought bubble (never target-language).
class StoryThought {
  final String text;
  const StoryThought(this.text);
  factory StoryThought.fromJson(Map<String, dynamic> j) =>
      StoryThought(j['text'] as String);
}

enum InteractionType { reveal, listen, speak, trace, dictionary }

class StoryInteraction {
  final InteractionType type;

  /// True if this interaction is part of the fiction (e.g. a phone call
  /// scene inviting speech) rather than a bolt-on practice prompt.
  final bool diegetic;

  /// Always true in story mode (INV-1) — no interaction may gate reading.
  final bool optional;

  const StoryInteraction({
    required this.type,
    required this.diegetic,
    this.optional = true,
  });

  factory StoryInteraction.fromJson(Map<String, dynamic> j) => StoryInteraction(
        type: InteractionType.values.byName(j['type'] as String),
        diegetic: j['diegetic'] as bool? ?? false,
        optional: j['optional'] as bool? ?? true,
      );
}

class StoryPanel {
  final int index;
  final String asset;
  final List<StoryBubble> bubbles;
  final List<StoryThought> thoughts;
  final List<StoryInteraction> interactions;

  /// Recurring camera axis id (e.g. "A1") — see docs/story/VISUAL_STYLE.md.
  /// Null when the panel does not reuse one of the series' fixed anchors.
  final String? anchorShot;

  /// Author commentary. Never rendered to the reader.
  final String notes;

  const StoryPanel({
    required this.index,
    required this.asset,
    required this.bubbles,
    required this.thoughts,
    required this.interactions,
    this.anchorShot,
    this.notes = '',
  });

  factory StoryPanel.fromJson(Map<String, dynamic> j) => StoryPanel(
        index: j['index'] as int,
        asset: j['asset'] as String,
        bubbles: [
          for (final b in (j['bubbles'] as List? ?? const []))
            StoryBubble.fromJson(b as Map<String, dynamic>),
        ],
        thoughts: [
          for (final t in (j['thoughts'] as List? ?? const []))
            StoryThought.fromJson(t as Map<String, dynamic>),
        ],
        interactions: [
          for (final i in (j['interactions'] as List? ?? const []))
            StoryInteraction.fromJson(i as Map<String, dynamic>),
        ],
        anchorShot: j['anchorShot'] as String?,
        notes: j['notes'] as String? ?? '',
      );
}

class StoryPage {
  final int index;
  final List<StoryPanel> panels;

  const StoryPage({required this.index, required this.panels});

  factory StoryPage.fromJson(Map<String, dynamic> j) => StoryPage(
        index: j['index'] as int,
        panels: [
          for (final p in (j['panels'] as List? ?? const []))
            StoryPanel.fromJson(p as Map<String, dynamic>),
        ],
      );
}

class Episode {
  final String id;
  final String seasonId;
  final int orderIndex;
  final String title;
  final String locale;
  final String era;
  final EpisodeBudget budget;
  final List<StoryPage> pages;

  const Episode({
    required this.id,
    required this.seasonId,
    required this.orderIndex,
    required this.title,
    required this.locale,
    required this.era,
    required this.budget,
    required this.pages,
  });

  factory Episode.fromJson(Map<String, dynamic> j) => Episode(
        id: j['id'] as String,
        seasonId: j['seasonId'] as String,
        orderIndex: j['orderIndex'] as int,
        title: j['title'] as String,
        locale: j['locale'] as String,
        era: j['era'] as String,
        budget: EpisodeBudget.fromJson(j['budget'] as Map<String, dynamic>? ?? const {}),
        pages: [
          for (final p in (j['pages'] as List? ?? const []))
            StoryPage.fromJson(p as Map<String, dynamic>),
        ],
      );

  /// All panels across all pages, in reading order.
  Iterable<StoryPanel> get allPanels => pages.expand((p) => p.panels);
}
