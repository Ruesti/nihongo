# Design: Der geführte Weg — Lektion ↔ Manga (neue Kernstruktur)

*Status: Entscheidungsvorlage. Datum: 2026-08-20.*
*Vereint die beiden vorherigen Specs (Empfang + Manga-Lesen) zu einem Erlebnis.*
*Nächster Schritt nach Freigabe: Implementierungsplan (writing-plans).*

## Vision

> Eine **Sprachlern-Plattform, mit der es Spaß macht** eine Sprache zu lernen —
> **und die effektiv ist**. **Keine Gamification** wie Duolingo (Streaks, Punkte,
> Ligen). Aber auch **kein Anki-Abfragen** (trockenes Karteikarten-Pauken).
> Sondern ein **Mix aus Lektionen** *und* **Erfahren durch Manga/
> Bildergeschichte** — ein *geführter Weg*, der dich abholt und durch die
> Sprache trägt, mit Schrift + Vokabular + Grammatik **verwoben** (nicht die
> „Schriftzeichen-Keule" am Anfang), gewürzt von einer Geschichte, die mit dir
> mitwächst.

## Problem (was heute nicht stimmt)

Die App öffnet auf einem **Lektions-Raster** (Kachel-Menü), das der Nutzer
ablehnt: es fühlt sich wie ein Menü an, nicht wie Lernen; es startet mit der
Kana-Keule; und selbst nach dem neuen Onboarding *mündet* der Weg wieder genau
in dieses Raster. Wiederholung liegt als Anki-artige Abfrage-Warteschlange
(Review-Tab) vor — genau das trockene Pauken, das der Nutzer *nicht* will. Die
Manga-Lese-Funktion existiert als *getrennter* Tab, statt Teil des Lernens zu
sein.

## Nicht verhandelbare Invarianten

Übernommen aus `CLAUDE.md`, plus eine neue:

- **I1 — Recall, kein Recognition** auf Produktions-Sprossen.
- **I2 — Timing ≠ Schwierigkeit** (SRS-Zeitplan vs. `masteryRung` getrennt).
- **I3 — Keine Gamification** (kein Streak, Punkte, Ligen, Leaderboards).
- **Ehrlichkeit** — nie fälschlich „gewusst" behaupten.
- **Offline-first**, **System-Sprache** (l10n), **I8 sprach-blinder Core**.
- **NEU — Kein Drill als Front-Erlebnis.** Wiederholung ist kein
  Karteikarten-Stapel, den man abarbeitet. Sie geschieht **im Lesen**: gelernte
  Wörter begegnen dir wieder in der Geschichte (i+1), fällige Items tauchen im
  Kontext auf. Der zeitliche SRS-Rhythmus läuft im Hintergrund; das *Erlebnis*
  ist Lesen, nicht Abfragen.

## Die zwei Säulen & der Rhythmus

Die App *ist* ein **geführter Weg** aus abwechselnden Schritten:

**Säule 1 — Lektion (fokussiertes Lernen).**
Ein kleines, *verwobenes* Häppchen neuer Bausteine: ein paar **Zeichen** + ein
paar **Wörter** + evtl. ein **Grammatik**-Baustein — *zusammen*, wie die
Geschichte sie gleich braucht. Nie „erst alle Kana". Eingeführt über das
bestehende **Begegnungs-Ritual** (Sprosse 0): sehen · hören · nachfahren
(Zeichen) / Bedeutung + Konzeptbild + Beispiel (Wort) / Muster + Kann-Ziel
(Grammatik).

**Säule 2 — Erfahren durch Manga (anwenden statt abfragen).**
Direkt danach ein **Abschnitt der mitwachsenden Bildergeschichte**, der *genau
das* benutzt, was du gerade gelernt hast — plus ein bisschen Neues (i+1). Du
liest, tippst Wörter an, *erlebst* die Sprache in einer Szene. Die Blasen
kippen über den Weg von „viel L1 (deine Sprache) + paar L2-Wörter" zu „immer
mehr L2". **Das ersetzt das Anki-Abfragen**: Die Wörter kehren lebendig im
Kontext zurück.

**Der Rhythmus ist die App:** Lektion → Manga → Lektion → Manga … Der Weg ist
die **Startseite**. Kein Raster, keine Punkte, keine Abfrage-Warteschlange
vorn.

## Struktur & Datenmodell

- Ein **Curriculum** = *autorierte, geordnete* Folge von **Schritten**. Ein
  Schritt ist entweder eine **Lektion** (Bündel aus 0–n Zeichen/Wörter/
  Grammatik) oder ein **Manga-Abschnitt** (eine `ComicPage`/Installment). In der
  Regel gruppiert ein **Kapitel** *ein Lektions-Bündel + seinen Manga-Abschnitt*.
- **Eine durchgehende, mitwachsende Geschichte**, erzählt über die Kapitel
  (nicht viele lose Kurzgeschichten).
- **Autorierter Faden** (die Reihenfolge ist *geführt*). **i+1 justiert nur die
  Manga-Schwierigkeit** gegen den realen Bekannt-Stand (welche Wörter zählen als
  bekannt), nicht die Kapitel-Reihenfolge.
- **Fortschritts-Zustand:** auf welchem Schritt der Lernende steht
  (`curriculum_progress`: stepIndex je languageCode). Pro-Item-Meisterung bleibt
  in der Leiter (`LearnItems`) — im Hintergrund für die Terminierung.
- **Sprach-agnostisch (I8):** das Curriculum ist Pack-Daten
  (`packs/<lang>/curriculum.json`), der Core kennt nur „Schritt {lesson|manga}".

Neues, minimales Modell (Pack-Daten, kein sprach-spezifischer Core-Code):
```
Curriculum        : languageCode, title, steps: [CurriculumStep]
CurriculumStep    : id, kind {lesson|manga}, chapterRef,
                    lesson?  : { characterIds[], lexemeIds[], grammarIds[] }
                    manga?   : { comicPageRef }   // → ComicPack/ComicPage
```

## Wiederverwendung des bereits Gebauten

Fast alles existiert schon (Empfang + Manga sind gemergt) — dieser Spec
*verdrahtet* es neu:

- **Begegnungs-Ritual (rung 0) + `EncounterView`** → die Einführungen im
  Lektions-Schritt (polymorph Zeichen/Wort/Grammatik).
- **SRS-Leiter + `LearnItem` + `LadderReview`** → Hintergrund-Terminierung; die
  Fälligkeit *surft im Lesen* (`InReadingReviewPanel`/`DueInReading`), nicht als
  Tab.
- **`ComicPack`/`SpatialReader`/`ComicRepository`/`rankByIPlusOne`** → die
  Manga-Abschnitte (Bild + tippbare L2-Wörter + Snapshot).
- **`KnowledgeBridge`/`MiningDb`-Substanz** → geteilter Bekannt-Stand; das
  Onboarding-Vorwissen speist ihn.
- **Onboarding** → führt in den Weg (statt ins Raster); der **Vokabel-Mini-Check**
  (bisher zurückgestellt) wird gebaut.

## Was mit der bestehenden Struktur passiert

- **Raster-Home** → ersetzt durch den **geführten Weg** (neuer `/`-Screen:
  „weiter auf dem Weg" = nächster Schritt; darunter eine ruhige Kapitel-/
  Fortschrittsanzeige, *kein* Kachel-Menü, *keine* Punkte).
- **„Lesen"-Tab** → verschmilzt in den Weg (Manga-Schritte). Die „bring dein
  eigenes Manga"-OCR-Seitentür bleibt optional erreichbar.
- **Review-Tab** → **herabgestuft**: Wiederholung passiert im Lesen; eine
  optionale „Extra-Übung"-Seitentür bleibt für Willige (nicht Front).
- **Fortschritt** + **Einstellungen** → bleiben. **Gespräch (Kaiwa)** + **Spiele**
  → optionale Seitentüren.
- **Legacy Tamago-chan-Story-Lektionen / alte `AppDatabase`-Lektionen** → aus
  dem Front-Erlebnis genommen; ihre Kana-/Vokabel-Inhalte fließen als
  Curriculum-Schritte ein. (Vollständige Entfernung der toten `AppDatabase` ist
  optionaler Aufräum-Folgeschritt.)

## Onboarding-Anschluss

- Nach dem Onboarding → **erster Schritt des Weges** (erstes Lektions-Bündel →
  erster Manga-Abschnitt), *nie* das Raster.
- **Vorwissen wird abgeholt:** der **60-Sekunden-Vokabel-Mini-Check** wird gebaut
  (eine Handvoll häufiger Wörter, „Kennst du das?", selbst benotet). Bestätigte
  Wörter → über den ehrlichen FSRS-Bootstrap als *known* markiert. Der Weg
  überspringt Lektions-Schritte, deren Inhalt bereits bekannt ist, und die
  Story-Schwierigkeit (i+1) startet entsprechend weiter vorn. Kana-Ja/Nein bleibt
  wie gehabt.

## Content

- Maschinerie + Struktur werden gegen einen **kleinen, autorierten ersten
  Bogen** gebaut: 2–3 Kapitel (je ein Lektions-Bündel + passender Manga-Abschnitt
  mit **Platzhalter-Art**), die den Loop Ende-zu-Ende beweisen.
- **Volles Curriculum + echte ComfyUI-Manga-Art** = laufender, separater
  Content-Strang danach — dieselbe Disziplin wie bisher (Platzhalter, bis echte
  Assets existieren; App hängt nie zur Laufzeit an ComfyUI).
- Ehrlichkeit zum Spaß-Ziel: dieser Spec liefert das **Vehikel**. Ob es wirklich
  Spaß macht, hängt an gutem Story-/Lektions-*Content* — das ist die
  Autorier-Arbeit, die die Struktur erst ermöglicht.

## Grenzfälle & Fehlerfälle

- **Kein Content für den nächsten Schritt** → ruhiger „Mehr kommt bald"-Zustand +
  Rückfall auf Wiederholung-im-Lesen des bereits Freigeschalteten; nie Absturz.
- **Fehlende Manga-Art** → Platzhalter-Panels (bestehende Degradation).
- **Viel-Vorwissen-Nutzer** → Weg springt zum ersten *unbekannten* Schritt vor;
  bekannte Lektions-Bündel werden übersprungen (nichts wird neu „gelehrt").
- **Nutzer ohne jedes Vorwissen** → startet bei Schritt 0 (Kana kommt im Fluss,
  verwoben mit ersten Wörtern — nicht als isolierter Kana-Block).

## Teststrategie (in der Beweis-Report-Disziplin)

- **Unit:** Curriculum-Sequenzierung (nächster Schritt gegeben Fortschritt +
  Bekannt-Stand, überspringt Bekanntes); i+1-Justierung der Manga-Schwierigkeit;
  Vorwissen-Anschluss (bestätigte Wörter → Start weiter vorn).
- **Widget:** der Weg-Home rendert den geführten Rhythmus (kein Raster, keine
  Punkte); ein Schritt öffnet das Lektions-Bündel (Begegnung) und danach den
  Manga-Abschnitt; „weiter" rückt vor.
- **Beweis (`tool/`):** ein Lernender geht den ersten Bogen (Lektion → Manga →
  nächstes Kapitel) Ende-zu-Ende — sprach-agnostisch (JA + ein zweites Pack).

## Scope / Nicht-Ziele

**Drin:** der geführte-Weg-Spine (Curriculum-Modell + Sequenzierung + Fortschritt),
integrierte Lektions-Schritte (Zeichen+Wort+Grammatik via Begegnung),
Manga-Abschnitts-Schritte (ComicPack-Wiederverwendung), Weg-Home ersetzt Raster,
Onboarding→Weg, Vokabel-Mini-Check, Review-Tab herabgestuft/„Extra-Übung",
Lesen-Tab-Verschmelzung, kleiner erster Bogen mit Platzhalter-Content, Tests.

**Draußen (später / eigener Strang):** volles Curriculum-Autoring, echte
ComfyUI-Manga-Art, Kaiwa-/Spiele-Ausbau, vollständige Entfernung der toten
`AppDatabase`, Cloud-Sync/Monetarisierung.

## Getroffene Detail-Entscheidungen (Defaults — beim Gegenlesen überstimmbar)

- **Eine durchgehende, mitwachsende Geschichte** in Kapiteln (nicht viele lose).
- **Autorierter Curriculum-Faden**; i+1 justiert nur die Manga-Schwierigkeit.
- **Der Weg wird die Startseite**; Review-Tab herabgestuft zur optionalen
  „Extra-Übung"; Gespräch/Spiele optionale Seitentüren; Fortschritt/Einstellungen
  bleiben.
- **MVP gegen 2–3 Kapitel Platzhalter-Content**.

## Verhältnis zu den bisherigen Specs

Ersetzt *nicht* die Bausteine der Specs vom 2026-08-17 (Empfang, Manga-Lesen) —
die bleiben und werden **wiederverwendet**. Dieser Spec ändert die
**Kernstruktur/Navigation**: aus „Onboarding → Raster + getrennte Tabs" wird
„Onboarding → geführter Weg (Lektion ↔ Manga)". Reibt sich bewusst mit dem alten
Raster-Home und dem Review-Tab als Front — genau die ersetzt er.
