# Reconciliation — current app vs. SPEC_MINING_PIPELINE.md (SPEC FROZEN v1)

**Purpose:** map what already exists in `nihongo_app` (built against the old
CLAUDE.md / PHASES.md curriculum-app model) against the new immersion-mining
spec, so Phase 1 work starts from an accurate picture of what's reusable,
what's obsolete, and what's net-new.

**Structural note first, because it changes where new code even lives:**
§0.1.2 of the frozen spec answers *"embeddable package, built to be pulled
into a larger host app later (à la `packages/agent_cockpit/`)."* The current
app is a standalone Flutter app, not a package. This reconciliation is
therefore not "which files in `lib/` do we edit" — it's "which existing code
gets **extracted** into a new package largely unchanged, vs. left behind."
See the open question at the end.

---

## Part A — Engine

| Existing artifact | Verdict | Notes |
|---|---|---|
| `core/tts_service.dart`, `stt_service.dart`, `api_client.dart`, `api_key_service.dart` | **Extract & reuse** | Platform plumbing, not curriculum-shaped. Ports into the new package largely as-is (today's TTS engine-preference/rate fixes carry over). |
| `core/database.dart` (legacy `SrsCard`/`UserProgress`) | **Discard** | Legacy lesson-progress schema, fully superseded. |
| `core/db/tables.dart` — `Concepts`/`Assets`/`Lexemes`/`GrammarPoints`/`Sentences`/`LearnItems`/`ReviewLog` | **Discard — redesign, not migration** | Curriculum-centric (hand-authored `Concepts`→`Lexemes`) vs. the new spec's lemma-centric mined model (`source`, `segment`/`text_span`, `token_occurrence`, `vocab_item`, `card`, `work`, `reading_session`, `passage_snapshot`, `observation` — §4/§9). Different identity rules (§2.4: card ≠ sentence). |
| `core/db/tables.dart` — `ScriptProfiles`/`Characters`/`CharComponents` | **Possible reuse, unconfirmed** | May still inform reading/furigana data shape; not a hard requirement of the new spec, worth revisiting once `ReadingProvider` (§2.2) is built. |
| `core/srs.dart` (SM-2) | **Discard** | Replaced by the `fsrs` Dart package per §0.4.12. |
| `core/language_module.dart` / `script_profile.dart` (`LanguageModule`) | **Discard — different seam** | Old abstraction gates UI/exercise availability by script properties. New spec's `LanguagePack` (Tokenizer/Dictionary/FrequencyList/ReadingProvider, §2.2) abstracts linguistic processing. No naming collision, but no conceptual overlap either. |
| Tokenizer (Lindera/Sudachi FFI), Dictionary (JMdict import), FrequencyList, sentence scoring, `token_occurrence` | **Net new** | Nothing exists today. This is Phase 1 (kill gate) + Phase 2/3. |
| A/V extraction (`ffmpeg`) | **Net new** | No AV/ffmpeg dependency in `pubspec.yaml`. |
| Source adapters (EPUB/SRT-ASS/OCR/share-target/clipboard) | **Net new** | No EPUB/subtitle-parsing package present (`xml` dep is generic, not purpose-built). |
| `core/purchases_service.dart` / `feature_gate.dart` (RevenueCat) | **Reusable later, not v1-critical** | Spec confirms a commercial product (§0.1.3) but never specifies monetization shape for the new features. Current paywall logic gates *language packs*, which don't exist in the new v1 — needs redesign whenever monetization is scoped, but the RevenueCat plumbing itself carries over. |

## Part B — Experience

| Existing artifact | Verdict | Notes |
|---|---|---|
| `features/lesson/*` (lesson_screen, exercise_factory, all exercise types) | **Discard entirely** | Exactly the paradigm the spec forbids (*"if a screen looks like Anki, it is a design defect"*). Today's TTS/state-key bugs in this code are moot — the whole path goes away. |
| `features/kanji_games/{quiz,blitz,memory}` | **Discard** | No games-hub concept in the new spec. |
| `features/kanji_games/trace/*` (stroke_painter, kanji_svg_loader, stroke_validator) | **Shelve, don't discard code** | KanjiVG stroke-rendering tech isn't inherently game-shaped, but handwriting recognition is a confirmed non-goal for v1 (§0.6.18) — nothing to do with it yet. |
| `features/kaiwa/*` (conversation, shadowing) | **Discard for v1** | Not mentioned anywhere in Part B. |
| `features/travel/*` | **Discard** | Not mentioned in the new spec. |
| `features/language_select/*`, `packs/{es,ko,ar,hi,zh}` | **Discard for v1** | §0.2 confirms JA-only v1 (this is PR #1's content — already paused). |
| `features/home/*` (dashboard, lesson_grid), `features/progress/*` | **Discard** | Replaced by the §8 Then/Now opening screen — a different screen concept entirely (no lesson grid, no XP progress bars). |
| `models/mascot_state.dart` + `features/home/mascot_widget.dart` (Tamago-chan) | **Discard, replaced by Datum** | Confirmed separate character (§0.8.21–23: Datum is the canonical YouTube character with an existing asset, reused as-is). Tamago-chan's XP/level egg-hatch states have no equivalent in Datum's measurement-narrator model. No Datum asset files exist in this repo yet — they live in the separate YouTube-work project per §0.8.23. |
| `widgets/furigana_text.dart` | **Reuse directly** | Ruby-text rendering is medium-agnostic — needed by both the reader and dictionary lookups. |
| `widgets/audio_button.dart` | **Reuse** | Thin wrapper over `tts_service`; still useful for inline audio in the reader. |
| `widgets/progress_bar.dart`, `grade_buttons.dart` | **Discard** | Shaped for the old lesson/exercise flow; Phase 7 grading happens inline in reading — different interaction model, needs new design. |
| Unified text track (`TextSpan_`/`Anchor`), EPUB/SRT/manga renderers, `passage_snapshot` + re-presentation screen, Then/Now opening screen, Datum utterance template registry | **Net new** | Core of Part B, none of it exists. |

---

## Structural decision: where the new code lives

**Resolved:** `nihongo_app` is replaced in place. Same repo, same top-level
app — immersion-mining features grow in, and each old lesson/game/kaiwa/
travel module (per the tables above) is deleted once its replacement lands.
No new package or separate repo for now.

Note this is a pragmatic reading of §0.1.2's "embeddable package" answer
rather than a literal one — the app isn't structured as an embeddable
package today. If a host-app embedding actually needs to happen later,
carving the engine out of `nihongo_app`'s `lib/core` into a package is a
mechanical extraction at that point, not a redesign, since the discard/reuse
split above already isolates engine code from app-shell code. Revisit if
that assumption turns out wrong.

This decides where Phase 1's Lindera spike gets scaffolded: directly inside
this repo's `nihongo_app`, e.g. as an isolated test/tool target, not a new
package.

---
*Softbrew Studio — reconciliation snapshot — 2026-07-28.*
