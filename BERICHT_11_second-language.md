# BERICHT 11 — Second Language Pack With Real Data

**Phase:** 11 — Second language pack with real data (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** New language added with zero changes to pipeline **or** experience code — verified by diff.
**Verdict: PASS.**

---

## Scope note (§0.2 tension, resolved)

§0.2 of the frozen interview gate says "no real second data pack *ships*
in v1." The Phase 11 gate asks for a real second pack "verified by
diff." These aren't in conflict: Phase 11 is an **architecture proof**,
not a shipped feature. The Spanish pack built here exists to demonstrate
that a real second language drops into the four-seam design with zero
changes to pipeline or experience code — it is **not wired into the app
or shipped to users in v1**. (FreeDict spa-eng is GPL-licensed; a
licensing review like JMdict's §0.5 would be required before any pack
actually ships — moot here precisely because this one doesn't.)

## What was built

A real Spanish `LanguagePack` (`lib/mining_packs/es/`), entirely
self-contained — deliberately not reaching into the JA pack for shared
helpers, so the diff proves a new pack needs no changes *anywhere*, not
even to sibling packs:

- **`EsWhitespaceTokenizer`** — §2.2's "whitespace-language
  implementation": a Unicode word-break regex, no FFI, no dictionary,
  no toolchain. The cheap seam the design promised for whitespace
  languages, in direct contrast to JA's Lindera FFI.
- **`EsPackDb` + `freedict_importer.dart`** — real dictionary data:
  FreeDict spa-eng (TEI P5), 4,502 headwords with English glosses.
- **`es_frequency_importer.dart`** — real frequency data: 80,511 lemmas
  ranked from 441,131 Tatoeba Spanish sentences, counted with the ES
  tokenizer.
- **`EsLanguagePack`** — implements the exact same `Tokenizer`/
  `Dictionary`/`FrequencyList`/`ReadingProvider` interfaces JA does.
  Two seams differ in kind, exactly as §2.2's table predicts for a
  whitespace language: the tokenizer is regex word-break, and
  `readings` is `null` (Spanish has no separate reading layer).

## The gate: verified by diff

The whole point. Everything new lives under `lib/mining_packs/es/`;
**nothing** in the pipeline or experience was touched:

```
$ git status --short -- lib/core/pipeline lib/features \
      lib/core/text_track lib/core/language_pack lib/core/media \
      lib/core/sources lib/core/datum
(empty — no pipeline/experience changes)

$ git status --short -- lib/  (excluding .g.dart)
?? lib/mining_packs/es/
```

- **`lib/core/pipeline/`** (sentence scoring, ranking, passage
  snapshot/delta, FSRS, card assembly, knowledge, review scheduler) —
  unchanged.
- **`lib/features/`** (reader, opening screen, Datum display) —
  unchanged.
- **`lib/core/text_track/`, `lib/core/language_pack/`,
  `lib/core/sources/`, `lib/core/media/`, `lib/core/datum/`** —
  unchanged.
- No existing generated file changed; only the new `es_pack_db.g.dart`
  is added.

The pack registers through the existing generic
`LanguagePackRegistry.register()` — no registry change, no
`if (lang == 'es')` anywhere.

## Measured evidence — the unchanged pipeline running on Spanish

`tool/phase11_second_language.dart` drives the *existing* core pipeline
end to end over the Spanish pack:

```
=== Setup: importing REAL Spanish data ===
FreeDict lexemes: 4502
frequency: 441131 sentences, 80511 lemmas
registered language packs: [es]

=== The unchanged pipeline, running on Spanish ===
spans: 400, i+1 candidates: 132
top i+1 candidates (real ES words + FreeDict glosses):
  [rank 817]  cámara   = [camera]            ← "El otro día compré una cámara."
  [rank 845]  viajar   = [travel]            ← "Me gustaría poder viajar alrededor del mundo."
  [rank 941]  paraguas = [umbrella]          ← "Puedes tomar un paraguas si necesitas uno."
  [rank 992]  novio    = [beloved, loved one]← "Ella tiene un nuevo trabajo y novio nuevo."
  [rank 1032] segundo  = [second]            ← "El segundo libro es mío."
  [rank 1044] arroz    = [rice]              ← "¿Tienes arroz?"

=== Re-presentation + Datum, over Spanish ===
Capítulo 1: 43% → 6% unknown
Datum (UI language DE): "Capítulo 1. Vor 6 Wochen: 43 Prozent unbekannt. Heute: 6."

=== Phase 11 gate ===
real ES data imported:                4502 lexemes, 80511 freq lemmas
ES pack registered:                   true
unchanged pipeline scored/ranked ES:  true
re-presentation delta over ES:        true
Datum voiced the ES measurement:      true
GATE: PASS
```

Every core stage ran over Spanish with no ES-specific code in it:

- The **SRT source adapter** (`core/sources`) parsed a Spanish episode
  into spans.
- **Sentence scoring + ranking** (`core/pipeline`) produced 132 i+1
  candidates — real Spanish target words with real FreeDict glosses
  (`cámara`=camera, `viajar`=travel, `paraguas`=umbrella, `arroz`=rice).
- **Passage snapshot + delta** (`core/pipeline`) measured a Spanish
  passage improving 43% → 6% unknown.
- **Datum** (`core/datum`) voiced that Spanish measurement in the user's
  UI language (German, per §0.8.25 — Datum speaks the UI language, not
  the target language), using the exact same template registry, with no
  ES template added.

## On lemmatisation (a pack-quality note, not an architecture gap)

The ES tokenizer's lemma is the lowercased surface, so conjugated verb
forms won't all hit the dictionary's infinitives. Real ES lemmatisation
(conjugation → infinitive) would raise dictionary hit-rate — but it's a
change *inside the pack's tokenizer seam*, invisible to the pipeline,
which is exactly the point: pack quality is improvable without touching
core. The candidates above are the ones that already resolve cleanly.

## Gate verdict

**PASS.** A real second language — real dictionary, real frequency
corpus — was added purely as a new pack, and the entire existing
pipeline and experience (scoring, ranking, re-presentation, Datum, the
source adapter) ran over it unchanged, verified by a diff that touches
nothing outside `lib/mining_packs/es/`. The four-seam design genuinely
generalizes. Proceed to Phase 12.

---
*Softbrew Studio — Phase 11 proof report — 2026-08-04.*
