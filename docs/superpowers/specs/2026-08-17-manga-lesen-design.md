# Design: Manga-Lesen — das mitwachsende Comic

*Status: Entwurf. Datum: 2026-08-17. Baut auf dem Empfang-Spec auf.*
*Nächster Schritt nach Freigabe: Implementierungsplan (writing-plans).*

## DIE zentrale Entscheidung (bitte zuerst gegenlesen)

**Woher kommen die Manga?** Ich habe entschieden — mit Begründung, damit wir
ohne weitere Abstimmungsrunde schreiben können. Wenn du anders willst, ist das
*der* Punkt zum Ändern.

**Gewählt: selbst-generiertes Comic über die Manifest-/Asset-Pipeline, zuerst
gegen Platzhalter-Art gebaut.** Mit dem **„mitwachsenden Comic"** (Deutsch →
immer mehr Japanisch) und einem **i+1-Selektor** über eine gestufte
Panel-Bibliothek.

Warum:
- Es ist der **einzige** Weg, der *designte* Steigerung (leicht → schwer),
  „immer mehr Japanisch" **und** legales Bündeln zugleich liefert.
- Es passt exakt zur bestehenden **Asset-Doktrin (§6)**: die App hängt nur am
  Manifest + gebündelten Dateien; ComfyUI-Generierung ist ein *externer,
  späterer* Schritt. Wir bauen und beweisen den kompletten Leser + Selektor
  **erst gegen Platzhalter-Art** — genau wie das Projekt bisher alles mit
  synthetisch-aber-legitimen Inhalten bewiesen hat.

Verworfene/abgegrenzte Alternativen (dokumentiert):
- **Kuratierte echte Manga** — Urheberrecht (nicht bündelbar) *und* nicht
  gestuft. Der vorhandene OCR-Pfad („bring dein eigenes Manga mit") bleibt als
  **Seitentür** für Fortgeschrittene erhalten, ist aber **nicht** Teil der
  gestuften Progression.
- **Illustrierte Graded Readers** (gezeichnete Strips statt voller Manga) —
  leichterer Rückfall, falls die Comic-Generierung ins Stocken gerät; dieselbe
  Reader-/Selektor-Architektur trägt sie ohne Änderung.

## Problem

Der Lesen-Tab wirft heute eine **Kanji-Wand** hin: ein reiner Text-Auszug aus
羅生門 (Rashōmon), einem schweren Literaturtext, mit nur Tipp-zum-Nachschlagen.
Keine Bilder, kein Comic, keine Anpassung ans Niveau. Manga existiert nur als
**Backend-OCR**, das ein Manga-Bild in Text verwandelt und **das Bild wegwirft**
— es wird nie ein Comic angezeigt. Die gestufte Inhaltsbibliothek und der
Selektor sind laut `DESIGN_ONRAMP_BRIDGE.md` ausdrücklich noch nicht gebaut.

Ziel: ein **echtes Comic** mit Bildern, das **leicht anfängt und mit dem
Lernfortschritt schwerer wird** — und in dem **immer mehr Japanisch** steht.

## Randbedingungen

- **i+1.** Inhalte knapp über dem Stand; die Pipeline misst `unknownRatio` schon
  pro Passage (`passage_snapshot.dart`). Ziel-Fenster ~5–15 % unbekannt.
- **Offline-first, Asset-Doktrin §6.** App hängt nur an Manifest + gebündelten
  Panel-Bildern, nie an ComfyUI zur Laufzeit. Fehlende Art → Platzhalter, nie
  Absturz.
- **Geteilte Wissens-Substanz.** Der Bekannt-Stand kommt aus `MiningDb`,
  gespeist vom **Empfang-Spec** (Platzierung + Begegnungen). Dieser Spec *liest*
  ihn, um das Niveau zu kennen.
- **Reader ist die Review-Oberfläche** (bestehende §7-Entscheidung): Tippen →
  Gloss, fällige Karte im Lesen bewertet, Then/Now-Beweis via Datum.
- **UI-Sprache = Systemsprache** (für Monetarisierung). Die **L1-Seite** des
  mitwachsenden Comics ist die **aktive UI-/Systemsprache**, nicht fix Deutsch.
  Setzt das l10n-Fundament aus dem Empfang-Spec voraus.
- **Zielsprachen-agnostisch (I8).** Der Manga-Stil muss für *jede* Zielsprache
  funktionieren, nicht nur Japanisch. Leser, Selektor und Rampe sind über
  `languageCode` + `ScriptProfile` parametrisiert — kein `'ja'`-Hartcode. Die
  **L2-Seite ist die aktive Zielsprache** (Pack). Lesehilfe generisch (Furigana/
  Pinyin/Romaji je `ScriptProfile.transliteration`); **Leserichtung** (LTR/RTL,
  z. B. Arabisch) folgt `ScriptProfile.direction`. Die gestufte Comic-Bibliothek
  liegt **pro Pack**.

## Die Vision konkret

- Ein Comic = Folge von **Seiten**; jede Seite = **Panels** (Bild) mit
  **Sprechblasen**, die Text-Spans tragen.
- **Gestufte Schwierigkeit:** jeder Comic/jede Seite hat ein Ziel-i+1-Fenster;
  der Text nutzt überwiegend bekannten Wortschatz + wenige neue (geminte) Wörter.
- **Mitwachsendes Comic (Immersions-Rampe):** Sprechblasen mischen die
  Lernersprache (L1 = die aktive UI-/Systemsprache) und die **Zielsprache (L2 =
  das aktive Pack**, z. B. Japanisch, Koreanisch, Spanisch). Früh: überwiegend
  L1 mit ein paar bekannten L2-Wörtern. Mit steigendem Niveau kippt das
  Verhältnis, bis die Blasen ganz L2 sind. Der **L2-Anteil** `l2Ratio(level)`
  steigt 0 → 1 über die Stufen. Der L1-Blasentext wird pro Locale vorgehalten
  (ARB-/Content-seitig), nie fix Deutsch.
- **Lesen = Üben:** Tippen auf ein L2-Wort → Gloss-Sheet (bestehender
  `WordTapHandler`); fällige Karten im Lesen bewertet (bestehendes
  `InReadingReviewPanel`); `passage_snapshot` misst den Unbekannt-Anteil →
  Datums „Damals→Jetzt"-Beweis (existiert schon).

## Architektur — auf dem vereinheitlichten Text-Track

Wir wiederverwenden den bestehenden Track (`Works`/`Sources`/`TextSpans`) und
den Anker `SpatialAnchor` (pageId + rect), den `MangaSourceAdapter` schon
erzeugt. Das **Neue** ist die *Anzeige* des Bildes (heute weggeworfen) plus
Auswahl und Rampe:

1. **Bild behalten statt wegwerfen.** `MangaSourceAdapter`
   (`lib/core/sources/manga_source_adapter.dart`) speichert künftig den
   Panel-Bildpfad je `pageId` (heute verworfen). Für generierte Comics kommt das
   Bild direkt aus dem Manifest.
2. **Räumlicher Leser** — neues `features/reader/spatial_reader.dart`: rendert
   das Seiten-/Panel-Bild und legt tippbare Spans/Sprechblasen an ihren `rect`s
   darüber. Wort-Tipp → derselbe `WordTapHandler` → Gloss. Fällige Karte am
   Ort → dasselbe `InReadingReviewPanel`. **Sprach-blind:** die Lesehilfe über
   dem L2-Wort ist generisch (Furigana/Pinyin/Romaji je
   `ScriptProfile.transliteration`), und die **Leserichtung** folgt
   `ScriptProfile.direction` (LTR/RTL). Lesereihenfolge wird für generierte
   Comics **explizit autoriert** (kein RTL-Rätselraten wie bei fremden Manga).
3. **Gestufte Bibliothek** — Comics getaggt mit `level`, gemessenem
   `unknownRatio` (gegen eine Referenz-Bekannt-Menge) und `japaneseRatio`.
   Struktur + Manifest wie `assets_manifest.csv`; Platzhalter-Panels bis
   ComfyUI-Art landet.
4. **i+1-Selektor** — neues `lib/core/pipeline/content_selector.dart`: liest den
   Bekannt-Stand (`MiningDb`) → wählt den nächsten Comic, dessen `unknownRatio`
   im i+1-Fenster liegt. Das ist die „wird schwerer mit Fortschritt"-Maschine.
5. **L1/L2-Spans** — `TextSpans` bekommen einen `lang`-Marker: **L1** (Deutsch,
   Prosa) rendert *nicht* tippbar und wird *nicht* gemint; **L2** (Japanisch) ist
   tippbar/minebar. So trägt ein und dieselbe Span-Struktur die Immersions-Rampe.

## Content-Generierung (extern/später, §6)

- **Art** (figuren-konsistente Panels) ist der größte Brocken → ComfyUI +
  Character-LoRA/IPAdapter, *extern/später*, genau wie das Maskottchen
  (CLAUDE.md §6 erwähnt es). Die App hängt nie zur Laufzeit an ComfyUI.
- **Skript/Text** je Comic (Story-Beats) + Blasentext auf Ziel-Niveau
  (`japaneseRatio` + i+1-Wortwahl). Autoriert oder LLM-gestützt (BYOK). Die
  App-konsumierbare Ausgabe sind **Spans + rects + Bildpfade** im Manifest.
- **MVP:** kompletter Leser + Selektor + Rampe gegen **Platzhalter-Panels**
  (neutrale Rahmen/Low-fi) mit *echten* Span-Daten — Schleife Ende-zu-Ende
  beweisen, bevor in Art investiert wird.

## Datenmodell-Erweiterungen

- Wiederverwenden: `Works`/`Sources`/`TextSpans`/`SpatialAnchor`.
- Panel-Bild: `pages` mit `imagePath` je `pageId` (bzw. Manifest-Eintrag).
- Comic-Metadaten: `level`, `targetUnknownRatio`, `l2Ratio`, `coverImage`,
  `languageCode` (welches Pack).
- `TextSpans.lang` (L1|L2) — steuert Tippbarkeit + Mining. L2-Text ist fix
  (Japanisch); **L1-Text ist locale-abhängig** (Content pro Locale bzw.
  ARB-Key), damit dieselbe Seite in der Systemsprache erscheint.

## Grenzfälle

- **Noch keine Art** → Platzhalter-Panel (neutraler Rahmen) mit Blasen; Schleife
  funktioniert.
- **Bibliothekslücke** (kein Comic trifft das i+1-Fenster) → nächstgelegenen
  wählen; Datum sagt es ehrlich, erfindet keinen Fortschritt.
- **Seitentür OCR („eigenes Manga")** → Bild wird jetzt *angezeigt* (nicht mehr
  verworfen); nicht gestuft, nicht Teil der Progression; RTL-Reihenfolge bleibt
  die bekannte offene Näherung im Adapter.
- **L1-Prosa** wird nie gemint und ist nicht tippbar (nur L2).

## Teststrategie (Beweis-Report-Disziplin)

- **Widget:** `spatial_reader` rendert ein Panel-Bild + tippbare Spans an
  `rect`s; Tipp → Gloss; fällige Karte am Ort bewertet. L1-Span nicht tippbar,
  L2-Span tippbar.
- **Unit:** Selektor wählt für eine Bekannt-Menge einen Comic im i+1-Fenster und
  rückt vor, wenn die Bekannt-Menge wächst. Rampe: höheres `level` → höherer
  `japaneseRatio` im gelieferten Blasentext.
- **Beweis (`tool/`):** Bekannt-Stand → Selektor → Seite rendert mit
  Platzhalter-Art + echten Spans → Tipp→Lookup funktioniert → `passage_snapshot`
  liefert Then/Now. Mining: nur L2-Spans erzeugen i+1-Kandidaten.

## Scope / Nicht-Ziele

**Drin:** räumlicher Leser (Bild + Overlay), gestufte Bibliotheks-Struktur +
Manifest, i+1-Selektor, Immersions-Rampe + L1/L2-Spans, Bild-behalten im
`MangaSourceAdapter`, Platzhalter-Art-MVP, Tests.

**Draußen (extern/später):** die eigentliche ComfyUI-Art-Pipeline +
Character-LoRA (§6, extern) · Autorieren eines großen Comic-Katalogs (Content) ·
volle RTL-Unterstützung für beliebige fremde Manga · Monetarisierung.

**Abhängigkeit:** der **Empfang-Spec** (liefert den Bekannt-Stand, den der
Selektor braucht). Ohne ihn kennt der Manga-Leser das Niveau nicht.
