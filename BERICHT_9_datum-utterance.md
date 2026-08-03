# BERICHT 9 — Datum Utterance Layer

**Phase:** 9 — Datum utterance layer (SPEC_MINING_PIPELINE.md §10)
**Gate criterion:** Template registry live; automated test proves no line can render an unmeasured fact; app fully functional with Datum disabled.
**Verdict: PASS.**

---

## What was built

Datum is "the voice of the instrument — a well-made measuring device
that happens to talk" (§6.1). This phase is the machinery that lets it
talk *only* about things the engine actually measured.

### Observation model (`core/datum/observation.dart`)

§6.3's `Observation`: an `ObservationKind` (`reencounter`,
`predictionMiss`, `deltaMeasured`, `loadWarning`) plus a `facts` map.
Every fact must trace to a real measured record; this type is the
boundary that carries that guarantee into the utterance layer. (The
Drift row type for the `Observations` table was renamed to
`ObservationRow` — same `LanguagePackRow`/`ScriptProfileRow`
convention — so the domain type `Observation` owns its name.)

### Template registry (`core/datum/datum_registry.dart`)

Datum lines are data, not authored strings scattered in the UI (§6.3):
a registry keyed by `ObservationKind`, one table per UI locale (§0.8.25
— Datum speaks the user's language; localisation is another table, not
a code change). Each template is a pattern with `{fact}` placeholders.

`renderTemplate(template, facts)` is **the gate guard**: it returns
`null` if *any* fact the pattern interpolates is absent — never a
placeholder, never a blank, never an invented value. A line the facts
can't fully back is simply not emitted (§6.3: "No line is permitted to
render a value the engine did not measure").

### Voice (`core/datum/datum_voice.dart`) and display (`features/datum/datum_line.dart`)

`DatumVoice.say(observation)` turns an observation into a line or into
silence. Two silences, both load-bearing:
1. **Disabled** — the whole layer is off; it emits nothing for any
   input (§0.24: Datum is an ornament on state legible without it).
2. **Un-backable** — even enabled, if no template's facts are all
   present, nothing is emitted (§6.3).

`DatumLine` renders the line, or `SizedBox.shrink()` when there's
nothing to say — no gap, no placeholder, no "Datum has nothing to say"
notice. Its absence leaves the surrounding UI untouched.

## Measured evidence

### The automated no-unmeasured-fact test — the gate itself

`datum_registry_test.dart` runs over **every template in the registry**,
generically:

- For every template, removing *any one* required fact makes it emit
  nothing (`isNull`) — asserted per-template, per-fact. Add a template
  with a new fact later and it's automatically covered; this can't
  regress silently.
- A fully-backed template renders with *no* leftover `{placeholder}`.
- An empty facts map emits nothing for any template that needs facts.

Plus §6.2's voice rules enforced across all templates: **no exclamation
marks, no emoji, no streak/praise/effort language** — so the character
discipline is a test, not a style note that erodes over time.

### End-to-end on a real measurement

`tool/phase9_datum.dart` measures an *actual* passage delta (the Phase
8 pipeline, on the real 羅生門 EPUB), builds an observation whose facts
are exactly those measured numbers, and exercises all three properties:

```
=== Template registry live (locale de) ===
[reencounter]    needs [days_since, episode_ref]
[predictionMiss] needs [lemma]
[deltaMeasured]  needs [chapter, unknown_after, unknown_before, weeks_ago]
[loadWarning]    needs [unknown_count]

=== Datum voices a REAL measurement ===
measured facts: {chapter: Kapitel 2, weeks_ago: 6, unknown_before: 55, unknown_after: 9}
Datum says: "Kapitel 2. Vor 6 Wochen: 55 Prozent unbekannt. Heute: 9."

=== A fact the engine did NOT measure → Datum stays silent ===
facts without unknown_after: {chapter: Kapitel 2, weeks_ago: 6, unknown_before: 55}
Datum says: (nothing — not faked)

=== Datum disabled → silent, but the numbers stay legible ===
Datum says: (nothing)
the measurement itself, without Datum: DAMALS 55% → JETZT 9%

=== Phase 9 gate ===
registry live:                              true
real measurement voiced:                    true
missing fact → no line:                     true
disabled → silent (info still legible):     true
no template emits with a missing fact:      true
GATE: PASS
```

Datum voices a **real** measured delta (55% → 9% unknown, from an
actual two-reading measurement of the 羅生門 text) — the numbers in the
sentence are the numbers the engine measured, not decoration. Drop the
`unknown_after` fact and Datum goes silent rather than inventing a
value. Disable Datum and it's silent entirely, while the same
measurement (55% → 9%) stays fully legible without it — §0.24's
"disabling Datum removes personality, never information," demonstrated.

### "App fully functional with Datum disabled" — as a widget test

`datum_line_test.dart` shows a screen with a real measurement (`Unbekannt:
8%`) and a Datum line above it, then flips Datum off: the measurement is
still there, the Datum line is gone (`ValueKey('datum-line')` findsNothing),
nothing else moves.

## Gate verdict

**PASS.** The template registry is live and locale-tabled; an automated
test proves — over every template, generically and regression-proof —
that no line can render a fact the engine didn't measure; and the app
is fully functional with Datum disabled, with the underlying
measurements legible without it. Datum can only ever report what was
truly measured. Proceed to Phase 10.

---
*Softbrew Studio — Phase 9 proof report — 2026-08-03.*
