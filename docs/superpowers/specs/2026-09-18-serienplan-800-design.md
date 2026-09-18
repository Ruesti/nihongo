# Serienplan 800 — Die Geschichte trägt den Grundwortschatz

*Design-Spec, 2026-09-18. Status: Entwurf zur Abnahme durch Uli.*

Bezugsdokumente: `docs/story/BRIEF_STORY_ENGINE.md` (Invarianten INV-1 bis INV-10), `docs/story/DREHBUCH_FOLGE_01_V2.md` (Format-Regeln, Serien-Curriculum), `docs/superpowers/specs/2026-09-15-cafe-nachbesprechung-design.md` (Nachbesprechung, INV-11, Schritte 3 bis 5), `docs/superpowers/specs/2026-09-13-lernmechanik-ein-lernweg-zwei-gleise-design.md` (zwei Gleise, Grundwortschatz N = 800). Diese Spec baut auf ihnen auf und ändert sie nur dort, wo §10 es sagt.

Der Staffelplan für Staffel 1 steht in `docs/story/STAFFEL_1_DIE_ADRESSE.md`.

---

## 0. Was entschieden ist

Uli hat am 18.9.2026 vier Fragen entschieden, alle in Richtung der Empfehlung:

1. **Wortvorrat:** Ein fester Vorrat aus dem N5-Grundwortschatz plus dem Alltag im Shotengai. Die Geschichte wählt daraus, sie erfindet ihren Wortschatz nicht frei.
2. **Rätsel:** Der Zettel wird bis zum Ende ganz gelesen. Das Schweigen der Großmutter bekommt eine Antwort. Eine Randnotiz im Wörterbuch bleibt für immer offen.
3. **Kana:** Die Kana laufen über die vorhandenen Lektionen. Die Geschichte zeigt nur die Kana, die gerade wehtun.
4. **Dichte:** Mehr Text pro Folge kommt aus dichteren Dialog-Panels mit drei bis vier Blasen, nicht aus mehr Panels.

Außerdem gilt der gewählte Weg: **Serienplan zuerst.** Erst Wortvorrat und Kanji, dann ein Plan, der jeder Folge ihre Wörter zuteilt, dann werden die Folgen gegen den Plan geschrieben und geprüft.

---

## 1. Ziel und Nicht-Ziele

**Ziel.** Wer alle Folgen liest und die Nachbesprechungen im Café mitmacht, ist den 800 Wörtern des Grundwortschatzes und den dazugehörigen Kanji begegnet, hat sie wiederholt und in den Karteikasten übernommen. Die Wiederholung passiert an zwei Stellen: in der Geschichte selbst, weil Wörter planmäßig wiederkehren, und im Café, das die Fälligkeit verwaltet.

**Warum die Geschichte und nicht ein Anschub-Kurs.** Das Lernmechanik-Design sah einen endlichen Grundwortschatz-Anschub im Strukturgleis vor. Uli will die Wörter aus der Geschichte, nicht aus Listen. Das Drehbuch zu Folge 01 hat das Format dafür bereits gesetzt: 15 bis 20 neue Wörter und 2 bis 4 Zeichen pro Folge. Diese Spec macht daraus einen Plan, der die 800 garantiert.

**Nicht-Ziele.**
- Kein zweiter Karteikasten, keine Vokabelliste neben dem Wörterbuch. Der Bestand des Wörterbuchs bleibt der Bestand des Karteikastens.
- Kein Fortschrittsbalken „412 von 800". Der Abdeckungsbericht ist ein Autorenwerkzeug, keine Anzeige in der App.
- Keine Änderung an den Café-Regeln. Das Café führt nichts Neues ein und hat keinen eigenen Erzählbogen.
- Keine Kana-Lektionen in der Geschichte. Siehe §4.
- Grammatik bekommt hier nur ihren Platz pro Folge. Wie Grammatik-Karten aussehen, regelt Schritt 4 der Café-Spec.

---

## 2. Der Wortvorrat

**Was er ist.** Eine Liste von genau 800 Wörtern, die vor dem Schreiben von Folge 02 steht. Sie ist die Quelle der Wahrheit dafür, was „die ersten 800" sind. Jede Folge zieht ihre neuen Wörter aus dieser Liste. Am Ende von Staffel 3 ist die Liste aufgebraucht.

**Woher die Wörter kommen.**
- Grundstock: der übliche Wortschatz der JLPT-Stufe N5, rund 650 bis 700 Wörter. Es gibt keine amtliche Liste, wir stellen sie selbst zusammen und prüfen jedes Wort gegen JMdict, das im Repo schon liegt.
- Ergänzung: der Alltag des Shotengai 1996, rund 100 bis 150 Wörter, die die Geschichte braucht und die in Anfängerlisten fehlen: Rollladen, Schirm, Telefonkarte, Werkstatt, Nadel und Faden, Schlüssel, Speisekarte.
- Bestand: die 148 japanischen Einträge aus `lib/data/vocab_800.dart` und die 23 Pack-Wörter aus `lib/packs/ja/ja_seed.dart` werden übernommen, wo sie passen. Die 18 Wörter aus Folge 01 sind gesetzt.
- Häufigkeit als Kontrolle: Der vorhandene Tatoeba-Häufigkeits-Import dient als Plausibilitätsprüfung, nicht als Auswahlregel.

**Eine Reservebank.** Zusätzlich zu den 800 gibt es bis zu 40 Ersatzwörter. Wenn eine Folge ein Pflichtwort beim besten Willen nicht unterbringt, darf es gegen ein Bankwort getauscht werden. Der Tausch wird im Plan vermerkt, die Summe bleibt 800.

**Was ein Eintrag weiß.**

| Feld | Bedeutung |
|---|---|
| `id` | wie bisher, z. B. `lex_ja_kagi` |
| `written` | die Schreibung mit Kanji, z. B. 鍵; leer, wenn das Wort in Kana bleibt |
| `kana` | die Lesung, z. B. かぎ |
| `meaningDe` | die deutsche Bedeutung, ein bis drei Wörter |
| `pos` | Wortart |
| `kanji` | die Kanji in `written`, in Reihenfolge |
| `domain` | Lebensbereich: Café, Werkstatt, Bahnhof, Zeit, Wetter, Familie, Körper, Gefühl, Zahlen, Fragen, Verben Alltag, Adjektive, 1996 |
| `plannedEpisode` | die Folge, die das Wort einführt |
| `status` | geplant, geschrieben, ausgeliefert |

**Ablageort.** Dart-Konstanten unter `lib/features/story/plan/vocab_pool_ja.dart`. Gleiche Bauart wie die Folgen-Manifeste, damit Tests ohne Asset-Laden darauf zugreifen. Deutsche Bedeutungen fließen beim Ausliefern einer Folge in `conceptGlossDe`, die Lexeme in den Pack-Seed, genau wie bei Folge 01.

---

## 3. Die Kanji folgen den Wörtern

**Regel 1: Kein Kanji ohne Trägerwort und Ort.** Ein Kanji wird nur in einer Folge eingeführt, in der ein Wort des Vorrats es trägt und in der es einen sichtbaren Ort hat: ein Schild, ein Preis, eine Tafel, der Zettel, eine Randnotiz. Das Trägerwort kommt in derselben Folge vor. Es darf schon früher eingeführt worden sein, denn die Schrift wächst mit, siehe §8. Zettel-Kanji, also die Zeichen der drei Zeilen, haben den Zettel als Ort und brauchen kein Trägerwort, weil die Handlung sie trägt; 田 in Tanaka ist so ein Fall. Das ist die bisherige Praxis aus Folge 01 (駅 am Bahnsteig, 傘 am Laden), jetzt als Regel.

**Welche Kanji.** Der Kanji-Vorrat wird aus dem Wortvorrat abgeleitet: alle Kanji, die in den Schreibungen der 800 Wörter vorkommen. Sortiert wird nach Nutzen, also danach, wie viele Wörter des Vorrats ein Kanji aufschließt, bei Gleichstand nach Strichzahl. Die üblichen N5-Kanji, etwa 100, sind die Kontrolle: Was in der Ableitung fehlt, aber in N5 steht, bekommt ein Trägerwort in den Vorrat. Was in der Ableitung steht, aber nicht in N5, bleibt drin, wenn es einen Ort in der Geschichte hat, wie 傘.

**Wie viele.** 2 bis 3 Kanji pro Folge, in Ausnahmen 4. Über 45 Folgen ergibt das rund 100 bis 120. Zahlen und Wochentage sind Gruppen und werden über zwei bis drei Folgen verteilt, damit die Regel hält.

**Zwei Arten von Ort.**
- Zettel-Kanji: die Zeichen der drei Zeilen. Sie sind das Rätsel. Jedes entzifferte Zeichen ist ein gelerntes Kanji.
- Schild-Kanji: alles andere hängt im Shotengai. Preise, Speisekarte, Bahnhofstafel, Kalender, Telefonzelle, Ladenschilder, Türen mit Drücken und Ziehen.

**Nachzeichnen bleibt in der Geschichte.** Jede Folge hat einen Nachzeichnen-Moment, der zur Handlung gehört. Miras Ort dafür ist das Wörterbuch: Sie schreibt ihre Zeichen an den Rand, neben die fremde Handschrift. Dazu kommen Gelegenheiten, die die Welt anbietet: beschlagene Scheibe, Handrücken, Quittung. Der Nachzeichnen-Moment führt das Zeichen auf Sprosse 1, wie bisher.

**Im Café.** Die Wirtin zeigt in der Nachbesprechung die Strichfolge und lässt nachfahren. Das ist Schritt 3 der Café-Spec und wird ab Folge 02 gebraucht.

INV-7 bleibt unverändert: Kanji, deren Bedeutung nicht freigeschaltet ist, sind Bildtextur. Ein Tipp tut nichts.

---

## 4. Kana bleiben bei den Lektionen

Die 92 Grund-Kana passen nicht nebenbei in 45 Folgen. Sie laufen weiter über die Kana-Lektionen des geführten Wegs, parallel zur Serie. Die Geschichte setzt beim Lesen keine Kana-Kenntnis voraus: Die deutschen Erzählkästen tragen die Handlung, ein Tipp auf die Blase gibt Ton und Kana. Wer schon Kana kann, liest mit. Wer nicht, hört.

Die Geschichte zeigt Kana nur, wenn sie gerade wehtun: das め auf dem Zettel, das め am Caféschild. Solche Momente sind Zeichen im Budget der Folge, wie in Folge 01, und zählen gegen die 2 bis 4.

---

## 5. Drei Staffeln, drei Zeilen

Die Endkarte von Folge 01 sagt: Auf dem Zettel standen einmal drei Zeilen. Jede Staffel entziffert eine.

| Staffel | Folgen | Zeile | Frage der Staffel | Antwort am Ende |
|---|---|---|---|---|
| 1 „Die Adresse" | 01 bis 15 | 南町三ノ二 田中 | Wo ist das, und wer ist Tanaka? | Der geschlossene Buchladen war der Laden ihrer Großmutter. Der Schirmmann kannte sie. |
| 2 „Der Name" | 16 bis 30 | はるへ | Wer ist Haru, und wo ist sie? | Haru ist die jüngere Schwester der Großmutter. Sie lebt in der Nachbarstadt und will von Yuki nichts hören. |
| 3 „Der Satz" | 31 bis 45 | ごめんね。もう一度、会いたい。ゆき | Was steht da, und will Haru es hören? | Mira liest den Satz selbst, ohne Wörterbuch, laut, im Café, im Regen. Haru antwortet: わたしも。 |

**Die Antwort auf das Schweigen.** Yuki Tanaka verließ 1961 den Shotengai, um einen deutschen Ingenieur zu heiraten. Ihr Vater, der Buchhändler, verbot es und brach mit ihr. Ihre Briefe kamen zurück. Haru, die jüngere Schwester, wuchs mit der Version auf, Yuki habe die Familie vergessen. Yuki in Deutschland hielt es umgekehrt: Wer die Sprache nicht spricht, kann kein Heimweh haben. Darum kein Wort Japanisch zuhause, darum der Zettel erst am Ende. Der Schirmmann Yamada war Yukis Freund aus Kindertagen. Er gab Mira in Folge 01 den Schirm, weil sie Yukis Gesicht hat. Das erfährt der Leser erst im Finale von Staffel 1.

**Was offen bleibt.** Das Wörterbuch gehört nicht Mira. Seine Randnotizen stammen von jemandem, der nie auftritt. Eine Notiz, nahe beim Wort 会う, bleibt bis zum Schluss ohne Erklärung. Regel aus dem Brief: höchstens eine Randnotiz pro drei Folgen, nie auflösbar.

**Regeln für die Figuren.**
- Träger des Rätsels sind Mira, der Schirmmann Yamada, der Rollladen des Buchladens, das Telefon nach Deutschland, die Gemüsefrau, das Foto, später Haru. Nur sie bewegen die Handlung.
- Die vier Café-Gäste dürfen in der Geschichte auftreten, aber nur in ihrer Rolle: Die Wirtin benennt und erklärt, das Schulkind fragt ab und korrigiert, der Vielredner redet, die Gleichaltrige plaudert. Sie tragen kein Geheimnis und keinen eigenen Bogen. Das hält den Brief ein.
- Yamada spricht wenig. Seine ersten ganzen Sätze sind Ereignisse.

**Der Motor jeder Folge.** Eine Frage, eine Antwort, eine neue Frage als Cliffhanger. Dazu das Muster aus Folge 01: Mira tut etwas, was sie nicht sagen kann. Ihr Fehler ist rührend, nie peinlich. Der Ton bleibt der des Briefs: Alltag statt Postkarte, warm trotz Melancholie.

---

## 6. Die Folge als Bauteil

Jede Folge hält dieselben Maße. Der Serien-Prüfer aus §9 misst sie nach.

| Maß | Wert |
|---|---|
| Panels | 10 bis 12 |
| Blasen auf Dialog-Panels | 3 bis 4 |
| Neue Wörter | 15 bis 20, aus dem Vorrat |
| Neue Kanji | 2 bis 3, in Ausnahmen 4, jedes mit Trägerwort und Ort |
| Grammatik | genau ein Punkt ab Folge 02 |
| Sprechmoment | mindestens einer, diegetisch |
| Nachzeichnen-Moment | genau einer, diegetisch |
| Zettel- oder Wörterbuch-Beat | höchstens einer; Randnotiz höchstens alle drei Folgen |
| Wort-Vorkommen in Blasen | ab Folge 04 mindestens 120 |
| Jedes neue Wort | mindestens zweimal in verschiedenem Zusammenhang, INV-4 |

**Warum 120.** Folge 01 hat 57 Vorkommen und 18 neue Wörter, also fast nur Neues. Das darf die erste Folge. Ab Folge 04 sollen auf jedes neue Wort zwei wiederkehrende kommen, siehe §7. Dann braucht eine Folge rund 54 verschiedene Wörter und, weil neue Wörter mehrfach vorkommen, rund 120 Vorkommen. Bei 11 Panels sind das elf Vorkommen pro Panel, das entspricht drei Blasen zu drei bis vier Wörtern. Deshalb dichte Dialog-Panels statt mehr Panels.

**Hochlauf.** Folge 02 kann nur die 18 Wörter aus Folge 01 wiederholen, Folge 03 die 36 aus 01 und 02. Für Folge 02 und 03 gilt darum nur: mindestens 80 Vorkommen, und alles, was schon eingeführt ist, kommt vor.

**Was unverändert bleibt.** Das Manifest-Schema mit Budget, Seiten, Panels, Blasen, Tokens, Interaktionen und Nachbesprechung. Die Übergabe ans Café am Folgen-Ende. Der Tipp auf die Blase gibt nie die Bedeutung, INV-2. Das Wörterbuch bleibt der einzige Weg zur Bedeutung.

---

## 7. Wiedersehen: Wiederholen in der Geschichte

Das Café verwaltet die Fälligkeit. Die Geschichte soll trotzdem selbst wiederholen, sonst bleibt jede Folge eine Insel. Dafür gibt es zwei Regeln, die der Plan einhält und der Prüfer misst.

**Wiedersehen-Regel.** Jedes Wort kehrt in einer der drei Folgen nach seiner Einführung zurück und noch einmal innerhalb von zehn Folgen. Danach ist es frei. Wörter, die in Staffel 1 tragende Rollen haben, wie あめ, かさ, みせ, かぎ, kommen ohnehin ständig.

**Wiedersehen-Quote.** Ab Folge 04 kommen auf jedes neue Wort mindestens zwei wiederkehrende, gezählt nach verschiedenen Wörtern. 18 neue Wörter brauchen also 36 alte.

**Anderer Mund, anderer Ort.** Ein Wort soll nicht nur wiederkommen, sondern wandern. Was die Wirtin eingeführt hat, sagt später das Schulkind. Was am Bahnhofsschild stand, steht dann auf einer Quittung. Das ist eine Autorenregel, keine Prüfregel.

**Was das Café davon hat.** Wer eine Folge liest, räumt fällige Wörter beim Lesen inline ab, wie im Lernmechanik-Design vorgesehen. Die Wiedersehen-Regel sorgt dafür, dass es dafür regelmäßig Gelegenheit gibt. Das Café bleibt das einzige Zuhause der Fälligkeit, INV-8 bis INV-10 und INV-11 bleiben.

---

## 8. Schrift wächst mit

Ein Wort steht so geschrieben, wie Mira es lesen kann.

| Stufe | Wann | Wie |
|---|---|---|
| Kana | solange nicht alle Kanji des Worts eingeführt sind | えき |
| Kanji mit Lesehilfe | die drei Folgen nach der Einführung des letzten Kanji | 駅 mit えき darüber |
| Nackt | danach | 駅 |

Weil alle Leser die Folgen in derselben Reihenfolge lesen, ist die Schreibform pro Folge und Wort fest und steht im Plan. Sie kann in die Bilder gesetzt werden, wie bei Folge 01 mit dem Beschriftungs-Skript. Wer eine alte Folge noch einmal liest, sieht die alte Form. Das ist richtig so: So hat Mira es damals gesehen.

Im Café gilt dieselbe Stufe: Die Karte eines Worts zeigt die Schreibform, die der Leser nach seiner letzten Folge kennt. Die Schreibung mit Kanji steht im Wortvorrat, die Anzeige rechnet die Stufe aus den eingeführten Kanji aus.

Jede Rückkehr eines Worts in Kanji ist damit auch eine Kanji-Wiederholung. Das ist die stille Hälfte des Kanji-Übens, neben Nachzeichnen und Café.

---

## 9. Das Prüfwerkzeug

Der vorhandene Folgen-Prüfer prüft eine Folge. Der Serien-Prüfer prüft die Staffel als Ganzes. Er ist ein Test, der über alle ausgelieferten Folgen läuft, und ein Kommandozeilen-Bericht für die Autoren.

**Was er prüft.**
1. Jedes Budget-Wort steht im Vorrat. Kein Wort wird zweimal eingeführt.
2. Budget pro Folge: 15 bis 20 Wörter, 2 bis 4 Kanji.
3. Kein Kanji ohne Ort; kein Schild-Kanji ohne Trägerwort, das in derselben Folge vorkommt.
4. Wiedersehen-Regel und Wiedersehen-Quote nach §7, mit dem Hochlauf aus §6.
5. Schriftstufe nach §8: Kein Token trägt ein Kanji, das erst später eingeführt wird. Lesehilfe ist da, wo sie hingehört.
6. Vorkommen-Mindestzahl nach §6.
7. Ein Grammatik-Punkt, ein Nachzeichnen-Moment, mindestens ein Sprechmoment pro Folge.

**Was er berichtet.** Nach Folge N: wie viele der 800 eingeführt sind, wie viele geplant waren, welche Wörter überfällig für ihr Wiedersehen sind, welche Kanji ohne Trägerwort geplant sind, welche Bankwörter getauscht wurden. Als Tabelle im Terminal.

**Wo er lebt.** `lib/features/story/plan/season_plan_ja.dart` für den Plan, `season_validator.dart` für die Regeln, `test/features/story/season_plan_test.dart` als Test, `tool/serienplan_report.dart` für den Bericht.

**Vorgeschlagene Invarianten**, damit die Regeln denselben Rang bekommen wie die aus dem Brief:
- INV-12: Kein Kanji ohne Ort in derselben Folge; Schild-Kanji brauchen zusätzlich ein Trägerwort, das in ihr vorkommt.
- INV-13: Jedes Wort kehrt binnen drei Folgen wieder und noch einmal binnen zehn.

---

## 10. Was sich an bestehenden Dokumenten ändert

- **Lernmechanik-Design §3 und §8:** Der Grundwortschatz-Anschub im Strukturgleis entfällt. Die 800 laufen über die Serie. Kana, Kanji-Systematik und Grammatik bleiben im Strukturgleis. Der Sequenz-Schritt 5 „Grundwortschatz-Auslauf" wird gegenstandslos.
- **Drehbuch Folge 01, Abschnitt Serien-Curriculum:** „70 bis 100 Folgen" und „Start bei 8 pro Folge" werden durch 45 Folgen in drei Staffeln ersetzt. Der dort genannte Abdeckungs-Tracker ist der Serien-Prüfer aus §9.
- **Café-Spec §11:** Schritt 3, Zeichen im Café, wird von Folge 02 an gebraucht und rückt vor Schritt 4.
- **Folge 01:** Die Schlusskarte im Code sagt „ein Zeichen und vier Wörter", das Drehbuch „zwei Zeichen und achtzehn Wörter". Der Plan zählt fünf Zeichen. Der Code wird auf das Drehbuch gebracht, das Drehbuch zählt Kana künftig mit.
- **Brief:** Die Invarianten INV-12 und INV-13 werden ergänzt, wenn Uli sie annimmt.

---

## 11. Umsetzung in Arbeitspaketen

Reihenfolge ist Absicht. Jedes Paket bekommt seinen eigenen Plan.

1. **Wortvorrat 800.** Claude stellt die Liste zusammen, mit deutscher Bedeutung, Kanji-Schreibung und Lebensbereich. Uli sichtet eine Stichprobe von 50. Ergebnis: `vocab_pool_ja.dart`.
2. **Kanji-Vorrat.** Ableitung aus dem Wortvorrat, Sortierung nach Nutzen, Abgleich mit N5, Zuordnung von Trägerwort und Ort. Strichfolge-Dateien aus KanjiVG werden je Folge nachgezogen, nicht auf Vorrat.
3. **Staffelplan 1 als Daten und der Serien-Prüfer.** Der Prosaplan aus `docs/story/STAFFEL_1_DIE_ADRESSE.md` wird zu `season_plan_ja.dart`: pro Folge Wörter, Kanji, Grammatik, Momente. Dazu Prüfer, Test und Bericht. Folge 01 läuft als erste durch.
4. **Folge 02 als Pilot des dichten Formats.** Drehbuch, Manifest, Renders, Beschriftung, Nachbesprechung mit Zeichen. Wenn Folge 02 den Prüfer besteht und Uli auf dem Gerät gefällt, ist das Format bewiesen.
5. **Dokumente nachziehen** nach §10.

Danach laufen die Folgen 03 bis 15 je als eigenes Paket im bewiesenen Format.

---

## 12. Risiken und offene Punkte

- **Dichte gegen Lesbarkeit.** 120 Vorkommen in 11 Panels sind mehr Text, als Folge 01 hat. Folge 02 muss zeigen, dass das auf dem Handy noch wie ein Manga wirkt und nicht wie ein Lehrbuch. Wenn nicht, ist die Stellschraube die Wiedersehen-Quote, nicht das Budget.
- **Render-Aufwand.** 45 Folgen zu 11 Panels plus Reaktionsbilder sind rund 550 Renders. Die Pipeline steht, der Aufwand ist Kalenderzeit, kein technisches Risiko.
- **Wortlisten und Lizenz.** N5-Listen sind inoffiziell. Wir stellen unsere eigene Auswahl zusammen und prüfen gegen JMdict. Es entsteht keine Abhängigkeit von einer fremden Liste.
- **Der Plan wird der Geschichte im Weg stehen.** Das ist gewollt und begrenzt: Die Bank aus §2 gibt Luft, die Wiedersehen-Regel lässt drei Folgen Spielraum.
- **Kana-Lücke beim Lesen.** Wer die Kana-Lektionen nicht macht, liest die Blasen nie selbst. Die Geschichte funktioniert trotzdem über Ton und Erzählkästen. Ob das reicht, zeigt der Gerätetest, nicht diese Spec.
- **Figuren-Konsistenz über 45 Folgen.** Yamada, die Gemüsefrau und später Haru brauchen feste Beschreibungen im Render-Prompt, wie bisher bei Mira.

---

## 13. Abnahme

Die Spec gilt als abgenommen, wenn Uli den Staffelbogen aus §5 und die Maße aus §6 bestätigt. Danach folgt der Plan für Arbeitspaket 1. Ulis Gerätetest von Folge 02 ist die Abnahme des Formats.
