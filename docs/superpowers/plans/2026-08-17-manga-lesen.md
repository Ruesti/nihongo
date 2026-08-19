# Manga-Lesen — das mitwachsende Comic — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn reading into a real comic — page images with speech bubbles — that starts easy and gets harder as the learner progresses, mixing the UI language (L1) with the target language (L2) in a ramp from mostly-L1 to fully-L2. Works for **any** target language, not just Japanese.

**Architecture:** A prebaked, language-agnostic `ComicPack` (JSON: pages → panels with a placeholder image → bubbles carrying `l1`/`l2` spans + normalized rects + tokens). A new `SpatialReader` renders the image and overlays tappable L2 words (plain L1 text is never tappable or mined); reading-help (furigana/pinyin/romaji) and text direction come from `ScriptProfile`, never a language branch. Comic selection reuses the **existing** `rankByIPlusOne` i+1 selector over the pack's pages, with knowledge from the existing `FsrsKnowledgeSource` (MiningDb). The real ComfyUI art pipeline is external/later (Asset-Doktrin §6); everything here is built and proven against placeholder art.

**Tech Stack:** Dart 3.11, Flutter, Drift 2.22 (MiningDb), Riverpod, fsrs, `flutter_test` with `NativeDatabase.memory()`. Depends on the l10n foundation from the Empfang plan (`AppLocalizations`).

## Global Constraints

- **Package name:** `nihongo_app`. **Working dir (`<WT>`):** `/home/uli/projects/nihongo/.claude/worktrees/spec+onboarding-and-manga`.
- **Target-language-agnostic (I8):** no `if (lang == 'ja')` anywhere. Everything keyed by `languageCode` + `ScriptProfile`. The seam discipline is already documented in `lib/core/language_pack/language_pack.dart`. L2 = the active pack's language; L1 = the active UI locale.
- **Reading-help is generic:** the overlay above an L2 word is `Token.reading` (kana for JA, pinyin for ZH, romaji, …), already nullable in `Token`. Never call it "furigana" in language-blind code.
- **Text direction** from `ScriptProfile.direction` (`ltr`/`rtl`).
- **Offline-first, Asset-Doktrin §6:** the app depends only on the bundled pack + placeholder images, never on ComfyUI at runtime. Missing image → neutral placeholder frame, never a crash.
- **Reader is the review surface:** word tap → gloss (reuse `WordTapHandler`), due card graded in place (reuse `InReadingReviewPanel`), progress measured via `recordPassageSnapshot`.
- **Depends on the Empfang plan** for the learner's known-set (placement + encounters feed `MiningDb`), which the selector reads to pick i+1 content.
- **Token type:** `Token({required surface, required lemma, String? reading, required pos, required charStart, required charEnd})` from `package:nihongo_app/core/language_pack/language_pack.dart`.

## Reused (do NOT rebuild)

Confirmed present in the codebase — the plan wires these, it does not reimplement them:
- `rankByIPlusOne<T>(Iterable<T>, List<Token> Function(T), KnowledgeSource, {IPlusOneWindow window})` → `List<RankedPassage<T>>` with `Fit {tooEasy, ideal, tooHard}` — `lib/core/pipeline/content_selector.dart`.
- `FsrsKnowledgeSource.load(MiningDb, {required String languageCode, double knownStabilityThreshold})` and its `call(String lemma) → Knowledge` — `lib/core/pipeline/fsrs_knowledge_source.dart`.
- `Knowledge {unknown, learning, known}`, `KnowledgeSource = Knowledge Function(String)`, `isContentToken(Token)` — `lib/core/pipeline/sentence_scoring.dart`.
- `WordTapHandler(Dictionary).onTap(Token) → WordTapResult{token, senses, isKnownWord}` — `lib/core/text_track/word_tap.dart`.
- `InReadingReviewPanel({required DueCardInView due, required void Function(Rating) onGrade})` — `lib/features/reader/in_reading_review.dart`.
- `recordPassageSnapshot(MiningDb, {workId, passageRef, tokens, knowledgeOf, metrics, ts})` — `lib/core/pipeline/passage_snapshot.dart`.
- `MiningDb.forTesting()` / `MiningDb.at(File)`, `miningDbProvider` (`Provider<MiningDb?>`) — `lib/app/knowledge_providers.dart`.

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/comic/comic_pack.dart` | Create | `ComicPack`/`ComicPage`/`Bubble`/`BubbleRect`/`BubbleLang` + `fromJson`; language-agnostic |
| `assets/comic/ja_l0.json`, `assets/comic/es_l0.json` | Create | Two placeholder packs (JA + ES) proving agnosticism |
| `assets/comic/placeholder_page.png` | Create | Neutral placeholder panel image |
| `lib/features/comic/spatial_reader.dart` | Create | Render page image + overlay bubbles by rect; L2 tappable, L1 plain; direction + reading generic |
| `lib/features/comic/comic_selector.dart` | Create | `l2TokensOf` + `nextComicPage` over `rankByIPlusOne` |
| `lib/features/comic/comic_repository.dart` | Create | Load pack, knowledge, tap, snapshot — mirrors `SliceRepository` |
| `lib/features/comic/comic_reader_screen.dart` | Create | Screen: SpatialReader + gloss sheet + in-reading review |
| `lib/features/mining_slice/reading_tab.dart` | Modify | Offer manga reading for the active language |
| `lib/core/sources/manga_source_adapter.dart` | Modify | Persist a renderable image handle (MediaBlobs) for the OCR side-door |
| `tool/proof_manga_reading.dart` | Create | Multi-language (JA + ES) end-to-end proof |
| `test/**` | Create | Unit + widget tests per task |

---

### Task 1: Language-agnostic comic content model

**Files:**
- Create: `lib/features/comic/comic_pack.dart`
- Test: `test/features/comic/comic_pack_test.dart`

**Interfaces:**
- Produces: `ComicPack{languageCode, title, level, l2Ratio, pages}`, `ComicPage{pageRef, imageAsset, aspectRatio, bubbles}`, `Bubble{rect, lang, text, tokens, reading}`, `BubbleRect{left, top, right, bottom}` (normalized 0..1), `enum BubbleLang {l1, l2}`, all with `fromJson`.
- Consumes: `Token` from `core/language_pack/language_pack.dart`.

- [ ] **Step 1: Write the failing test**

Create `test/features/comic/comic_pack_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';

const _json = {
  'languageCode': 'ja',
  'title': 'Neko',
  'level': 0,
  'l2Ratio': 0.2,
  'pages': [
    {
      'pageRef': 'p1',
      'imageAsset': 'assets/comic/placeholder_page.png',
      'aspectRatio': 0.7,
      'bubbles': [
        {
          'rect': {'left': 0.1, 'top': 0.1, 'right': 0.5, 'bottom': 0.25},
          'lang': 'l1',
          'text': 'Schau, eine Katze!',
          'tokens': [],
        },
        {
          'rect': {'left': 0.5, 'top': 0.6, 'right': 0.9, 'bottom': 0.75},
          'lang': 'l2',
          'text': '猫',
          'reading': 'ねこ',
          'tokens': [
            {
              'surface': '猫', 'lemma': '猫', 'reading': 'ねこ',
              'pos': 'n', 'charStart': 0, 'charEnd': 1
            }
          ],
        },
      ],
    },
  ],
};

void main() {
  test('parses a pack with L1 and L2 bubbles', () {
    final pack = ComicPack.fromJson(_json);
    expect(pack.languageCode, 'ja');
    expect(pack.l2Ratio, 0.2);
    expect(pack.pages, hasLength(1));

    final bubbles = pack.pages.first.bubbles;
    expect(bubbles[0].lang, BubbleLang.l1);
    expect(bubbles[0].tokens, isEmpty);
    expect(bubbles[1].lang, BubbleLang.l2);
    expect(bubbles[1].tokens.single.lemma, '猫');
    expect(bubbles[1].rect.left, 0.5);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/comic_pack_test.dart
```
Expected: FAIL — `comic_pack.dart` does not exist.

- [ ] **Step 3: Create `lib/features/comic/comic_pack.dart`**

```dart
import '../../core/language_pack/language_pack.dart';

enum BubbleLang { l1, l2 }

/// Normalized (0..1) bounding box within the page image.
class BubbleRect {
  final double left, top, right, bottom;
  const BubbleRect(
      {required this.left,
      required this.top,
      required this.right,
      required this.bottom});

  factory BubbleRect.fromJson(Map<String, dynamic> j) => BubbleRect(
        left: (j['left'] as num).toDouble(),
        top: (j['top'] as num).toDouble(),
        right: (j['right'] as num).toDouble(),
        bottom: (j['bottom'] as num).toDouble(),
      );
}

class Bubble {
  final BubbleRect rect;
  final BubbleLang lang;
  final String text;
  final List<Token> tokens; // empty for L1 (plain, non-tappable, not mined)
  final String? reading;

  const Bubble({
    required this.rect,
    required this.lang,
    required this.text,
    required this.tokens,
    this.reading,
  });

  factory Bubble.fromJson(Map<String, dynamic> j) => Bubble(
        rect: BubbleRect.fromJson(j['rect'] as Map<String, dynamic>),
        lang: (j['lang'] as String) == 'l2' ? BubbleLang.l2 : BubbleLang.l1,
        text: j['text'] as String,
        reading: j['reading'] as String?,
        tokens: [
          for (final t in (j['tokens'] as List? ?? const []))
            Token(
              surface: t['surface'] as String,
              lemma: t['lemma'] as String,
              reading: t['reading'] as String?,
              pos: t['pos'] as String,
              charStart: t['charStart'] as int,
              charEnd: t['charEnd'] as int,
            ),
        ],
      );
}

class ComicPage {
  final String pageRef;
  final String imageAsset;
  final double aspectRatio; // width / height
  final List<Bubble> bubbles;

  const ComicPage({
    required this.pageRef,
    required this.imageAsset,
    required this.aspectRatio,
    required this.bubbles,
  });

  factory ComicPage.fromJson(Map<String, dynamic> j) => ComicPage(
        pageRef: j['pageRef'] as String,
        imageAsset: j['imageAsset'] as String,
        aspectRatio: (j['aspectRatio'] as num?)?.toDouble() ?? 0.7,
        bubbles: [
          for (final b in (j['bubbles'] as List? ?? const []))
            Bubble.fromJson(b as Map<String, dynamic>),
        ],
      );
}

/// A graded comic for one target language. `l2Ratio` is the immersion-ramp
/// dial: fraction of bubble text in L2 (0 = all L1, 1 = all L2).
class ComicPack {
  final String languageCode;
  final String title;
  final int level;
  final double l2Ratio;
  final List<ComicPage> pages;

  const ComicPack({
    required this.languageCode,
    required this.title,
    required this.level,
    required this.l2Ratio,
    required this.pages,
  });

  factory ComicPack.fromJson(Map<String, dynamic> j) => ComicPack(
        languageCode: j['languageCode'] as String,
        title: j['title'] as String,
        level: j['level'] as int? ?? 0,
        l2Ratio: (j['l2Ratio'] as num?)?.toDouble() ?? 0.0,
        pages: [
          for (final p in (j['pages'] as List? ?? const []))
            ComicPage.fromJson(p as Map<String, dynamic>),
        ],
      );
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/comic/comic_pack_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/comic/comic_pack.dart test/features/comic/comic_pack_test.dart
git commit -m "feat(comic): language-agnostic ComicPack model (L1/L2 bubbles, normalized rects)"
```

---

### Task 2: Placeholder comic assets for two languages

**Files:**
- Create: `assets/comic/placeholder_page.png`
- Create: `assets/comic/ja_l0.json`, `assets/comic/es_l0.json`
- Modify: `pubspec.yaml` (declare `assets/comic/`)
- Test: `test/features/comic/comic_assets_test.dart`

**Interfaces:**
- Produces: two bundled packs (`ja`, `es`) that `ComicPack.fromJson` parses, proving the model is not JA-specific.

- [ ] **Step 1: Create the placeholder image**

Create a neutral 700×1000 light-grey PNG at `assets/comic/placeholder_page.png` (a plain frame — real art is external/later). Any tiny valid PNG works; e.g. generate one:

```bash
cd <WT> && python3 -c "from PIL import Image; Image.new('RGB',(700,1000),(235,235,235)).save('assets/comic/placeholder_page.png')" 2>/dev/null || printf '' > assets/comic/placeholder_page.png
```
If Pillow is unavailable, commit an existing small PNG copied to that path; the exact pixels don't matter for the MVP.

- [ ] **Step 2: Create `assets/comic/ja_l0.json`** (level 0, mostly L1)

```json
{
  "languageCode": "ja",
  "title": "Neko no hi",
  "level": 0,
  "l2Ratio": 0.2,
  "pages": [
    {
      "pageRef": "p1",
      "imageAsset": "assets/comic/placeholder_page.png",
      "aspectRatio": 0.7,
      "bubbles": [
        {"rect": {"left": 0.08, "top": 0.08, "right": 0.6, "bottom": 0.2},
         "lang": "l1", "text": "Schau, da ist eine Katze!", "tokens": []},
        {"rect": {"left": 0.45, "top": 0.55, "right": 0.9, "bottom": 0.68},
         "lang": "l2", "text": "猫", "reading": "ねこ",
         "tokens": [{"surface": "猫", "lemma": "猫", "reading": "ねこ", "pos": "n", "charStart": 0, "charEnd": 1}]}
      ]
    }
  ]
}
```

- [ ] **Step 3: Create `assets/comic/es_l0.json`** (a different target language)

```json
{
  "languageCode": "es",
  "title": "El gato",
  "level": 0,
  "l2Ratio": 0.2,
  "pages": [
    {
      "pageRef": "p1",
      "imageAsset": "assets/comic/placeholder_page.png",
      "aspectRatio": 0.7,
      "bubbles": [
        {"rect": {"left": 0.08, "top": 0.08, "right": 0.6, "bottom": 0.2},
         "lang": "l1", "text": "Schau, da ist eine Katze!", "tokens": []},
        {"rect": {"left": 0.45, "top": 0.55, "right": 0.9, "bottom": 0.68},
         "lang": "l2", "text": "gato",
         "tokens": [{"surface": "gato", "lemma": "gato", "pos": "n", "charStart": 0, "charEnd": 4}]}
      ]
    }
  ]
}
```

- [ ] **Step 4: Declare the asset dir in `pubspec.yaml`**

Under `flutter: assets:` add:

```yaml
    - assets/comic/
```

- [ ] **Step 5: Write the failing test**

Create `test/features/comic/comic_assets_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ComicPack> load(String path) async {
    final raw = await rootBundle.loadString(path);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  test('JA and ES packs both parse (model is language-agnostic)', () async {
    final ja = await load('assets/comic/ja_l0.json');
    final es = await load('assets/comic/es_l0.json');
    expect(ja.languageCode, 'ja');
    expect(es.languageCode, 'es');
    // ES has no reading layer; JA does — both are valid.
    final jaL2 = ja.pages.first.bubbles.firstWhere((b) => b.lang == BubbleLang.l2);
    final esL2 = es.pages.first.bubbles.firstWhere((b) => b.lang == BubbleLang.l2);
    expect(jaL2.tokens.single.reading, isNotNull);
    expect(esL2.tokens.single.reading, isNull);
  });
}
```

- [ ] **Step 6: Run test (pub get first for the new asset dir)**

```bash
cd <WT> && flutter pub get && flutter test test/features/comic/comic_assets_test.dart
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml assets/comic/ test/features/comic/comic_assets_test.dart
git commit -m "feat(comic): placeholder packs for JA + ES (proves language-agnostic content)"
```

---

### Task 3: `SpatialReader` — image + bubble overlay (L2 tappable, L1 plain)

**Files:**
- Create: `lib/features/comic/spatial_reader.dart`
- Test: `test/features/comic/spatial_reader_test.dart`

**Interfaces:**
- Consumes: `ComicPage`, `Bubble`, `Token`.
- Produces: `SpatialReader({required ComicPage page, required TextDirection direction, required void Function(Token) onWordTap})` — renders the page image behind normalized-positioned bubbles; L2 bubble words are tappable and show `Token.reading` above; L1 bubbles are plain text.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/comic/spatial_reader_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/spatial_reader.dart';

ComicPage _page() => const ComicPage(
      pageRef: 'p1',
      imageAsset: 'assets/comic/placeholder_page.png',
      aspectRatio: 0.7,
      bubbles: [
        Bubble(
          rect: BubbleRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.2),
          lang: BubbleLang.l1,
          text: 'Eine Katze!',
          tokens: [],
        ),
        Bubble(
          rect: BubbleRect(left: 0.5, top: 0.6, right: 0.9, bottom: 0.7),
          lang: BubbleLang.l2,
          text: '猫',
          reading: 'ねこ',
          tokens: [
            Token(surface: '猫', lemma: '猫', reading: 'ねこ', pos: 'n', charStart: 0, charEnd: 1),
          ],
        ),
      ],
    );

void main() {
  testWidgets('renders L1 text plainly and L2 word tappably', (tester) async {
    Token? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpatialReader(
          page: _page(),
          direction: TextDirection.ltr,
          onWordTap: (t) => tapped = t,
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Eine Katze!'), findsOneWidget); // L1 present
    expect(find.text('猫'), findsOneWidget); // L2 present
    expect(find.text('ねこ'), findsOneWidget); // reading overlay (generic)

    await tester.tap(find.text('猫'));
    await tester.pump();
    expect(tapped, isNotNull); // L2 is tappable
    expect(tapped!.lemma, '猫');
  });

  testWidgets('tapping L1 text does nothing (not mineable)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpatialReader(
          page: _page(),
          direction: TextDirection.ltr,
          onWordTap: (_) => taps++,
        ),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Eine Katze!'));
    await tester.pump();
    expect(taps, 0);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/spatial_reader_test.dart
```
Expected: FAIL — `spatial_reader.dart` does not exist.

- [ ] **Step 3: Create `lib/features/comic/spatial_reader.dart`**

```dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';
import 'comic_pack.dart';

/// Renders one comic page: the panel image with speech bubbles overlaid at
/// their normalized rects. L2 words are tappable (report to [onWordTap])
/// and show their reading above; L1 text is plain and never tappable.
/// Language-blind: [direction] and the reading overlay come from the pack /
/// ScriptProfile, never a language branch. Missing image → neutral frame.
class SpatialReader extends StatelessWidget {
  final ComicPage page;
  final TextDirection direction;
  final void Function(Token token) onWordTap;

  const SpatialReader({
    super.key,
    required this.page,
    required this.direction,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: AspectRatio(
        aspectRatio: page.aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                _pageImage(page.imageAsset),
                for (final b in page.bubbles)
                  Positioned(
                    left: b.rect.left * w,
                    top: b.rect.top * h,
                    width: (b.rect.right - b.rect.left) * w,
                    height: (b.rect.bottom - b.rect.top) * h,
                    child: _BubbleWidget(bubble: b, onWordTap: onWordTap),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _pageImage(String assetPath) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEDEDED)),
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final Bubble bubble;
  final void Function(Token token) onWordTap;
  const _BubbleWidget({required this.bubble, required this.onWordTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black26),
      ),
      child: bubble.lang == BubbleLang.l1
          ? Text(bubble.text, textAlign: TextAlign.center)
          : _l2Content(context),
    );
  }

  Widget _l2Content(BuildContext context) {
    // If tokens are provided, render each as a tappable word with its
    // reading above; otherwise render the whole L2 text as one tappable unit.
    if (bubble.tokens.isEmpty) {
      return GestureDetector(
        onTap: () {},
        child: Text(bubble.text, textAlign: TextAlign.center),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final t in bubble.tokens)
          GestureDetector(
            key: ValueKey('l2-${t.charStart}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => onWordTap(t),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (t.reading != null)
                  Text(t.reading!, style: Theme.of(context).textTheme.labelSmall),
                Text(t.surface),
              ],
            ),
          ),
      ],
    );
  }
}
```

Note: `Color.withValues(alpha:)` is the Flutter 3.27+ API; if the SDK on disk is older, use `Colors.white.withOpacity(0.92)`.

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/comic/spatial_reader_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/comic/spatial_reader.dart test/features/comic/spatial_reader_test.dart
git commit -m "feat(comic): SpatialReader — page image + L2-tappable/L1-plain bubbles, direction-aware"
```

---

### Task 4: Comic i+1 selector (reuses `rankByIPlusOne`)

**Files:**
- Create: `lib/features/comic/comic_selector.dart`
- Test: `test/features/comic/comic_selector_test.dart`

**Interfaces:**
- Consumes: `ComicPage`, `Bubble`, `rankByIPlusOne`, `KnowledgeSource`, `Knowledge`, `IPlusOneWindow`.
- Produces: `List<Token> l2TokensOf(ComicPage)`; `ComicPage? nextComicPage(Iterable<ComicPage>, KnowledgeSource, {IPlusOneWindow window})` returning the best-fit (ideal, else nearest) page.

- [ ] **Step 1: Write the failing test**

Create `test/features/comic/comic_selector_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_selector.dart';

Bubble _l2(List<String> lemmas) => Bubble(
      rect: const BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
      lang: BubbleLang.l2,
      text: lemmas.join(),
      tokens: [
        for (var i = 0; i < lemmas.length; i++)
          Token(surface: lemmas[i], lemma: lemmas[i], pos: 'n', charStart: i, charEnd: i + 1),
      ],
    );

ComicPage _page(String ref, List<String> lemmas) => ComicPage(
      pageRef: ref,
      imageAsset: 'x.png',
      aspectRatio: 0.7,
      bubbles: [_l2(lemmas)],
    );

void main() {
  test('l2TokensOf returns only L2 tokens', () {
    final page = ComicPage(
      pageRef: 'p',
      imageAsset: 'x.png',
      aspectRatio: 0.7,
      bubbles: [
        const Bubble(
            rect: BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
            lang: BubbleLang.l1,
            text: 'hallo',
            tokens: []),
        _l2(['猫']),
      ],
    );
    expect(l2TokensOf(page).map((t) => t.lemma), ['猫']);
  });

  test('picks the page whose unknown-ratio sits in the i+1 window', () {
    // known: everything except "難". Page A is all-known (too easy),
    // Page B has one unknown among several (ideal i+1).
    Knowledge knows(String lemma) =>
        lemma == '難' ? Knowledge.unknown : Knowledge.known;

    final easy = _page('A', ['猫', '犬', '鳥', '魚', '本']);
    final ideal = _page('B', ['猫', '犬', '鳥', '魚', '難']); // 1/5 unknown = 0.2

    final next = nextComicPage([easy, ideal], knows);
    expect(next, isNotNull);
    expect(next!.pageRef, 'B');
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/comic_selector_test.dart
```
Expected: FAIL — `comic_selector.dart` does not exist.

- [ ] **Step 3: Create `lib/features/comic/comic_selector.dart`**

```dart
import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/content_selector.dart';
import '../../core/pipeline/sentence_scoring.dart';
import 'comic_pack.dart';

/// All L2 tokens on a page (L1 bubbles carry none → never mined/tested).
List<Token> l2TokensOf(ComicPage page) => [
      for (final b in page.bubbles)
        if (b.lang == BubbleLang.l2) ...b.tokens,
    ];

/// The next comic page for this learner: prefer an i+1 "ideal" fit, else
/// the nearest. Reuses the shared `rankByIPlusOne` ranker — no comic-
/// specific scoring, and no language branch.
ComicPage? nextComicPage(
  Iterable<ComicPage> pages,
  KnowledgeSource knowledgeOf, {
  IPlusOneWindow window = const IPlusOneWindow(),
}) {
  final ranked = rankByIPlusOne<ComicPage>(
    pages,
    l2TokensOf,
    knowledgeOf,
    window: window,
  );
  if (ranked.isEmpty) return null;
  final ideal = ranked.where((r) => r.fit == Fit.ideal).toList();
  if (ideal.isNotEmpty) return ideal.first.passage;
  // Nearest to the window: smallest distance from the [lower,upper] band.
  ranked.sort((a, b) =>
      _distance(a.unknownRatio, window).compareTo(_distance(b.unknownRatio, window)));
  return ranked.first.passage;
}

double _distance(double ratio, IPlusOneWindow w) {
  if (ratio < w.lower) return w.lower - ratio;
  if (ratio > w.upper) return ratio - w.upper;
  return 0;
}
```

Note: confirm `RankedPassage` exposes `.passage`, `.unknownRatio`, `.fit` and `IPlusOneWindow` exposes `.lower`/`.upper` (per the reference dossier); adjust field names if the file differs.

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/comic/comic_selector_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/comic/comic_selector.dart test/features/comic/comic_selector_test.dart
git commit -m "feat(comic): i+1 comic selector over rankByIPlusOne (L2-only, language-blind)"
```

---

### Task 5: Immersion ramp — `l2Ratio` and L1/L2 discipline

**Files:**
- Modify: `lib/features/comic/comic_selector.dart` (add a ramp helper)
- Create: `assets/comic/ja_l1.json` (a higher level with more L2)
- Test: `test/features/comic/ramp_test.dart`

**Interfaces:**
- Produces: `double measuredL2Ratio(ComicPage)` — fraction of bubbles that are L2 on a page (a measurable check that the authored ramp holds).

- [ ] **Step 1: Create a higher-level pack `assets/comic/ja_l1.json`** (more L2)

```json
{
  "languageCode": "ja",
  "title": "Neko no hi 2",
  "level": 1,
  "l2Ratio": 0.6,
  "pages": [
    {
      "pageRef": "p1",
      "imageAsset": "assets/comic/placeholder_page.png",
      "aspectRatio": 0.7,
      "bubbles": [
        {"rect": {"left": 0.1, "top": 0.1, "right": 0.5, "bottom": 0.2},
         "lang": "l2", "text": "猫", "reading": "ねこ",
         "tokens": [{"surface": "猫", "lemma": "猫", "reading": "ねこ", "pos": "n", "charStart": 0, "charEnd": 1}]},
        {"rect": {"left": 0.5, "top": 0.6, "right": 0.9, "bottom": 0.72},
         "lang": "l2", "text": "犬", "reading": "いぬ",
         "tokens": [{"surface": "犬", "lemma": "犬", "reading": "いぬ", "pos": "n", "charStart": 0, "charEnd": 1}]},
        {"rect": {"left": 0.1, "top": 0.8, "right": 0.6, "bottom": 0.92},
         "lang": "l1", "text": "… und so weiter.", "tokens": []}
      ]
    }
  ]
}
```

- [ ] **Step 2: Write the failing test**

Create `test/features/comic/ramp_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ComicPack> load(String path) async =>
      ComicPack.fromJson(jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>);

  test('higher level has more L2 than level 0 (the ramp)', () async {
    final l0 = await load('assets/comic/ja_l0.json');
    final l1 = await load('assets/comic/ja_l1.json');
    expect(l1.level, greaterThan(l0.level));
    expect(measuredL2Ratio(l1.pages.first),
        greaterThan(measuredL2Ratio(l0.pages.first)));
  });

  test('measuredL2Ratio counts L2 bubbles over all bubbles', () async {
    final l1 = await load('assets/comic/ja_l1.json');
    // ja_l1 page: 2 L2 + 1 L1 = 2/3
    expect(measuredL2Ratio(l1.pages.first), closeTo(2 / 3, 0.001));
  });
}
```

- [ ] **Step 3: Add `measuredL2Ratio` to `lib/features/comic/comic_selector.dart`**

```dart
/// The realized L2 fraction of a page (L2 bubbles / all bubbles). Lets a
/// test assert the authored immersion ramp actually rises with level.
double measuredL2Ratio(ComicPage page) {
  if (page.bubbles.isEmpty) return 0;
  final l2 = page.bubbles.where((b) => b.lang == BubbleLang.l2).length;
  return l2 / page.bubbles.length;
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter pub get && flutter test test/features/comic/ramp_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/comic/comic_selector.dart assets/comic/ja_l1.json test/features/comic/ramp_test.dart
git commit -m "feat(comic): immersion ramp — level 1 pack + measuredL2Ratio check"
```

---

### Task 6: `ComicRepository` — knowledge, tap, snapshot (mirrors `SliceRepository`)

**Files:**
- Create: `lib/features/comic/comic_repository.dart`
- Test: `test/features/comic/comic_repository_test.dart`

**Interfaces:**
- Consumes: `MiningDb`, `ComicPack`, `FsrsKnowledgeSource`, `WordTapHandler`/`Dictionary`, `recordPassageSnapshot`, `nextComicPage`.
- Produces: `ComicRepository({required MiningDb db, required ComicPack pack, required Dictionary dictionary})` with `Future<ComicPage?> nextPage()`, `WordTapResult tap(Token)`, `Future<void> finishPage(ComicPage, {int lookups})`.

- [ ] **Step 1: Write the failing test**

Create `test/features/comic/comic_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';

class _EmptyDict implements Dictionary {
  const _EmptyDict();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

ComicPack _pack() => const ComicPack(
      languageCode: 'ja',
      title: 'T',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'x.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
              lang: BubbleLang.l2,
              text: '猫',
              tokens: [
                Token(surface: '猫', lemma: '猫', pos: 'n', charStart: 0, charEnd: 1)
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  test('nextPage returns a page for an empty known-set (everything i+1)',
      () async {
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _EmptyDict());
    final page = await repo.nextPage();
    expect(page, isNotNull);
    expect(page!.pageRef, 'p1');
  });

  test('finishPage records a passage snapshot with the page unknown-ratio',
      () async {
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _EmptyDict());
    final page = (await repo.nextPage())!;
    await repo.finishPage(page, lookups: 1);

    final snaps = await db.select(db.passageSnapshots).get();
    expect(snaps, hasLength(1));
    expect(snaps.first.passageRef, 'p1');
    // No known cards → the single L2 lemma is unknown → ratio 1.0.
    expect(snaps.first.unknownRatio, closeTo(1.0, 0.001));
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/comic_repository_test.dart
```
Expected: FAIL — `comic_repository.dart` does not exist.

- [ ] **Step 3: Create `lib/features/comic/comic_repository.dart`**

```dart
import '../../core/db/mining_db.dart';
import '../../core/language_pack/language_pack.dart';
import '../../core/pipeline/fsrs_knowledge_source.dart';
import '../../core/pipeline/passage_snapshot.dart';
import '../../core/text_track/word_tap.dart';
import 'comic_pack.dart';
import 'comic_selector.dart';

/// The single wiring seam from a [ComicPack] onto the real pipeline —
/// exactly parallel to SliceRepository, but for spatial comic pages.
/// Language-blind: all queries key on [pack.languageCode].
class ComicRepository {
  final MiningDb db;
  final ComicPack pack;
  final Dictionary dictionary;

  ComicRepository({
    required this.db,
    required this.pack,
    required this.dictionary,
  });

  late final String workId = 'comic:${pack.languageCode}:${pack.title}';

  Future<FsrsKnowledgeSource> _knowledge() =>
      FsrsKnowledgeSource.load(db, languageCode: pack.languageCode);

  /// The next i+1 page for the learner, or the first page if the ranker
  /// has nothing to prefer (e.g. brand-new known-set).
  Future<ComicPage?> nextPage() async {
    final know = await _knowledge();
    return nextComicPage(pack.pages, know.call) ??
        (pack.pages.isEmpty ? null : pack.pages.first);
  }

  WordTapResult tap(Token token) => WordTapHandler(dictionary).onTap(token);

  Future<void> finishPage(ComicPage page, {int lookups = 0}) async {
    final know = await _knowledge();
    await recordPassageSnapshot(
      db,
      workId: workId,
      passageRef: page.pageRef,
      tokens: l2TokensOf(page),
      knowledgeOf: know.call,
      metrics: PassageMetrics(lookupCount: lookups),
    );
  }
}
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/features/comic/comic_repository_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/comic/comic_repository.dart test/features/comic/comic_repository_test.dart
git commit -m "feat(comic): ComicRepository — knowledge + tap + snapshot on the real pipeline"
```

---

### Task 7: `ComicReaderScreen` + Lesen-tab entry (language-blind)

**Files:**
- Create: `lib/features/comic/comic_reader_screen.dart`
- Modify: `lib/features/mining_slice/reading_tab.dart`
- Test: `test/features/comic/comic_reader_screen_test.dart`

**Interfaces:**
- Consumes: `ComicRepository`, `SpatialReader`, `ScriptProfile` (for direction), the gloss-sheet pattern from `reader_screen.dart`.
- Produces: `ComicReaderScreen({required ComicRepository repo, required TextDirection direction})` — shows the current page, opens a gloss sheet on L2 tap, advances on finish.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/comic/comic_reader_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_reader_screen.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';

class _Dict implements Dictionary {
  const _Dict();
  @override
  List<Sense> lookup(String lemma, String pos) =>
      [Sense(pos: 'n', glosses: ['cat'])];
}

ComicPack _pack() => const ComicPack(
      languageCode: 'ja',
      title: 'T',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'assets/comic/placeholder_page.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: BubbleRect(left: 0.2, top: 0.4, right: 0.8, bottom: 0.6),
              lang: BubbleLang.l2,
              text: '猫',
              reading: 'ねこ',
              tokens: [
                Token(surface: '猫', lemma: '猫', reading: 'ねこ', pos: 'n', charStart: 0, charEnd: 1)
              ],
            ),
          ],
        ),
      ],
    );

void main() {
  testWidgets('tapping an L2 word opens a gloss sheet', (tester) async {
    final db = MiningDb.forTesting();
    addTearDown(db.close);
    final repo = ComicRepository(db: db, pack: _pack(), dictionary: const _Dict());

    await tester.pumpWidget(MaterialApp(
      home: ComicReaderScreen(repo: repo, direction: TextDirection.ltr),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('猫'));
    await tester.pumpAndSettle();

    expect(find.text('cat'), findsOneWidget); // gloss shown in the sheet
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/features/comic/comic_reader_screen_test.dart
```
Expected: FAIL — `comic_reader_screen.dart` does not exist.

- [ ] **Step 3: Create `lib/features/comic/comic_reader_screen.dart`**

```dart
import 'package:flutter/material.dart';

import '../../core/language_pack/language_pack.dart';
import '../../core/text_track/word_tap.dart';
import 'comic_pack.dart';
import 'comic_repository.dart';
import 'spatial_reader.dart';

/// Reads a comic: the current i+1 page rendered spatially, a gloss sheet on
/// L2 tap, and a "next" action that snapshots progress and advances.
class ComicReaderScreen extends StatefulWidget {
  final ComicRepository repo;
  final TextDirection direction;

  const ComicReaderScreen({
    super.key,
    required this.repo,
    required this.direction,
  });

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late Future<ComicPage?> _page = widget.repo.nextPage();
  int _lookups = 0;

  void _onWordTap(Token token) {
    setState(() => _lookups++);
    final result = widget.repo.tap(token);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GlossSheet(token: token, result: result),
    );
  }

  Future<void> _finish(ComicPage page) async {
    await widget.repo.finishPage(page, lookups: _lookups);
    if (!mounted) return;
    setState(() {
      _lookups = 0;
      _page = widget.repo.nextPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.repo.pack.title)),
      body: FutureBuilder<ComicPage?>(
        future: _page,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final page = snapshot.data;
          if (page == null) {
            return const Center(child: Text('—'));
          }
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SpatialReader(
                    page: page,
                    direction: widget.direction,
                    onWordTap: _onWordTap,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      persistentFooterButtons: [
        FutureBuilder<ComicPage?>(
          future: _page,
          builder: (context, snapshot) {
            final page = snapshot.data;
            return FilledButton.icon(
              key: const ValueKey('finish-comic-page'),
              onPressed: page == null ? null : () => _finish(page),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Weiter'),
            );
          },
        ),
      ],
    );
  }
}

class _GlossSheet extends StatelessWidget {
  final Token token;
  final WordTapResult result;
  const _GlossSheet({required this.token, required this.result});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(token.lemma, style: Theme.of(context).textTheme.headlineSmall),
          if (token.reading != null) Text(token.reading!),
          const SizedBox(height: 12),
          if (!result.isKnownWord)
            const Text('—')
          else
            for (final s in result.senses) Text(s.glosses.join(', ')),
        ],
      ),
    );
  }
}
```

Note: "Weiter" here is a fixed literal for brevity — replace with `AppLocalizations.of(context)!.continueLabel` (from the Empfang plan's l10n) so it stays localized. Import `AppLocalizations` and swap when wiring.

- [ ] **Step 4: Add a manga entry to the Lesen tab in `reading_tab.dart`**

The current `ReadingTab` shows the text `OpeningGate`. Add a language-blind entry that loads a `ComicPack` for the active language and opens `ComicReaderScreen`. Add a provider that picks the pack asset by active language (falling back to the text reader when no comic exists for that language):

```dart
final comicPackProvider = FutureProvider<ComicPack?>((ref) async {
  final lang = ref.watch(activeLanguageProvider);
  final path = 'assets/comic/${lang}_l0.json';
  try {
    final raw = await rootBundle.loadString(path);
    return ComicPack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return null; // no comic bundled for this language → text reader only
  }
});
```

In `ReadingTab.build`, add a button/toggle (an `AppBar` action or a `FloatingActionButton`) that, when a comic exists and `miningDbProvider` is non-null, pushes:

```dart
ComicReaderScreen(
  repo: ComicRepository(
    db: db,
    pack: pack,
    dictionary: repo.dictionaryFor(pack.languageCode), // reuse the pack's dictionary seam
  ),
  direction: TextDirection.ltr, // TODO: from ScriptProfile.direction of the active pack
)
```

Keep the existing text `OpeningGate` as the default surface; the comic is an additional, opt-in reading mode. (Wiring the exact dictionary + ScriptProfile lookups follows the existing provider patterns; keep this minimal and language-blind.)

- [ ] **Step 5: Run the widget test**

```bash
cd <WT> && flutter test test/features/comic/comic_reader_screen_test.dart
```
Expected: PASS.

- [ ] **Step 6: Run the comic dir + analyze**

```bash
cd <WT> && flutter test test/features/comic/ && flutter analyze lib/features/comic/
```
Expected: all PASS; 0 analyze errors in the comic dir.

- [ ] **Step 7: Commit**

```bash
git add lib/features/comic/comic_reader_screen.dart lib/features/mining_slice/reading_tab.dart test/features/comic/comic_reader_screen_test.dart
git commit -m "feat(comic): ComicReaderScreen + Lesen-tab manga entry (language-blind)"
```

---

### Task 8: Persist a renderable image handle in `MangaSourceAdapter`

**Files:**
- Modify: `lib/core/sources/manga_source_adapter.dart`
- Test: `test/core/sources/manga_source_media_test.dart`

**Interfaces:**
- Produces: `_store` also writes a `MediaBlobs` row (`kind:'image'`, `path`, `contentHash`) for the page image, so the bring-your-own-manga (OCR side-door) path has a first-class image handle to render — not just discarded pixels.
- Consumes: `MediaBlobs` table (`mining_tables.dart`), `crypto` (already a dependency) for the hash.

- [ ] **Step 1: Write the failing test**

Create `test/core/sources/manga_source_media_test.dart`:

```dart
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/media/ocr_engine.dart';
import 'package:nihongo_app/core/sources/manga_source_adapter.dart';

class _FakeOcr implements OcrEngine {
  const _FakeOcr();
  @override
  Future<List<OcrBox>> recognize(File image) async =>
      const [OcrBox(text: '猫', left: 10, top: 10, right: 40, bottom: 40)];
}

void main() {
  late MiningDb db;
  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  test('storeBoxes records a MediaBlobs image row for the page', () async {
    final adapter = MangaSourceAdapter(db, const _FakeOcr());
    await adapter.storeBoxes(
      boxes: const [OcrBox(text: '猫', left: 10, top: 10, right: 40, bottom: 40)],
      sourcePath: '/tmp/page1.png',
      workTitle: 'Manga',
      languageCode: 'ja',
      pageId: 'page-1',
    );

    final blobs = await db.select(db.mediaBlobs).get();
    expect(blobs, hasLength(1));
    expect(blobs.first.kind, 'image');
    expect(blobs.first.path, '/tmp/page1.png');
    expect(blobs.first.contentHash, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd <WT> && flutter test test/core/sources/manga_source_media_test.dart
```
Expected: FAIL — no `MediaBlobs` row is written today.

- [ ] **Step 3: Edit `lib/core/sources/manga_source_adapter.dart`**

Add imports:

```dart
import 'package:crypto/crypto.dart';
import '../db/mining_tables.dart';
```

In `_store`, after inserting the `Sources` row, insert a `MediaBlobs` row for the page image (hash the path string — a stable handle without copying pixels; a real copy is a later step):

```dart
    await db.into(db.mediaBlobs).insert(MediaBlobsCompanion.insert(
          id: 'media:$stamp',
          kind: 'image',
          path: sourcePath,
          contentHash: sha1.convert(sourcePath.codeUnits).toString(),
        ));
```

- [ ] **Step 4: Run test to confirm it passes**

```bash
cd <WT> && flutter test test/core/sources/manga_source_media_test.dart
```
Expected: PASS.

- [ ] **Step 5: Run the existing manga adapter test (no regression)**

```bash
cd <WT> && flutter test test/core/sources/manga_source_adapter_test.dart
```
Expected: PASS (the added MediaBlobs write doesn't change span output).

- [ ] **Step 6: Commit**

```bash
git add lib/core/sources/manga_source_adapter.dart test/core/sources/manga_source_media_test.dart
git commit -m "feat(sources): manga adapter persists a MediaBlobs image handle (OCR side-door renderable)"
```

---

### Task 9: Multi-language proof + full verification

**Files:**
- Create: `tool/proof_manga_reading.dart`

- [ ] **Step 1: Write the proof tool**

Create `tool/proof_manga_reading.dart`, mirroring the `tool/phaseN_*.dart` header + gate style, proving the loop works for **two** target languages with no language branch:

```dart
// Proof: Manga-Lesen (docs/superpowers/specs/2026-08-17-manga-lesen-design.md)
//   "A real comic page renders with tappable L2 words over a placeholder
//    image; the i+1 selector picks a page from the learner's known-set;
//    reading is measured via a passage snapshot — for ANY target language."
//
// Runs headless for JA and ES ComicPacks (no `if (lang == 'ja')`), asserting
// selection + snapshot for both.
//
// Usage:
//   dart run tool/proof_manga_reading.dart

import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/language_pack/language_pack.dart';
import 'package:nihongo_app/features/comic/comic_pack.dart';
import 'package:nihongo_app/features/comic/comic_repository.dart';

class _EmptyDict implements Dictionary {
  const _EmptyDict();
  @override
  List<Sense> lookup(String lemma, String pos) => const [];
}

ComicPack _pack(String lang, String l2Surface) => ComicPack(
      languageCode: lang,
      title: 'proof-$lang',
      level: 0,
      l2Ratio: 0.2,
      pages: [
        ComicPage(
          pageRef: 'p1',
          imageAsset: 'assets/comic/placeholder_page.png',
          aspectRatio: 0.7,
          bubbles: [
            Bubble(
              rect: const BubbleRect(left: 0, top: 0, right: 1, bottom: 1),
              lang: BubbleLang.l2,
              text: l2Surface,
              tokens: [
                Token(surface: l2Surface, lemma: l2Surface, pos: 'n', charStart: 0, charEnd: l2Surface.length),
              ],
            ),
          ],
        ),
      ],
    );

Future<bool> _runFor(String lang, String l2Surface) async {
  final db = MiningDb.forTesting();
  final repo = ComicRepository(db: db, pack: _pack(lang, l2Surface), dictionary: const _EmptyDict());
  final page = await repo.nextPage();
  final selected = page != null;
  if (page != null) await repo.finishPage(page, lookups: 0);
  final snaps = await db.select(db.passageSnapshots).get();
  final snapped = snaps.length == 1;
  await db.close();
  print('  [$lang] page selected: $selected, snapshot written: $snapped');
  return selected && snapped;
}

Future<void> main(List<String> args) async {
  print('=== Manga-Lesen gate (multi-language) ===');
  final ja = await _runFor('ja', '猫');
  final es = await _runFor('es', 'gato');
  final pass = ja && es;
  print('GATE: ${pass ? 'PASS' : 'FAIL'}');
  print(pass ? '=== PASS ===' : '=== FAIL ===');
}
```

- [ ] **Step 2: Run the proof**

```bash
cd <WT> && dart run tool/proof_manga_reading.dart
```
Expected: prints per-language lines and `GATE: PASS`, `=== PASS ===`.

- [ ] **Step 3: Run the full suite + analyze**

```bash
cd <WT> && flutter test && flutter analyze
```
Expected: all tests PASS; 0 analyze errors in new code.

- [ ] **Step 4: Commit**

```bash
git add tool/proof_manga_reading.dart
git commit -m "test(proof): manga reading gate proven for JA + ES (language-agnostic)"
```

---

## Self-Review notes (for the executor)

- **Spec coverage:** real comic with images + bubbles (Tasks 1–3), starts-easy-gets-harder via i+1 selector (Task 4, reuses `rankByIPlusOne`), immersion ramp L1→L2 (Tasks 1,5), reading-as-review tap→gloss + snapshot (Tasks 6–7), language-agnostic for any target language (Tasks 2,9 prove JA+ES; direction/reading generic in Task 3), keep-image handle for the OCR side-door (Task 8), placeholder-art MVP throughout.
- **Out of scope (as in the spec):** the real ComfyUI art + character-consistency pipeline; authoring a large graded catalog; in-reading due-card review for comics (the `InReadingReviewPanel` reuse is straightforward but the due-source needs the comic's spans in `MiningDb` — add once comics are DB-seeded like `SliceRepository._seedContent`); full RTL page-order for arbitrary imported manga; monetization.
- **Language discipline check:** grep the new `lib/features/comic/` for `'ja'` before finishing — the only allowed occurrences are in test/proof fixtures and asset filenames, never in `lib/features/comic/*.dart` logic (I8).
- **Verify before coding:** confirm on disk that `RankedPassage`/`IPlusOneWindow` field names and `FsrsKnowledgeSource.load`/`.call` match the reference dossier; and confirm the active-language + dictionary provider names used in Task 7 against `lib/features/mining_slice/reading_tab.dart` and `lib/app/knowledge_providers.dart`.
- **Depends on:** the Empfang plan (l10n `AppLocalizations`; the known-set that makes the i+1 selector meaningful). Run/merge Empfang first.
```
