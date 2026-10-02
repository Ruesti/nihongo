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

  /// Panel-Variante, die nach Erfolg dieser Interaktion einblendet (§2.4).
  final String? reactionAsset;

  /// Deutsche Erzählzeile zur Reaktion.
  final String? reactionCaption;

  /// Deutsche Aufgabenzeile aus dem Drehbuch (ersetzt den Standardtext
  /// des Sheets). Null = generischer Text.
  final String? promptText;

  /// Explizites Sprech-/Zeichenziel. Null = Ableitung aus den
  /// Panel-Bubbles (bisheriges Verhalten).
  final String? target;

  /// Explizite SRS-Buchung bei Erfolg. Null = Ableitung aus den
  /// Bubble-Tokens; leere Liste = Erfolg reagiert nur erzählerisch
  /// (z. B. Glyph-Momente wie め, die kein Lexem sind).
  final List<String>? targetItemIds;

  const StoryInteraction({
    required this.type,
    required this.diegetic,
    this.optional = true,
    this.reactionAsset,
    this.reactionCaption,
    this.promptText,
    this.target,
    this.targetItemIds,
  });

  factory StoryInteraction.fromJson(Map<String, dynamic> j) => StoryInteraction(
        type: InteractionType.values.byName(j['type'] as String),
        diegetic: j['diegetic'] as bool? ?? false,
        optional: j['optional'] as bool? ?? true,
        reactionAsset: j['reactionAsset'] as String?,
        reactionCaption: j['reactionCaption'] as String?,
        promptText: j['promptText'] as String?,
        target: j['target'] as String?,
        targetItemIds: (j['targetItemIds'] as List?)?.cast<String>(),
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

/// „Man kann auch sagen …" — eine Variante, die die Wirtin in der
/// Nachbesprechung nennt (Spec Café-Nachbesprechung §3.3/§4). Wissen am
/// eingeführten Wort, NIE ein eigenes Item: keine Karteikarte, nie abgefragt.
class DebriefVariant {
  final String form;
  final String reading;
  final String meaning;
  final String? note;

  const DebriefVariant({
    required this.form,
    required this.reading,
    required this.meaning,
    this.note,
  });

  factory DebriefVariant.fromJson(Map<String, dynamic> j) => DebriefVariant(
        form: j['form'] as String,
        reading: j['reading'] as String? ?? j['form'] as String,
        meaning: j['meaning'] as String,
        note: j['note'] as String?,
      );
}

/// Der Erklärungsblock der Wirtin zu einem Budget-Item (Spec §5.1):
/// Gebrauch in ein bis zwei Sätzen plus höchstens zwei Varianten.
class DebriefNote {
  final String usage;
  final List<DebriefVariant> variants;

  const DebriefNote({required this.usage, this.variants = const []});

  factory DebriefNote.fromJson(Map<String, dynamic> j) => DebriefNote(
        usage: j['usage'] as String,
        variants: [
          for (final v in (j['variants'] as List? ?? const []))
            DebriefVariant.fromJson(v as Map<String, dynamic>),
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

  /// Deutsche Anmoderation der Titelkarte (Spec Reader-Erleben §2.1).
  final String? intro;

  /// Deutscher Erzählhaken der Endkarte (§2.6).
  final String? outro;

  /// Erklärungsblöcke der Wirtin je Budget-Item-Id (Spec Café-Nachbesprechung
  /// §5.1). Optional: fehlt der Block, zeigt die Karte nur Wort, Lesung,
  /// Bedeutung und die Stelle in der Folge.
  final Map<String, DebriefNote> debrief;

  const Episode({
    required this.id,
    required this.seasonId,
    required this.orderIndex,
    required this.title,
    required this.locale,
    required this.era,
    required this.budget,
    required this.pages,
    this.intro,
    this.outro,
    this.debrief = const {},
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
        intro: j['intro'] as String?,
        outro: j['outro'] as String?,
        debrief: {
          for (final e in ((j['debrief'] as Map?) ?? const {}).entries)
            e.key as String:
                DebriefNote.fromJson(e.value as Map<String, dynamic>),
        },
      );

  /// All panels across all pages, in reading order.
  Iterable<StoryPanel> get allPanels => pages.expand((p) => p.panels);
}
