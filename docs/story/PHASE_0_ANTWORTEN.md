# Phase 0 — Antworten auf das Interview-Gate (§0)

**Bezug:** `BRIEF_STORY_ENGINE.md` §0, im Dialog mit dem Auftraggeber geklärt am 2026-08-28.
**Status:** P0 schriftlich abgenommen. Datenmodell (§2 des Briefs) wird unverändert
übernommen, siehe Ergänzung unten.

---

## Vorbemerkung: Verhältnis zur bisherigen Café-Arbeit

Vor diesem Brief war an anderer Stelle ein Konzept „Hajimemashite" (Café als eigenes
Setting, Herbst, Figuren Ken/Yui) sowie ein Architektur-Entwurf „Ansatz 1" (Übungs-Beats
eingewoben in den Lesefluss, Freund-Figur als Quiz-Host, Multiple Choice als Einstieg)
erarbeitet worden. **Beides wird nicht weiterverfolgt** — weder die Geschichte noch die
Beat-in-Lesefluss-Übungsphilosophie.

Die Idee, zwei Stränge zu führen, wurde aufgegriffen, aber anders gelöst als „zwei
parallele Geschichten": Der Brief führt „Café" als **Wiederholungs-Modus innerhalb
derselben Shotengai-Welt** wieder ein (§4) — ein Laden in derselben Straße, kein
zweites Setting, kein eigener Erzählbogen. Er ersetzt den nackten SRS-Feed, führt aber
laut INV-8 explizit **keine neuen Items** ein; die Story bleibt der einzige Ort, an dem
gelernt wird. Damit ist die ursprüngliche „zwei Stränge"-Idee sinngemäß erhalten
(Story + Café als zwei Tätigkeiten), aber nicht als zwei konkurrierende Geschichten.

---

## 1. Panel-Assets

**Antwort: einzelne Bilddatei pro Panel**, kein Seiten-Sheet mit Panel-Koordinaten.

Begründung: Das Datenmodell des Briefs sieht `Panel.asset: AssetRef` vor — ein Asset
pro Panel. Wichtiger noch: die Ankerachsen-Strategie aus `VISUAL_STYLE.md` (7 Achsen
× 4 Zeitvarianten = 28 Basis-Renders, über viele Panels und Folgen hinweg
wiederverwendet) setzt zwingend voraus, dass ein Panel-Bild unabhängig adressierbar
und wiederverwendbar ist. Ein Seiten-Sheet würde diese Wiederverwendung verhindern
und Ken-Burns/Zoom pro Panel unnötig verkomplizieren.

## 2. Hit-Areas für Sprechblasen

**Antwort: im Manifest hinterlegt**, nicht zur Laufzeit erkannt.

Begründung: Entspricht dem bestehenden Muster im Code (`Bubble.rect`, normierte
Koordinaten, autoriert). Das Briefs-Datenmodell erweitert das zu `hitArea: Polygon`
— diese Erweiterung wird übernommen (deckt nicht-rechteckige Sprechblasenformen ab),
bleibt aber weiterhin manifest-autoriert. Laufzeit-Erkennung (z. B. Bildanalyse)
wäre für KI-generierte Panels unnötig fragil.

## 3. Audio

**Antwort: Laufzeit-TTS**, keine vorgeschnittenen Audiodateien. Einzelwort-Wiedergabe
= TTS direkt auf das einzelne Token, nicht Zerschneiden eines Blasen-Clips.

Begründung: `tts_service.dart` existiert bereits und funktioniert offline — eine
zusätzliche Audio-Produktions-Pipeline (Sprecheraufnahmen oder vorgeschnittene
Dateien für hunderte Panels und alle Café-Turns) wäre ein eigenes, unnötiges
Großprojekt parallel zur Bild-Produktion. `Bubble.audioRef` bleibt im Modell als
austauschbare Referenz bestehen (Interface, nicht Festlegung), falls später echte
Sprecheraufnahmen nachgerüstet werden sollen.

## 4. Wörterbuch-Suche

**Antwort: kein Fallback-Suchfeld.** Reines Kana-Blättern (§3.2 des Briefs), aber
**der Wörterbuch-Bestand pro Folge/Serie skaliert mit dem bereits Gelernten** —
nicht von Tag 1 ein vollständiges JA-Wörterbuch in Gojūon-Reihenfolge (bei 3
bekannten Kana in Folge 01 unmöglich zu bedienen). Eine sichtbare Gojūon-Tafel
dient als Navigationshilfe und lehrt dabei nebenbei die Silbenordnung — wie im
Brief selbst als Effekt des Blätterns beschrieben (§3.2).

## 5. Navigation

**Antwort: Panel-für-Panel-Tap**, kein vertikales Scrollen.

Begründung: vom Brief selbst nahegelegt („Bestimmt, ob P24 als Schlussbild wirkt
oder als Zeile im Scroll untergeht"). Panel-für-Panel bewahrt die Dramaturgie der
Pilotfolge (sechs stumme Eröffnungspanels, ein bewusst gesetztes Schlussbild).

## 6. Fortschritts-Persistenz

**Antwort: pro Panel persistiert**, nicht nur pro Folge.

Begründung: Bei Panel-für-Panel-Navigation (siehe Punkt 5) wäre ein Neustart ab
Panel 1 bei jedem Wiedereinstieg eine unnötige UX-Zumutung; technisch nur ein
zusätzlicher Index, kein nennenswerter Mehraufwand.

## 7. Café: Gast-Bestand fix pro Sitzung?

**Antwort: fix**, wie im Brief selbst empfohlen. Der Belegungsstand (§4.3) wird beim
Betreten des Cafés einmalig aus dem SM-2-Fälligkeitsstand berechnet und bleibt für
die Dauer der Sitzung stabil. Erst der nächste Café-Besuch berechnet neu.

Begründung: Gäste, die mitten im Besuch auftauchen oder verschwinden, sobald ein
Item fällig wird, zerstören die ruhige, diegetische Illusion und lassen den Ort wie
einen Spielautomaten wirken — genau die Wirkung, die der Brief explizit vermeiden
will (§4.3, „das ist die diegetische Fassung von 'nichts zu tun'").

## 8. Café: Wie werden Dialoge autorisiert?

**Antwort: Hybrid mit klarer Grenze.**

- `prompt` (was der Gast in einem Turn sagt) ist **template-basiert**, mit
  Slot-Einsatz des jeweiligen SM-2-Items. Das muss mit der Item-Zahl mitwachsen
  (perspektivisch Hunderte), handgeschrieben pro Item skaliert das nicht.
- `followUp` (Reaktion auf richtig/falsch/Ausweichen, §4.5) ist **vollständig
  handgeschrieben, aber pro Gast, nicht pro Item** — itemlos formuliert, universell
  wiederverwendbar über den gesamten Wortschatz hinweg.

Begründung: Die Reaktion trägt die Persönlichkeit und Komik des Gasts (Beispiel
Schulkind, §4.2), nicht der Prompt. Handschreib-Aufwand bleibt damit auf die vier
Gästefiguren begrenzt (überschaubar), während der Template-Anteil beliebig mit dem
Wortschatz mitwächst, ohne dass sich das Gespräch wie eine Karteikarte anfühlt.

---

## Ergänzung zum Datenmodell (§2 des Briefs)

Das im Brief beschriebene Datenmodell (`Episode → Page → Panel → Bubble → Token`,
plus `Interaction`, plus `CafeTurn` aus §4.5) wird unverändert als Zielstruktur
übernommen. Es ersetzt das bisherige, flachere `ComicPack → ComicPage → Bubble`-Schema
im Code (`lib/features/comic/comic_pack.dart`), das keine Panel-Ebene, keine
Sprecher-Zuordnung und keine Interaktions-Metadaten kennt. Die Migration dieses
Schemas ist Gegenstand von Phase P1 (Content-Schema + Validator) und wird dort
geplant, nicht hier vorweggenommen.

Bestehende, wiederverwendbare Bausteine aus dem Code (Five-Rung Retrieval Ladder,
SM-2 SRS, `ScriptProfile`-Abstraktion, `tts_service.dart`, `stt_service.dart`)
bleiben wie vom Brief vorausgesetzt bestehen. Der nackte SRS-Feed/Review-Screen wird
laut §4 vollständig vom Café ersetzt — das betrifft `review_screen.dart` und ist
ebenfalls Gegenstand der Content-/Implementierungsplanung ab P1, nicht dieses
Dokuments.
