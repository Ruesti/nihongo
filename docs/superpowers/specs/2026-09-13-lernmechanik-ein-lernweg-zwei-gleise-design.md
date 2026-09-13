# Design: Ein Lernweg, zwei Gleise — die Lernmechanik als Ganzes

**Datum:** 2026-09-13
**Status:** Entwurf — wartet auf Ulis Review
**Anlass:** Grundsatz-Brainstorming über die Lernmechanik. Nordstern (von Uli bestätigt):
*Zwei Gleise dauerhaft — ein strukturierter Weg (Grammatik, Systematik) läuft neben dem
Lesen, aber der Lerner erlebt EINE gemeinsame Fälligkeit, nicht zwei Systeme. Die
Verschmelzung passiert unter der Haube.*

**Getroffene Annahme:** Bei der Wahl des Grundgerüsts (Ansatz A/B/C, siehe §2) hat Uli
keine Präferenz geäußert. Dieses Dokument arbeitet die Empfehlung **Ansatz A
(Arbeitsteilung)** aus. Die Alternativen und ihre Nachteile sind in §2 festgehalten,
damit die Entscheidung revidierbar bleibt.

---

## 1. Ausgangslage: die Doppelwelt

Die App besteht heute aus zwei übereinandergelegten Lernwelten:

- **On-Ramp** (der geführte Weg): Lektionen mit der 5-Sprossen-Leiter
  (begegnen → erkennen → lesen → produzieren → schreiben), Wiederholung per **SM-2**
  (der klassische Karteikarten-Algorithmus), Daten in der `LearningDb`.
  Seit PR #41 ist das **Café** die Oberfläche für diese Wiederholungen: vier Gäste
  verkörpern die Sprossen, Belegung = Fälligkeit, keine Zahlen, keine Streaks (INV-10).
- **Immersion-Mining** (das Lesen): echte Texte, sortiert nach **i+1**
  (genau ein unbekanntes Wort pro Satz = idealer Lernstoff), fällige Wörter erscheinen
  **beim Lesen inline** unter dem Text. Wiederholung per **FSRS** (der modernere
  Nachfolger von SM-2), Daten in der `MiningDb`.

Verbunden sind die Welten durch die **Knowledge-Bridge**: Was im On-Ramp gemeistert
wurde, gilt beim Lesen als „bekannt" — aber nur Vokabeln; Kanji und Grammatik ignoriert
die Brücke bewusst.

**Das Problem:** Für den Lerner sind das zwei Wiederholungssysteme mit verschiedener
Zeitplanung und verschiedenem Fehlerverhalten, verkauft als ein Weg. Das Café benotet
SM-2-Items, der Reader FSRS-Items. Dazu läuft der Legacy-Home (Tamago-Maskottchen,
Mastery-Bar) noch, obwohl `RECONCILIATION.md` ihn zum Verwerfen erklärt und er der
Anti-Gamification-Linie (I3/INV-10) direkt widerspricht.

## 2. Die drei Ansätze und die Entscheidung

**A — Arbeitsteilung (gewählt).** Jedes Gleis macht dauerhaft, was nur es kann.
Strukturgleis = System-Wissen (Kana, Kanji-Systematik, Schreiben, Grammatik) plus ein
*endlicher* Grundwortschatz-Anschub. Vokabelquelle danach: nur noch das Lesen.
Unter der Haube ein einziger Scheduler (FSRS) und ein gemeinsamer Item-Raum.

**B — Vorkurs pro Werk (verworfen, später als Aufsatz möglich).** Das Strukturgleis
bereitet dynamisch das nächste Lesestück vor. Maximale Relevanz, aber: das Gleis
verliert seine eigene Systematik (Grammatik-Progression springt je nach Werk), braucht
Generierung pro Werk — und die Bibliothek hat aktuell genau ein Werk. B lässt sich
später als optionales Feature auf A draufsetzen („Vorkurs zum nächsten Kapitel").

**C — Nur Fassade (verworfen).** Beide Scheduler behalten, ein gemischter Due-Feed
darüber. Schnell, aber die Doppelwelt bleibt real bestehen (verschiedene Intervalle,
verschiedenes Fehlerverhalten) — das widerspricht dem Nordstern „Verschmelzung unter
der Haube" und lässt die technische Schuld wachsen.

## 3. Zielbild: die zwei Gleise

### Gleis 1 — Struktur (der geführte Weg)

Dauerhafte Aufgabe: **System-Wissen**, also das, was aus reinem Lesen schlecht lernbar ist.

- **Kana:** bleibt wie heute (Leiter mit Lesen/Schreiben/Nachzeichnen).
- **Kanji-Systematik:** Komponenten/Radikale und Schreiben. Das Schema
  (`Characters`, `CharComponents`) existiert bereits.
- **Grammatik:** `GrammarPoints` werden erstklassige Lern-Items mit eigener Fälligkeit
  (heute existieren sie nur als Inhalte ohne Scheduling-Anschluss an die Brücke).
  Vermittlung in kleinen Lektionen auf dem Gleis, Abruf im Café (§5).
- **Grundwortschatz-Anschub (endlich):** Die kuratierten Häufigkeits-Vokabeln
  (heute `vocab_800`) bleiben als Rampe, damit i+1 beim Lesen überhaupt Sätze findet.
  Die Rampe **endet** beim festen Umfang N (aktuell 800); danach stellt das Gleis keine
  neuen Vokabel-Lektionen mehr — neue Wörter kommen nur noch aus dem Lesen.
  Bewusst konservativ: ein automatisches Abschaltkriterium („Mining trägt, wenn der
  i+1-Ideal-Pool ≥ X Sätze liefert") wäre eleganter, ist aber schwerer zu treffen;
  fester Umfang zuerst, Automatik später falls nötig.
  **Die Rampe läuft parallel zum Lesen, nicht davor** — sie ist die Eintrittskarte
  für „wilde" Texte (§ Gleis 2), nicht für den Manga. Es gibt keinen Punkt, an dem
  die Schule „fertig sein muss", bevor gelesen werden darf.

### Gleis 2 — Lesen (Mining)

Bleibt mechanisch wie gebaut: i+1-Lesereihenfolge, Wörterbuch-Tap, In-Reading-Review
(fällige Items erscheinen im sichtbaren Text-Abschnitt), Passage-Snapshots als ehrliche
Messung.

**Prinzip: Lesen ab Tag 1 — der Manga wartet auf niemanden** (Uli-Anforderung, Review
2026-09-13). Das Lesegleis hat zwei Stoffsorten mit verschiedenen Eintrittsbedingungen:

- **Kuratierte Manga-Folgen (Story-Engine):** für Lerner geschrieben, setzen null
  Vorwissen voraus — Folge 01 führt ihre Wörter selbst ein (Antippen, Audio,
  diegetisches Sprechen/Nachzeichnen, Einführung bei Lese-Ende; INV-5). Sie sind der
  Anfänger-Einstieg des Lesegleises, verfügbar **ab dem ersten Tag**. Der
  Grundwortschatz-Anschub (§ Gleis 1) ist ausdrücklich KEINE Voraussetzung dafür.
- **„Wilde" Texte** (nicht für Lerner geschrieben: Rashōmon-Slice, künftige Importe):
  brauchen einen Wortschatz-Grundstock, damit i+1 überhaupt lesbare Sätze findet.
  Sie schalten sich über das i+1-Fenster von selbst frei, sobald der Wortschatz trägt.

Die Verdrahtung der Story-Engine in die App (Arbeitspaket W3) wird hier nicht neu
entworfen — aber sie ist von der Scheduler-Fusion **unabhängig** und soll nicht hinter
ihr warten (§9).

## 4. Verschmelzung unter der Haube

### 4.1 Ein Scheduler: SM-2 → FSRS

Alle On-Ramp-Items (`LearnItems`) erhalten FSRS-Karten im gemeinsamen Fälligkeitsraum.

- **Migration:** Für gemeistertes Wissen wird eine plausible FSRS-Historie simuliert —
  das Werkzeug existiert bereits (`simulateWellKnownCard` in
  `fsrs_bootstrap_import.dart`, heute für den Brücken-Backfill genutzt). Für Items in
  Arbeit wird aus `masteryRung` + bisherigem Intervall ein FSRS-Startzustand abgeleitet;
  das `ReviewLog` bleibt als historische Wahrheit unangetastet.
- **Die Leiter bleibt.** Wichtige Trennung, die heute schon als Invariante I2 angelegt
  ist (Sprosse ≠ Scheduling): Die Sprosse bestimmt **WIE** ein Item geübt wird
  (erkennen vs. tippen vs. schreiben vs. frei produzieren), FSRS bestimmt **WANN** es
  fällig ist. Promotion/Demotion auf der Leiter funktioniert unverändert; nur die
  Terminberechnung wechselt den Algorithmus.
- **Einmaliger Ruck akzeptiert:** Nach der Migration fühlen sich Intervalle anders an
  (Items kommen früher oder später als gewohnt). Datum und Re-Presentation messen
  ehrlich weiter; kein Kaschieren.

### 4.2 Ein Item-Raum

- **Ein Lemma = ein Item**, egal ob es über eine Lektion oder beim Lesen in den Kopf
  kam. Die Dubletten-Abwehr existiert im Kern schon (Brücke mappt Lexem → VocabItem);
  neu ist, dass auch das *Scheduling* zusammenfällt, nicht nur das „bekannt"-Flag.
- Der Kontext-Satz einer Karte darf wechseln („Card ≠ Satz", bereits Mining-Prinzip) —
  ein Lektions-Wort, das später im Lesen auftaucht, bekommt echten Text als Kontext.
- **Formabgleich-Audit:** Der stille Fehlerpunkt der Brücke (`Lexemes.writtenForm` muss
  dem Tokenizer-Lemma gleichen, sonst gilt Bekanntes als unbekannt) wird bei der Fusion
  einmalig über den ganzen Bestand geprüft, nicht nur pro Item gehofft.

### 4.3 Brücke erweitert: Kanji + Grammatik

Heute bricht die Brücke bei allem ab, was kein Lexem ist. Künftig:

- **Grammatik-Items** und **Kanji-Items** leben als eigene Item-Typen im gemeinsamen
  Fälligkeitsraum (gleiche FSRS-Mechanik, eigene Übungsformen).
- **Ausbaustufe (nicht Kern dieses Designs):** Grammatik-Bekanntheit fließt in die
  i+1-Bewertung ein — ein Satz mit unbekannter Struktur ist schwerer, als seine
  Vokabel-Abdeckung aussagt. Erst sinnvoll, wenn Grammatik-Items existieren und Daten
  liefern.

## 5. Eine erlebte Fälligkeit

- **Das Café ist das einzige Zuhause fälliger Items** — aus beiden Gleisen. Die vier
  Gäste bleiben; ihre Zuordnung folgt wie bisher der Übungsform (Sprosse). Neu kommt
  dazu: Grammatik-Items landen beim passenden Gast (Schulkind fragt Formen ab,
  Vielredner prüft Verständnis im Monolog, Gleichaltrige lassen frei produzieren);
  Kanji-Schreib-Items beim Nachzeichnen-Repertoire der Wirtin/des Schulkinds.
- **Lesen räumt ab:** Wer liest, bedient fällige Items inline (heute schon gebaut als
  `dueInView`); nach der Fusion gilt das automatisch auch für Ex-On-Ramp-Wörter. Das
  Café ist danach entsprechend leerer. Ein Item, ein Termin, egal wo bedient.
- **Café-Invarianten bleiben unangetastet:** INV-8 (führt nichts Neues ein), INV-9
  (kein un-eingeführtes Item an der Oberfläche), INV-10 (kein Level/Währung/Streak).
  Die Fusion vergrößert nur die Item-Quelle, nicht den Charakter des Cafés.

## 6. Aufräumen (Konsequenz aus RECONCILIATION.md)

- **Legacy-Home fliegt raus**, ersetzt durch den Empfang: qualitative Signale statt
  Zahlen („im Café sitzt jemand", „dein nächstes Kapitel wartet", Then/Now) —
  im Geist von INV-10.
- **Spiele-Tab:** wird entfernt. Einzelne Übungsformen daraus (z.B. Trace) leben als
  Übungsformen der Leiter weiter, nicht als eigenes Gamification-Areal. (Falls Uli im
  Review widerspricht, ist das die einzige Stelle, die davon abhängt.)
- **Kaiwa-Tab:** bleibt vorerst unangetastet — er ist der natürliche Anschlusspunkt für
  das separate Thema „Produktion & Fehler" (§8) und wird dort entschieden.

## 7. Was dieses Design bewusst NICHT behandelt

Eigene, spätere Brainstormings (hier nur als Anschlussstellen notiert):

1. **Content-Nachschub:** Import-UI (EPUB/Untertitel/OCR — Adapter existieren ohne
   Oberfläche), abgestufte Bibliothek. Die größte praktische Lücke, aber orthogonal
   zur Loop-Struktur.
2. **Produktion & Fehler:** Der Kernloop ist rezeptionslastig; die Invariante I7
   („Fehler erzeugt Item") ist unerfüllt. Kaiwa/STT als Produktionskanal.
3. **Story-Engine-Verdrahtung (W3):** läuft als eigenes Wiring-Arbeitspaket —
   wegen „Lesen ab Tag 1" (§3) aber mit hoher Priorität: unabhängig von der Fusion,
   kann vor oder parallel zu §9 laufen.

## 8. Risiken

| Risiko | Umgang |
|---|---|
| FSRS-Migration verschiebt gewohnte Intervalle | Einmaliger Ruck, akzeptiert; Datum/Re-Presentation messen ehrlich weiter |
| Formabgleich `writtenForm` ↔ Lemma schlägt still fehl | Einmaliges Bestand-Audit bei der Fusion (§4.2) |
| Grundwortschatz-Ende zu früh (i+1 findet nichts) oder zu spät (Doppelarbeit) | Fester Umfang N=800 zuerst; Automatik nur bei Bedarf nachrüsten |
| Grammatik-Items ohne bewährte Übungsformen | Bestehende Übungstypen (sentence_build, verb_conjugate) wiederverwenden, nichts Neues erfinden |

## 9. Grobe Reihenfolge (für den Implementierungsplan, nicht Teil dieses Designs)

1. **Scheduler-Fusion** SM-2 → FSRS, Leiter bleibt entkoppelt — rein unter der Haube,
   keine sichtbare Änderung.
2. **Café auf den gemeinsamen Pool** umstellen (Item-Quelle wird der fusionierte
   Fälligkeitsraum statt `LearningDb.getDueItems`).
3. **Brücke erweitern:** Kanji- und Grammatik-Items in den Pool.
4. **Empfang ersetzt Legacy-Home**; Spiele-Entscheidung.
5. **Grundwortschatz-Auslauf** (Rampe endet bei N).

Jeder Schritt ist einzeln shipbar und lässt die App jederzeit lauffähig.

**Außerhalb dieser Sequenz, aber nicht dahinter:** Die Manga-Verdrahtung (W3) hängt an
keinem dieser Schritte und soll parallel laufen — sie ist der schnellste Weg, das
Prinzip „Lesen ab Tag 1" (§3) in der echten App erlebbar zu machen.
