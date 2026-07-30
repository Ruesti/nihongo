# BERICHT 2 — Schema + LanguagePack Seams + JMdict Import

**Phase:** 2 — Schema + `LanguagePack` seams, JMdict import (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** Full JMdict imported; lemma lookup benchmarked; second stub `LanguagePack` (no real data) compiles and registers — proves the seam.
**Verdict: PASS.**

---

## What was built

### Schema (`lib/core/db/mining_tables.dart`, `mining_db.dart`)

A new, separate Drift database (`MiningDb`) implementing the §4/§9 table
list: `Works`, `Sources`, `TextSpans` (replaces standalone `segment` per
§9), `TokenOccurrences`, `VocabItems`, `Cards`, `ReviewLogs`,
`MediaBlobs`, `LanguagePacks`, `ReadingSessions`, `PassageSnapshots`,
`Observations`. Deliberately **not** merged into the existing
`LearningDb` — per `RECONCILIATION.md`, the curriculum-centric old
schema (`Concepts`/`Lexemes`/`LearnItems`) and the lemma-centric mined
schema don't share identity; this is a redesign, not a migration.

`Cards` field names mirror the `fsrs` Dart package's `Card` class
(`state`, `step`, `stability`, `difficulty`, `due`, `lastReview`)
per the §0.4.12 decision, so DB rows round-trip through the scheduler
without a translation layer.

### The four-seam interface (`lib/core/language_pack/`)

`Tokenizer`, `Dictionary`, `FrequencyList`, `ReadingProvider`, and the
`LanguagePack` composite, matching §2.2's table exactly. Kept
**synchronous** as sketched in the spec, not `Future`-wrapped — §3's
"< 10s for a full novel" scoring budget rules out per-lookup async
DB round-trips inside the hot loop. Real implementations (see below)
build an in-memory index once at load time instead.

`Pos` is represented as a raw `String` (the source tokenizer's own tag,
e.g. IPADIC's `名詞,固有名詞,組織`), not a unified enum — different
languages' POS tag sets don't collapse onto one vocabulary cleanly, and
nothing downstream needs to interpret the tag, only compare it.

### JA `LanguagePack` (`lib/mining_packs/ja/`)

- **Dictionary + ReadingProvider: real, JMdict-backed.** `jmdict_importer.dart` parses the raw JMdict_e XML (EDRDG, `http://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz`) and populates `JmdictDb` (its own database — dictionary data is per-pack, not shared pipeline state). `JaLanguagePack.load()` then builds an in-memory `lemma -> entryIds` and `kanji -> reading` index from it once; `lookup()`/`reading()` are synchronous Map reads against that index afterward.
- **FrequencyList: honest stub.** No frequency corpus (BCCWJ/JPDB/subtitle-derived) has been acquired — `rank()` always returns `null`, which is the correct contract for "not in the list," not a placeholder pretending to work.
- **Tokenizer: documented deferral, not a fake.** Lindera 4.0.0 + embedded IPADIC was already proven viable on a physical Android device in Phase 1 (785ms cold start, p99 0.259ms/sentence — `BERICHT_1_lindera-spike.md`). Wiring that FFI setup into `nihongo_app`'s own Android build (rather than the throwaway `spike/` project) is mechanical repetition of already-solved toolchain problems, not new risk — deferred to Phase 3's pipeline-stages work rather than done here, since Phase 2's gate is dictionary-focused. `tokenize()` throws `UnimplementedError` with a message pointing at the proof, rather than silently returning naive/wrong segmentation that would corrupt every downstream stage without anyone noticing.

### Second stub `LanguagePack` (`lib/mining_packs/stub/`)

Code `xx` (ISO 639 reserved-for-testing tag, so nobody mistakes it for
real second-language coverage — §0.2 confirmed none ships in v1). Every
seam member is **fully real and running**, not stubbed-and-thrown: a
regex-based whitespace/punctuation tokenizer (§2.2's "ICU word-break"
row, simplified), empty `Dictionary`/`FrequencyList`, no `ReadingProvider`.
This is what actually proves seam genericity — the JA pack alone
wouldn't, since it's the only implementation the design was built
around.

### Registry (`lib/core/language_pack/language_pack_registry.dart`)

A `code -> LanguagePack` map. Adding a language is calling `.register()`
with a data package, never a branch in pipeline code — the seam
discipline rule from §2.2 holds by construction here since there's no
`if (code == 'ja')` anywhere in the registry or the interfaces.

## Measured evidence

Run via `dart run tool/phase2_import_and_benchmark.dart <path-to-JMdict_e>`
against the real, current JMdict_e (fetched fresh, EDRDG, 62.9MB
uncompressed XML):

```
=== Importing JMdict ===
entries:  218173
lemmas:   497548
senses:   252681
elapsed:  27737 ms

=== Loading JA LanguagePack (in-memory index) ===
index build: 5309 ms

=== Benchmarking lemma lookup ===
probes:        2000
senses found:  4615 total
p50:           0.00 µs
p99:           3.00 µs
max:           394.00 µs

Spot check 日本語 -> [Japanese (language)]

=== Second stub LanguagePack: compiles and registers ===
registered codes: [ja, xx]
stub tokenizer on a real sentence -> [hello, world, this, is, a, test]
ja pack resolved from registry: code=ja, readings=true

=== PASS ===
```

Full JMdict imported (all 218,173 entries — not a sample), lemma lookup
benchmarked (p50/p99 in **microseconds**, three orders of magnitude
inside any realistic per-frame or per-sentence budget, because it's an
in-memory Map read rather than a query), second stub pack compiles,
registers, and its tokenizer actually runs against real text.

## Automated tests

24 new tests (`test/core/language_pack/`, `test/mining_packs/`,
`test/core/db/mining_db_test.dart`), covering: registry
register/resolve/replace semantics, the stub tokenizer's offsets and
punctuation handling, JMdict custom-DTD-entity resolution specifically
(a small inline fixture with `<!ENTITY n "...">`-style declarations —
this is the exact thing that breaks naive XML parsers), sense/gloss
parsing correctness, and `MiningDb` schema creation + upsert semantics.

Combined with the pre-existing suite: **287/287 tests pass**
(263 existing + 24 new). `flutter analyze`: 0 new errors.

## A note on the JMdict file itself

Not committed to the repo — 62.9MB uncompressed, updated daily upstream,
and §0.5.16 already decided dictionary data ships via first-run
download, not bundled in-APK. The import/benchmark tool takes a file
path argument; fetching a fresh copy is one `curl` command
(documented in the tool's header comment).

## Known gap, carried forward honestly

The JA `Tokenizer` is not wired to Lindera in `nihongo_app` yet — see
above. This does not weaken the Phase 2 gate (which is about the
schema, the seam abstraction, and JMdict), but it's real remaining work
before Phase 3 ("Pipeline stages 1–4, headless: one SRT in -> ranked
`ScoredSegment` list out") can complete, since that phase needs a
working tokenizer in the loop.

## Gate verdict

**PASS.** Schema frozen, seam interfaces defined and exercised by two
independent implementations (one real, dictionary-backed; one minimal
but genuinely running), JMdict fully imported with sub-3µs p99 lookup
latency. Proceed to Phase 3, with the tokenizer-integration gap as its
first item.

---
*Softbrew Studio — Phase 2 proof report — 2026-07-28.*
