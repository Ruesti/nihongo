# CLAUDE.md — Softbrew Sprachlern-App

> **SUPERSEDED (2026-07-20):** Dieses Dokument und `PHASES.md` beschreiben die alte Tamago-chan/Lektionen-Architektur. Sie wird durch `SPEC_MINING_PIPELINE.md` (Datum / Immersion-Mining-App) vollständig ersetzt, siehe deren Status-Zeile. Nur noch als historische Referenz relevant.

*(Arbeitstitel: TBD · Implementierungs-Brief für Claude Code)*

Mehrsprachige Sprachlern-App, **local-first**, mit dauerhaftem Lernen über eine Abruf-Leiter + SM-2, generischer Schrift-Unterstützung, produktiven Schrift-Spielen und KI-Gesprächspartner. Pädagogische Quelle der Wahrheit: **Methode-Spec v0.2** (`Lernmethode_Asset-System_v0.2.md`). Diese Datei übersetzt sie in Architektur und Code-Regeln.

---

## 1. Tech-Stack & Grundhaltung

- **Flutter** (UI), **Riverpod** (State), **Drift/SQLite** = Source of Truth.
- **Supabase** optional (Sync) · **RevenueCat** (IAP, Einmalkauf pro Sprache) · **Anthropic API via BYOK** für KI-Features.
- **Offline-first:** Die App muss ohne Netz *vollständig* funktionieren. Sync und KI sind optionale Layer, nie Voraussetzung.
- **Harte Trennung:** sprach-agnostischer **Core** (Logik) vs. daten­getriebene **Language Packs** (Inhalt). Kein sprach-spezifischer Code im Core.

---

## 2. Nicht verhandelbare Invarianten

Diese Regeln sind der Existenzgrund des Projekts. Bei Konflikt schlagen sie Bequemlichkeit und „Engagement".

- **I1 — Recall, kein Recognition.** Produktions-Sprossen (3–5) zeigen die Antwort **nie** unter Auswahloptionen. Keine Multiple-Choice auf Produktion.
- **I2 — Timing ≠ Schwierigkeit.** `srsState` (SM-2: *wann*) und `masteryRung` (*wie schwer*) sind getrennte Felder. Nie vermischen.
- **I3 — Keine Gamification.** Kein Streak, keine Punkte, keine Leaderboards. Fortschritt = Mastery + Retention + Can-do.
- **I4 — Assets an `conceptId`.** Ein Bild gehört zum Konzept, nie zu Wort oder Sprache. Eine Bibliothek bedient alle Packs.
- **I5 — Spiele an Schrift-Eigenschaften.** Spiel-Verfügbarkeit wird aus `ScriptProfile`-Flags berechnet, nicht aus der Sprache. Kein sprach-spezifischer Spielcode.
- **I6 — Stabiler Abrufreiz.** Pro `conceptId` *ein* festes Bild. Keine Neugenerierung pro Review.
- **I7 — Fehler erzeugt Item.** Jeder Fehler im KI-Gespräch legt ein gezieltes `LearnItem` an bzw. stuft es zurück.
- **I8 — Core ist sprachblind.** Der Core kennt keine konkrete Sprache; alles Sprachspezifische kommt aus dem Pack.

---

## 3. Datenmodell (Drift)

Felder kompakt als `name: typ`. Als Drift-Tabellenklassen umsetzen; IDs als `TEXT`/UUID.

**Sprach-neutral (geteilt über alle Packs):**
```
concepts        : id, glossKey, partOfSpeech, defaultAssetType
assets          : id, conceptId→concepts, type{image|clip|icon|none}, path
```

**Pro Sprache (Language Pack):**
```
languages       : id, name, scriptProfileId→script_profiles, ttsVoice, enabled
script_profiles : id,
                  scriptType{alphabet|syllabary|logographic|abugida|abjad|hangul},
                  direction{ltr|rtl},
                  decomposability{atomic|radicals|jamo|consonantMatra|baseDiacritics},
                  positionalForms: bool,
                  toneSystem{none|tonal|pitchAccent|vowelPoints},
                  needsScriptTrack: bool,
                  transliteration{none|romaji|pinyin|...},
                  inputMethods: list{keyboard|ime|handwriting}
lexemes         : id, languageId, conceptId→concepts, writtenForm, reading, audioPath, cefrBand
characters      : id, languageId, glyph, readings, meaning, strokeOrderAssetId, mnemonicId
char_components : id, characterId→characters, componentGlyph, position
grammar_points  : id, languageId, cefrBand, sequenceIndex, canDoId→can_do_goals
sentences       : id, languageId, cefrBand, text, knownCoverage   # Graded Input
can_do_goals    : id, languageId, cefrBand, description
```

**Lernzustand (lokal, polymorph über die drei trainierbaren Typen):**
```
learn_items : id, languageId,
              refType{lexeme|character|grammar}, refId,
              masteryRung: int(1..5),
              ease: double, intervalDays: int, dueAt: datetime, reps: int, lapses: int
review_log  : id, learnItemId→learn_items, rung, result{again|hard|good|easy}, ts
```

`learn_items` ist die **einzige** SRS-Einheit. Jeder der drei `refType` läuft dieselbe 5-Sprossen-Leiter.

---

## 4. Modulstruktur

```
lib/
  core/
    db/            # Drift schema + DAOs
    srs/           # SM-2: schedule(when)  — entkoppelt von rung
    ladder/        # rung-defs + exerciseTypeResolver(rung, refType, scriptProfile)
    games/         # script games + gameAvailability(scriptProfile)
    conversation/  # KI-Partner (BYOK) + onError→learnItem
    assets/        # conceptId→asset; Produktions-Sprossen fordern asset=null (Anti-Krücke, I1/I6)
    progress/      # mastery map, retention, can-do  (KEIN streak/score, I3)
    sync/          # optional Supabase
  packs/           # rein datengetrieben, KEINE Logik
    ja/ es/ ko/ ar/ ...
  features/        # UI (review, games, reader, conversation, progress, travel)
  app/
```

`ScriptProfile` ist ein typisiertes Modell, das der Core konsumiert. Packs liefern nur Daten + Profil.

---

## 5. Kern-Algorithmen

- **`srs.schedule(item, result)`** → aktualisiert `ease/intervalDays/dueAt` (SM-2). Kennt `masteryRung` *nicht* (I2).
- **`ladder.resolveExercise(rung, refType, scriptProfile)`** → konkreter Übungstyp. Rung 3–5 ⇒ Produktion, niemals Optionsauswahl (I1).
- **Promotion/Demotion:** N aufeinanderfolgende `good`/`easy` auf einer Sprosse ⇒ rung+1. `again` ⇒ rung−1 *und* Intervall-Reset.
- **`games.available(scriptProfile)`** → Spielset (siehe Tabelle §6 der Spec). Reine Funktion der Profil-Flags (I5).
- **`conversation.onError(span)`** → erzeugt/raised `learn_item` auf passender Sprosse (I7).
- **`assets.resolve(lexeme, rung)`** → bei Produktions-Sprossen `null` zurückgeben (Anti-Krücke), sonst `conceptId`-Asset (I4/I6).

**Spiel→Sprosse→Flag (aus der Spec):**
```
mnemonicMatch  rung1   if decomposability != atomic
readingBlitz   rung2   always (bei alphabet niedrig priorisiert)
componentBuild rung3   if decomposability != atomic   (alphabet ⇒ wordBuild)
writeTrace     rung4   always
compoundBuild  rung5   logographic⇒Komposita, sonst wordBuild
positionalForm rung3-4 if positionalForms              (Arabisch)
toneVowelMatch  —      if toneSystem in {tonal, vowelPoints}
```
Alle Spiele ziehen ihre Items aus der **SRS-Queue** (Zwischendurch-Spielen = echte verteilte Praxis).

---

## 6. Asset-Pipeline

Die App hängt **nur am Manifest + gebündelten Dateien**, nie an ComfyUI. Die Generierung ist ein **externer, späterer** Offline-Schritt (manuell, ComfyUI) — *nicht* Teil dessen, was Claude Code baut. Bis Assets existieren, läuft alles mit Platzhaltern.

**Manifest = Quelle der Wahrheit** (versioniert im Repo, erzeugt die `assets`-Tabelle):
```
assets_manifest.csv
conceptId, glossKey, assetType{image|clip|icon|none}, prompt, status{todo|generated}
```
- Namenskonvention: Datei = `assets/{conceptId}.{ext}` → wird zu `assets.path`.
- Import-Skript macht die `assets`-Tabelle zur **deterministischen, idempotenten** Funktion des Manifests.
- Alles hängt an `conceptId` → einmal generieren, alle Sprach-Packs nutzen dasselbe Asset (I4).

**Was pro `assetType` entsteht:**
- Nomen → ein Standbild (`image`)
- Verb → kurzer Loop/Sequenz, nur wo Bewegung *die Bedeutung ist*; minimal (`clip`)
- Adjektiv → Standbild, oft kontrastives Paar (`image`)
- Abstrakt/Grammatik → Icon oder `none`
- Funktionswort → `none`

**Generieren-Disziplin (I6):** append-only. Neue Konzepte → nur `status=todo` rendern. Regenerieren nur bewusst (ändert den stabilen Abrufreiz) → **versionieren statt überschreiben**.

**App-Konsumregeln (das baut Claude Code):**
- `assets.resolve(lexeme, rung)` → Produktions-Sprossen liefern `null` (Anti-Krücke, I1); sonst das `conceptId`-Asset.
- Fehlendes oder `todo`-Asset → neutraler Platzhalter, **nie Crash**. App ist ohne fertige Assets voll nutzbar.
- Assets gebündelt/offline; kein Netzabruf pro Review.

**Außerhalb der ComfyUI-Bildpipeline (andere Quellen, separat):**
- Strichfolge-Animationen → sprachspezifisch, datengetrieben (Stroke-Order-Vektoren/Font), `strokeOrderAssetId`. Keine Bildgenerierung.
- Audio → TTS pro Sprache (`audioPath`).
- UI-Belebung → Lottie/CSS im Flutter-Code, kein Asset.
- Mascot (Tamago-chan) → eigene Konsistenz (Character-LoRA/IPAdapter), getrennte Manifest-Gruppe.

> ComfyUI selbst (Modelle, Nodes, Stil-Anker) = **später**, separat von diesem Brief.

---

## 7. Build-Reihenfolge

- **Phase 0** — Drift-Schema + `ScriptProfile`-Modell + minimaler JA-Seed-Pack.
- **Phase 1** — SM-2-Engine + Leiter Sprossen 1–3 (Text, getippt). Kein Spiel, keine KI. *Den Loop beweisen.*
- **Phase 2** — Schrift-Parallelleiter + Handschrift (Sprosse 4) für ein Skript.
- **Phase 3** — Schrift-Spiele (§5), Flag-gesteuert, über SRS-Queue.
- **Phase 4** — Input-Schicht (Graded Texts) + KI-Gespräch (BYOK) + Fehler→Item.
- **Phase 5** — Zweiter/dritter Pack je anderer Schriftfamilie (z. B. ES = alphabet, KO = hangul, AR = abjad/RTL) → Abstraktion validieren.
- **Phase 6** — Asset-Generierung gegen das Manifest (§6; ComfyUI extern, *später*) + RevenueCat (Einmalkauf/Sprache) + optional Supabase-Sync. Bis dahin Platzhalter.
- **Phase 7** — Fortschritts-UI (Mastery/Can-do, kein Streak) + Reise-Quicklearn.

---

## 8. Anti-Patterns (nicht tun)

- Multiple-Choice auf Produktions-Sprossen (verletzt I1).
- Streaks / Punkte / Leaderboards (I3).
- Sprach-spezifischer Spiel- oder Schrift-Code im Core (I5/I8).
- Asset an Sprache oder Wort koppeln (I4).
- KI als Pflicht — App muss offline voll funktionieren.
