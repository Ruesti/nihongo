# SPEC — Immersion Learning App

**Working title:** `<TBD, see §0.1>`
**Status:** SPEC FROZEN v1
**Owner:** Uli / Softbrew Studio
**Stack target:** Flutter · Drift/SQLite · local-first · optional sync later
**Document language:** English (implementation + deliverables)

**Structure:**
**Part A — Engine** (§1–§4): the mining pipeline. Infrastructure. Never directly visible to the user.
**Part B — Experience** (§5–§9): what the user actually touches. Datum, the unified text track, measurement as reward.

> Design axiom: *the flashcard is an implementation detail, not an interface.*
> If a screen in this app looks like Anki, it is a design defect.

---

## §0 — Interview Gate (MANDATORY)

**No implementation, no schema freeze, no repo scaffold until every question below is answered.**
Answers are recorded inline in this document and the status flips to `SPEC FROZEN v1`.

### §0.1 Identity & scope
1. Working title / package name? (affects bundle ID, repo name, Drift DB filename)
   **A: TBD — deferred. Use a placeholder package id for now; revisit before Phase 2 schema freeze.**
2. Standalone app, or a package intended for later embedding (à la `packages/agent_cockpit/`)?
   **A: Embeddable package — built to be pulled into a larger host app later.**
3. Is this a Softbrew Studio branded product (commercial path) or a personal tool published free?
   **A: Softbrew Studio commercial product. §0.15 dictionary-licensing compatibility must be resolved before Phase 2.**
4. Target platforms for v1: Android only, Android + Desktop (Linux), or all Flutter targets?
   **A: All Flutter targets (Android, iOS, Desktop, Web).**

### §0.2 Language scope
5. Is Japanese the only v1 language, with multi-language proven only by *architecture* (adapters stubbed)?
   Or must a second language ship in v1 as a real proof-of-seam?
   **A: JA is the only real v1 language. But "many languages possible" is an explicit goal — the four-seam design (§2.2) must genuinely generalize, not just tolerate one hypothetical second language. Proven via stub `LanguagePack`(s) in Phase 2; no real second data pack ships in v1.**
6. If a second language: which one, and is it a whitespace language (cheap) by design choice?
   **A: N/A for v1 — no real second language is planned yet. Deferred to whenever a real second pack is scheduled (see also Phase 11).**
7. Is the UI localized (DE/EN), or English-only like the other Softbrew products?
   **A: Localized DE/EN.**

### §0.3 Sources
8. Which source adapters are in v1 scope? Rank: plain text · EPUB · SRT/ASS · Android share-target · clipboard · OCR
   **A: Plain text, EPUB, SRT/ASS, and OCR (manga/image) are all in v1 *content-source* scope. SRT/ASS is the primary proof case for the acceptance demo. Note: this does not override the Phase plan — §11's risk gate still sequences OCR at Phase 12, never earlier, regardless of "in scope" status. Android share-target and clipboard are also both in scope as intake mechanisms.**
9. Is A/V media handling in v1 (audio+screenshot extraction from a local video file), or is v1 text-only?
   **A: Yes — A/V extraction is in v1.**
10. If A/V: is `ffmpeg` bundled (licensing + ~30 MB APK cost) or assumed present on desktop only?
    **A: Bundled everywhere (all platforms), consistent with the "all Flutter targets" answer in §0.1.4. Licensing review required before shipping (see §11 risks).**

### §0.4 Knowledge model
11. Is the SRS **inside** this app, or does v1 export to Anki (AnkiConnect / `.apkg`) and defer the SRS entirely?
    *(This is the single biggest scope fork in the document.)*
    **A: SRS is in-app. This confirms Part B's core mechanics (§7 re-presentation, Phase 7 in-reading review, Datum's measurement narrative) as real v1 scope, not deferred.**
12. If SRS is in-app: FSRS confirmed? Which Dart implementation, or FFI to `fsrs-rs`?
    **A: Both. Scheduling uses the pure-Dart `fsrs` package (`open-spaced-repetition/dart-fsrs`, pub.dev: `fsrs`) — actively maintained, no FFI/Rust toolchain needed for v1. FFI to `fsrs-rs` stays a later option if parameter-optimisation needs surface that the Dart port lacks.**
13. What defines "known" for the i+1 calculation — FSRS stability threshold, review count, or an explicit user mark?
    **A: FSRS stability threshold. Fully automatic, a real measurement — consistent with §6.2's "no invented number" rule for Datum.**
14. Is there a bootstrap path for existing knowledge (import Anki collection / WaniKani level / "mark first N of frequency list as known")?
    **A: Yes, three paths, all in v1, not mutually exclusive: (1) "mark first N of frequency list as known" — default/simplest, language-agnostic; (2) Anki collection import (.apkg/AnkiConnect); (3) WaniKani level import (JA-specific, fits v1 scope).**

### §0.5 Dictionary & licensing
15. JMdict/KANJIDIC are CC-BY-SA / EDRDG-licensed. Confirm attribution surface in-app and compatibility with a paid product (§0.1.3).
    **A: In-app attribution screen. JMdict/KANJIDIC's EDRDG licence permits commercial use with visible attribution — standard practice for commercial JA dictionary apps.**
16. Dictionary shipped in-APK, or downloaded on first run? (UniDic + JMdict ≈ 100–150 MB)
    **A: Downloaded on first run. Keeps the base install small; one-time network fetch, fully offline after caching.**
17. Tatoeba sentences (CC-BY) in scope as a fallback corpus, or user-material only?
    **A: Yes, in scope as a fallback corpus — used when the user's own material has no example sentence for a lemma. One additional attribution line.**

### §0.6 Non-goals
18. Explicitly out of scope for v1 — confirm each: cloud sync · shared decks · social/leaderboards · grammar SRS · handwriting recognition · pitch-accent training · speech scoring
    **A: Confirmed — all seven are out of scope for v1. Consistent with the "instrument, not a game" axiom; none of them fit the measurement-based reward mechanic.**
19. Anything above that must be moved *into* v1?
    **A: No. None of the seven move into v1.**

### §0.7 Definition of Done
20. What is the acceptance demo for v1? Proposed: *"Load one SRT of a 24-minute episode, produce a ranked i+1 candidate list, mine 20 cards with audio + screenshot, review them, and have the schedule survive an app restart."* Accept, or amend.
    **A: Accepted as proposed.**

### §0.8 Experience layer — Datum
21. Is the mascot from the YouTube work (**Datum**) canonically reused here, or is this a separate incarnation that merely shares the name?
    **A: Yes — the same character, canonically reused. Visual assets and voice must stay consistent with the existing YouTube-work incarnation.**
22. Does a character bible / voice guide already exist? If yes it is normative and supersedes §6.2 of this document.
    **A: No standalone bible document exists (confirmed by search — none found in this repo or elsewhere on disk as of this freeze). §6.2 of this document stands as the working voice spec until a formal bible is written; §6.2 is provisional in that sense but authoritative for now.**
23. Visual form: is Datum an existing rendered asset (2D/3D), or does it need to be designed for this app?
    **A: An existing 2D/3D asset already exists (from the YouTube work) and is to be reused, not redesigned.**
24. Is Datum ever *silent*? Confirm: a user must be able to run the entire app with Datum's commentary disabled without losing function.
    **A: Confirmed. Datum is fully disableable; disabling it removes personality, never information (§0.24 hard constraint stands as written).**
25. Does Datum speak German, English, or the target language? (Constrains localisation scope from §0.7.)
    **A: The user's UI language (DE or EN, per §0.1.7) — not the target/immersion language.**

### §0.9 Experience layer — measurement
26. Re-presentation cadence: is a passage re-offered on a fixed schedule, on an FSRS-derived trigger, or only on explicit user request?
    **A: FSRS-derived trigger. Reuses the same stability logic as §0.4.13 — one scheduling system, not two.**
27. Is dwell time recorded at all? It is the most informative and most privacy-sensitive signal in the app. Local-only confirmed?
    **A: Yes, recorded — strictly local-only, never synced or uploaded. Consistent with §1's "local-first, no cloud dependency in v1."**
28. Is the opening screen (§8) mandatory on every launch, or only when a meaningful delta exists?
    **A: Only when a meaningful delta exists. Falls back to the most-recently-read passage view otherwise, per §8's existing graceful-empty-state requirement.**
29. What happens when the delta is *negative* (a passage got harder after a long break)? Datum reports it honestly — confirm, or specify softening.
    **A: Confirmed — reported honestly, unmodified. No softening; this is load-bearing for the instrument's credibility per §7.**

### §0.10 Experience layer — media
30. Manga OCR: in v1 or deferred? It is the single largest engineering item in Part B.
    **A: In scope, but sequenced at Phase 12 per the §11 risk gate — never earlier, consistent with the §0.3.8 answer.**
31. Is video playback in-app, or does the app pair with an external player?
    **A: In-app player. Required for `TimeAnchor` sync and seamless mining directly from playback; an external player would need fragile screen-overlay hacks.**
32. Are works imported by the user only, or is there any bundled/sample content for first run?
    **A: Both. User import is the core path; a small public-domain sample work also ships for a better first-run experience without requiring the user's own content immediately.**

---

# PART A — ENGINE



Mainstream language apps (Duolingo et al.) train recognition against synthetic content. Retention is optimized for the app, not the learner. The two mechanics with the strongest evidence base — spaced repetition and comprehensible input — exist today only as a fragile toolchain (Yomitan + asbplayer + Anki + add-ons) that requires a desktop, manual glue, and tolerance for breakage.

**Thesis:** the mining loop can be a single local-first mobile application, and the language-specific parts are small enough to isolate behind four adapters.

## 2. Architecture

### 2.1 Data flow

```
Source ──▶ Segmentation ──▶ Tokenizer ──▶ Lemma normalisation
       ──▶ Knowledge lookup ──▶ Sentence scoring ──▶ Card assembly ──▶ SRS
```

Each arrow is a pure function over the previous stage's output. No stage reaches backwards. The pipeline is re-runnable over an unchanged source with changed knowledge state, and must produce a different (better) result — this is a hard requirement, not an optimisation.

### 2.2 The four seams

All language-specific behaviour lives behind these interfaces. Adding a language must be a **data package plus one adapter registration**, never a branch in pipeline code.

| Seam | Interface | JA implementation | Whitespace-language implementation |
|---|---|---|---|
| `Tokenizer` | `List<Token> tokenize(String)` | Lindera or Sudachi.rs via FFI | ICU word-break + lemma table |
| `Dictionary` | `List<Sense> lookup(String lemma, Pos pos)` | JMdict + JMdict-Furigana | Wiktextract / FreeDict |
| `FrequencyList` | `int? rank(String lemma)` | BCCWJ / JPDB / subtitle corpora | OpenSubtitles frequency |
| `ReadingProvider` | `Reading? reading(Token)` | JMdict-Furigana mapping | `null` |

```dart
abstract interface class LanguagePack {
  String get code;                 // BCP-47
  Tokenizer get tokenizer;
  Dictionary get dictionary;
  FrequencyList get frequency;
  ReadingProvider? get readings;   // null for languages without a reading layer
}
```

**Seam discipline rule:** if pipeline code ever needs `if (lang == 'ja')`, the seam is wrong and the design is reopened.

### 2.3 Core types

```dart
class Segment {
  String text;
  String sourceId;
  int ordinal;
  Duration? tStart;   // present for subtitle/AV sources
  Duration? tEnd;
}

class Token {
  String surface;     // as it appears in text
  String lemma;       // normalised dictionary form
  String? reading;    // kana for JA, null elsewhere
  Pos pos;
  int charStart, charEnd;   // span into Segment.text — required for furigana + highlight
}

enum Knowledge { unknown, learning, known }

class ScoredSegment {
  Segment segment;
  List<Token> tokens;
  int unknownCount;
  double knownRatio;
  int? targetRank;    // frequency rank of the single unknown lemma, if unknownCount == 1
}
```

### 2.4 Card ≠ Sentence

The SRS item is the **lemma**. The sentence is the *currently best available context* for that lemma and is a mutable field, not identity.

Consequence: when knowledge state improves, a card's example sentence may be re-elected from the corpus for a better i+1 fit. This requires a stable `vocab_item.id` decoupled from `context_sentence_id`, and it is the primary differentiator against every existing mining tool.

## 3. Sentence scoring

For each segment:

```
unknownCount = |{t ∈ tokens : knowledge(t.lemma) == unknown}|
knownRatio   = |{t : knowledge == known}| / |tokens|
```

Candidate ranking (descending priority):
1. `unknownCount == 1` (true i+1)
2. Lower frequency rank of the target lemma (more common word → higher yield)
3. Segment length within `[minLen, maxLen]` — very short segments carry no context, very long ones are unpleasant to review
4. Presence of `tStart`/`tEnd` (audio available)

`unknownCount == 2` segments are retained as a secondary pool, surfaced only when the i+1 pool is exhausted. Greedy selection over the whole corpus; complexity is linear in tokens and must complete a full novel in **< 10 s on device** (perf gate, Phase 3).

## 4. Storage

Drift/SQLite, local-first, no cloud dependency in v1.

Tables (indicative, frozen after §0):
`source` · `segment` · `token_occurrence` · `vocab_item` · `review_log` · `card` · `media_blob` · `language_pack`

Notes:
- `token_occurrence` is the join enabling sentence re-election; expect it to be the largest table. Index on `(lemma, source_id)`.
- Known-lemma set is cached in memory as a `HashSet<String>` and invalidated on review commit — the lookup stage must stay sub-millisecond for ~30 tokens.
- `review_log` is **append-only**. FSRS parameter re-optimisation depends on complete history; the same discipline as the agent daemon event log.
- Media blobs live on the filesystem, not in SQLite; the table holds paths and a content hash.

---

# PART B — EXPERIENCE

## 5. The unified text track

Reader and player are not two features. Both media types reduce to a **work with a positioned text track**; only the positioning axis differs.

| Medium | Positioning | Span carries |
|---|---|---|
| EPUB / plain text | character offset in flow | — |
| Subtitles (SRT/ASS) | time interval | `tStart`, `tEnd` → audio extractable |
| Manga (OCR) | bounding box on page | `pageId`, `rect` |

```dart
sealed class Anchor {
  const Anchor();
}
class FlowAnchor extends Anchor { int charStart, charEnd; }
class TimeAnchor extends Anchor { Duration start, end; }
class SpatialAnchor extends Anchor { String pageId; Rect box; }

class TextSpan_ {
  String workId;
  int ordinal;      // reading order, medium-independent
  String text;
  Anchor anchor;
}
```

Consequences, all of them load-bearing:
- One interaction model. Tap a word → same lookup, same mining action, regardless of medium.
- Progress is **cross-medial**. A word first met in a novel counts as known when it appears in an episode. This is the main reason not to build two apps.
- Renderers are swappable and thin. A renderer knows how to draw spans and report taps; it knows nothing about vocabulary, scheduling, or Datum.
- `Segment` from §2.3 becomes a view over `TextSpan_`, not a parallel type.

## 6. Datum

### 6.1 Role

Datum is the voice of the instrument. Not a teacher, not a cheerleader, not a companion in the emotional sense — **a well-made measuring device that happens to talk.**

The character does the work that a points system would otherwise do, and does it better, because it is grounded in real observations about the user's actual reading history rather than invented currency.

### 6.2 Voice rules (authoritative per §0.22 — no separate character bible exists; supersede this section only if one is written later)

**Datum does:**
- Report measurements: *"This word last appeared in episode 4. Twenty-three days ago. Not recognised then."*
- Give advice framed as its own preference: *"Three unknown words in this sentence. I would read on."*
- Notice patterns without drawing conclusions: *"You look up verbs more often than nouns. I have no theory about this."*
- Admit uncertainty in its own model: *"I predicted you knew this one. I was wrong. Adjusting."*

**Datum never:**
- Praises effort ("Great job!", "You're on fire!")
- Uses exclamation marks, emoji, or streak language
- Guilts the user about absence
- Invents a number that does not correspond to a real measurement
- Claims a feeling about the user's progress

**Register:** dry, precise, mildly pedantic, quietly fond. The humour comes from a machine applying rigour to something that does not warrant it. Any single line must still be tolerable on the hundredth reading — which rules out enthusiasm and rules in understatement.

**Hard constraint (§0.24):** every Datum utterance is an ornament on a state that is legible without it. Disabling Datum removes personality, never information.

### 6.3 Utterance model

Datum lines are not authored strings scattered in the UI. They are generated from a template registry keyed by observation type, so that new lines are a data change and localisation is a table.

```dart
class Observation {
  ObservationKind kind;   // reencounter, prediction_miss, delta_measured, load_warning, …
  Map<String, Object> facts;   // days_since, episode_ref, delta_pct, …
}
```

A line may only be emitted if every fact it interpolates is backed by a real record. **No line is permitted to render a value the engine did not measure.** This is testable and must be tested (Phase 6 gate).

## 7. Re-presentation — the honest competition

The self-competition mechanic. No invented scale, no synthetic difficulty rating: the same text, twice, with real measurements.

**First pass.** While reading, the app records per passage:
- unknown-token ratio at time of reading
- dwell time (§0.27 — local only)
- lookup count
- mining events

This is written as an immutable `passage_snapshot`.

**Second pass.** Weeks later the passage is re-offered. The same metrics are recorded. The delta is the score.

```
Δ unknown ratio   41% → 8%
Δ lookups         7 → 1
Δ dwell           2m 14s → 41s
```

Notes:
- Dwell time is noisy (interruptions, re-reading for pleasure). Treat it as indicative, display it with less weight than the unknown ratio, and discard outliers rather than showing nonsense.
- A negative delta is displayed, not hidden (§0.29). The whole credibility of the instrument rests on this.
- Re-presentation requires no new content, which makes it cheap to build and independent of the user's library size.

## 8. The opening screen is a proof, not a menu

Ranked first in the elicitation: *visibly easier text*. Therefore the launch screen is exactly one artifact.

```
┌─────────────────────────────────────┐
│  THEN                    NOW        │
│  [passage, unknown       [same       │
│   words marked]           passage,    │
│                           mostly      │
│                           clean]      │
│                                       │
│  Datum: "Chapter 2. Six weeks ago,   │
│          forty-one percent unknown.  │
│          Today, eight."               │
│                                       │
│  [ Continue reading ]  [ Library ]   │
└─────────────────────────────────────┘
```

Requirements:
- No task count, no due-card number, no streak anywhere on this screen.
- Falls back gracefully when no delta exists yet (new user, no history): show the most recently read passage and a Datum line that says so plainly.
- Navigation is below the fold, always.

## 9. Additional data model (Part B)

Extends §4. Frozen together with Part A after §0.

| Table | Purpose | Notes |
|---|---|---|
| `work` | a book, series, episode, volume | medium-agnostic; groups text spans |
| `text_span` | positioned text unit | replaces standalone `segment`; carries `Anchor` as tagged union |
| `reading_session` | one continuous engagement with a work | start/end, device, span range covered |
| `passage_snapshot` | immutable measurement of one passage at one time | the substrate of §7; append-only |
| `observation` | facts available to Datum | derived, may be recomputed; never a source of truth |

`passage_snapshot` and `review_log` are both append-only for the same reason: every measured claim the app makes must be traceable to a record it cannot have altered afterwards.

---

## 10. Phase plan

Each phase ends with a `BERICHT_<n>_<name>.md` proof report containing measured evidence, not assertions. Commit on green. No phase starts before the previous report is accepted.

| Phase | Deliverable | Gate criterion |
|---|---|---|
| **0** | Interview gate closed, SPEC frozen | All §0 questions answered in-document |
| **1** | **Lindera FFI spike** — isolated, no app | Tokenize 10 k JA sentences on a physical Android device; report cold-start time, per-sentence latency p50/p99, dictionary size on disk, APK impact |
| **2** | Schema + `LanguagePack` seams, JMdict import | Full JMdict imported; lemma lookup benchmarked; second stub `LanguagePack` (no real data) compiles and registers — proves the seam |
| **3** | Pipeline stages 1–4, headless | One SRT in → ranked `ScoredSegment` list out, as a CLI/test harness. Perf gate from §3 met |
| **4** | Knowledge model + bootstrap import | Existing knowledge importable; re-running Phase 3 over the same source yields a demonstrably different ranking |
| **5** | Card assembly incl. furigana, audio, frame | 20 cards produced from a real episode; artifacts inspectable on disk |
| **6** | Unified text track + one renderer (§5) | EPUB and SRT both reduce to `TextSpan_`; tapping a word behaves identically in both; renderer contains zero vocabulary logic — verified by inspection |
| **7** | Scheduling woven into reading (no review screen) | A due item is surfaced in reading flow and graded without leaving the reader |
| **8** | `passage_snapshot` + re-presentation (§7) | A passage read in Phase 6 is re-offered and a real delta is computed and displayed, including a negative one |
| **9** | Datum utterance layer (§6) | Template registry live; automated test proves no line can render an unmeasured fact; app fully functional with Datum disabled |
| **10** | Opening screen (§8) | Then/Now proof renders from real history; graceful empty state verified |
| **11** | Second language pack with real data | New language added with zero changes to pipeline **or** experience code — verified by diff |
| **12** | Manga OCR (if in scope per §0.30) | `SpatialAnchor` path works end to end |

Phase 1 is a **kill gate**. If Lindera on-device is not viable, the whole product direction is re-planned before any schema exists.

Phase 6 is the **second kill gate**: if the unified text track does not hold — if the renderer starts needing to know about medium-specific vocabulary behaviour — then Part B's core premise is wrong and the product splits into two apps or drops one medium. Better to find out at Phase 6 than Phase 10.

## 11. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Lindera/UniDic size or latency unacceptable on mobile | Fatal to concept | Phase 1 kill gate before any other work |
| Dictionary licence incompatible with commercial product | Business model | Resolved in §0.15 before Phase 2 |
| `token_occurrence` table growth on large corpora | Perf/storage | Measure in Phase 3; fall back to on-demand re-tokenisation if needed |
| Scope creep into grammar SRS / pitch accent / handwriting | Never ships | §0.18 non-goals list is binding |
| FSRS Dart port immaturity | Scheduling quality | Evaluate in §0.12; FFI to `fsrs-rs` as fallback |
| Manga OCR effort dwarfs the rest of Part B | Schedule | §0.30 decides in or out *before* Phase 2; if in, it is Phase 12 and never earlier |
| Datum becomes grating on repeat exposure | Product identity | Voice rules §6.2 are binding; every line must survive a hundredth-reading test before it ships |
| Datum lines drift into unmeasured claims | Credibility — fatal | Template registry + automated test (Phase 9 gate) |
| Dwell time proves too noisy to display | Weakens §7 | Unknown-ratio delta is the primary metric; dwell is presented as secondary and may be dropped without redesign |
| Two renderers diverge into two products | Doubles scope | Phase 6 kill gate |

## 12. Open design questions (post-§0, do not block Phase 1)

**Engine**
- Sentence re-election policy: automatic, or user-confirmed?
- Do proper nouns count toward `unknownCount`? (They wreck i+1 ratios in fiction.)
- Multi-word expressions and JA compound verbs — one item or several?
- Conjugated forms: is the card the lemma only, or does the surface form matter for production?

**Experience**
- How is a "passage" delimited for snapshot purposes — chapter, scene, fixed span count, user selection?
- Does Datum have a visual presence in the reader, or only on the opening screen and in interstitials?
- When a due item never occurs naturally in what the user is reading, is it eventually surfaced as an explicit card — and does that reintroduce the very screen this design forbids?
- Cross-medial progress: does a word known from text count as known when *heard*, or is listening a separate competence with its own state?

---

*Attribution obligations for JMdict/KANJIDIC (EDRDG), KanjiVG, and Tatoeba are to be enumerated in `LICENSES.md` before Phase 2 completes.*
