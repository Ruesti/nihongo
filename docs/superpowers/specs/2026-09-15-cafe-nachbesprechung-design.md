# Design: Das Café als Nachbesprechung — nach der Folge geht es ins Café

**Datum:** 2026-09-15
**Status:** Entwurf — wartet auf Ulis Review
**Anlass:** Ulis Frage vom 15.9.: *„Nach einer Folge geht es dann ins Café? Dann müsste
in der ersten Folge das Café eingeführt werden. Im Café dann erklären und wiederholen
der Wörter, Schriftzeichen erklären und wiederholen, dann wäre auch Gelegenheit für
Grammatik — was man wie, wo und warum verwendet."* Und: *„Im Café könnte auch sowas
erklärt werden wie ‚danke heißt arigatou, man kann aber auch sagen …'"*

**Ulis Entscheidungen (15.9.):**
1. Das Café erklärt **nur die Grammatik der gerade gelesenen Folge**. Der geführte Weg
   behält daneben seine **systematische Grammatik-Reihe** (für alle, die auch außerhalb
   des Mangas lesen).
2. Die Wirtin darf **Varianten** nennen („man kann auch sagen …"), ohne dass daraus
   neue Karteikarten werden (siehe §4, Präzisierung von INV-8).

**Baut auf:** dem Story-Brief (`docs/story/BRIEF_STORY_ENGINE.md`, §4 Café), der
Lernmechanik-Spec (`2026-09-13-lernmechanik-ein-lernweg-zwei-gleise-design.md`,
PR #43 — wird in §7 an drei Stellen angepasst), der Reader-Erleben-Spec
(`2026-09-13-reader-erleben-design.md`, PR #45 — liefert Endkarte und `outro`) und dem
Begegnungs-Ritual der Empfang-Spec (`2026-08-17-empfang-erste-begegnung-design.md`, A4).

---

## 1. Ausgangslage: die Lücke zwischen Folge und Café

Heute passiert nach dem letzten Panel sichtbar nichts. Die acht Wörter der Folge wandern
still in den Karteikasten (sofort als „fällig"), PR #45 ergänzt eine Endkarte mit
Erzählhaken und schickt zurück zum Lesen-Tab. Das Café erreicht man getrennt davon über
den Hinweis auf der Startseite. Dort sitzt dann zwar tatsächlich die Wirtin mit genau
diesen Wörtern — aber niemand hat dem Lerner gezeigt, dass Folge und Café zusammengehören.

Drei Dinge fehlen konkret:

- **Das Café kommt in Folge 01 nicht vor.** Es kam erst nach dem Pilot-Drehbuch ins
  Konzept; das Skript-Ende (`PILOT_01_REGEN.md`, „Auslauf") redet noch vom alten
  Kartenfeed. Einzige Brücke ist der Erzählhaken der Endkarte („… der Name des Cafés
  kommt ihr bekannt vor").
- **Das Café erklärt nichts.** Es wiederholt Wörter (vier Gäste = vier Sprossen),
  Bedeutung ist frei antippbar und zählt als Hinweis. Zeichen und Grammatik kennt es
  nicht; die Übergabe am Folgen-Ende führt nur Wörter ein, die drei Kana der Folge
  gar nicht.
- **Grammatik hat keinen Ort.** `GrammarPoints` existiert als Tabelle ohne Lehrtext,
  ohne Anschluss an die Leiter, ohne Inhalt.

## 2. Zielbild

**Nach jeder Folge geht es ins Café.** Die Figur tritt ein, die Wirtin hat die Wörter,
Zeichen und Grammatikpunkte dieser Folge auf dem Tisch. Erst **erklärt** sie
(Bedeutung, wo es in der Folge vorkam, wie man es benutzt, was man auch sagen kann),
dann **fragt sie nach**. Danach ist es das normale Café: wer sonst fällig ist, sitzt da.

Ein Ort, eine Wirtin, zwei Anlässe: die **Nachbesprechung** direkt nach der Folge und
der **normale Besuch** für alles, was fällig ist.

**Der Grundsatz, der alles zusammenhält:** *Das Café erklärt nur, was in einer gelesenen
Folge vorkam.* Nichts Neues, nur Vertiefung. Die Geschichte bleibt der einzige Weg, auf
dem Sprache in die App kommt; das Café ist der Ort, an dem jemand sie dir erklärt. Das
ist wörtlich die Begründung, die der Brief für das freie Antippen gibt (§4.4: „hier
hilft dir jemand — draußen auf der Straße bist du allein mit dem Buch").

## 3. Das Erlebnis, Schritt für Schritt

### 3.1 Folge 01 führt das Café ein

Das Vordach, unter dem sie in P23/P24 stehen bleibt und das Wörterbuch aufschlägt,
**ist das Vordach des Cafés.** Über ihr das Schild mit dem Namen, den sie vom Zettel
kennt. Sie geht hinein.

- **Neues Epilog-Panel P25** (Ankerachse `A7`, Café innen): Sie tritt ein, nass, das
  Wörterbuch unter dem Arm. Die Wirtin hinter dem Tresen blickt auf, nickt. **Kein
  Dialog** — damit kein neues Wort ins Budget der Folge rutscht (INV-3). Ein deutscher
  Gedanke reicht: *„Warm. Und jemand, der nicht wegschaut."*
- Die Endkarte (`outro`, PR #45) endet an der Café-Tür, nicht davor: *„Der Zettel ist
  unleserlich. Aber das Wort auf dem Schild über ihr kennt sie. Drinnen brennt Licht."*
- **Übergang ohne Neurender:** Solange P25 nicht gerendert ist, trägt die Endkarte den
  Eintritt allein („Sie geht hinein." + Weg ins Café). Das Panel ist später reiner
  Asset-Tausch. Kein Café-Erzählbogen entsteht (§6 des Briefs bleibt gewahrt): P25 ist
  das letzte Panel der Folge, keine Nebenhandlung.

### 3.2 Folgen-Ende → Café (kein Gate)

Die Endkarte bekommt zwei Wege:

- **„Ins Café"** (primär): öffnet die Nachbesprechung dieser Folge.
- **„Später"** (sekundär): zurück zum Lesen-Tab, wie in PR #45 beschrieben.

Die Folge gilt in beiden Fällen als gelesen (INV-1: kein Gate). Wer „Später" wählt,
findet die Wirtin beim nächsten Café-Besuch mit derselben Einladung (§3.6).

### 3.3 Akt 1 — Die Wirtin erklärt

Alle Items, die die Folge einführt (ihr Manifest: Wörter, Zeichen, Grammatikpunkte),
in der Reihenfolge ihres ersten Auftritts. Pro Item eine Karte, nur „Weiter", keine
Bewertung. **Diese Karte ist das Begegnungs-Ritual der Empfang-Spec (Sprosse 0)**, um
das ergänzt, was nur das Café weiß: die Stelle in der Folge und die Stimme der Wirtin.

Die Wirtin erklärt **auf Deutsch.** Das ist eine bewusste Ausnahme zur Regel „Japanisch
ist die Welt" der Reader-Erleben-Spec, und sie ist dieselbe Ausnahme, die das Café
schon für die Bedeutung macht: Hilfe ist in deiner Sprache. Japanisch spricht die
Wirtin nur, wenn sie das Item selbst vorsagt.

**Wort** (z. B. ありがとう):
- groß, mit Lesung, hörbar (TTS) — die Wirtin sagt es vor;
- deutsche Bedeutung;
- **die Stelle in der Folge:** Miniatur des Panels, in dem es zum ersten Mal vorkam
  („So hat sie es zu dem Mann gesagt."). Wird aus den Folgendaten abgeleitet, nichts
  zu autorieren;
- **Gebrauch** in ein bis zwei einfachen Sätzen: was man damit tut, wann es passt;
- **„Man kann auch sagen …":** Varianten mit Lesung, Bedeutung, kurzer Einordnung,
  hörbar. Beispiel: *„Danke heißt ありがとう. Zu Fremden und Älteren sagt man
  ありがとうございます, das ist höflicher. Ganz beiläufig geht auch どうも."*
  Varianten sind Wissen, keine Karteikarten (§4).

**Zeichen** (z. B. あ):
- groß, hörbar, **Strichfolge animiert** wo eine Strichfolge-Datei gebündelt ist
  (KanjiVG; あ ja, め heute nicht → dann stehendes Zeichen), wiederholbar;
- **Nachfahren** mit dem Finger auf der vorhandenen Zeichenfläche
  (`DiegeticTraceSheet`; falls PR #26 vorher landet, dessen `TracePractice`);
- **„Kommt vor in":** die Wörter dieser Folge, die das Zeichen enthalten (あめ, かさ) —
  abgeleitet, nicht autoriert;
- Merkbild oder Eselsbrücke, falls vorhanden.

**Grammatik** (z. B. こわれた → 〜た):
- **Muster** und **„warum"-Erklärung** in schlichtem Deutsch: was es tut, wie es
  gebaut ist, wo es steht, wann man es braucht;
- **das Beispiel aus der Folge:** die Sprechblase, in der das Muster vorkam, als
  Panel-Miniatur — plus ein zweites, minimales Beispiel nur aus Wörtern der Folge;
- optional ein Kontrastpaar;
- gerahmt durch das Kann-Ziel: *„Damit verstehst du, wenn jemand sagt, dass etwas
  schon passiert ist."*
  Das ist die `GrammarCard` aus der Reicher-Lern-Loop-Spec (§F), gefüllt aus den
  dort vorgesehenen Feldern (§5.5).

Nach der Karte steht das Item auf **Sprosse 1** (Begegnung abgeschlossen), genau wie
nach einer Lektions-Begegnung. Items, die durch einen diegetischen Sprech- oder
Schreibmoment schon auf Sprosse 1 stehen, bekommen die Karte trotzdem — erklärt wird
alles, was die Folge eingeführt hat; die Karte ist keine zweite Einführung, sondern
die erste Erklärung.

### 3.4 Akt 2 — Die Wirtin fragt nach

Dieselben Items noch einmal, jetzt als **Café-Turns** wie heute: Prompt der Wirtin,
Antwort, Reaktion (`followUp`-Rotation), Bewertung in den Karteikasten. Die Übungsform
folgt der Sprosse (nach Akt 1 also Erkennen). Das entspricht der Lektions-Regel der
Empfang-Spec: *erst die Begegnungen der ganzen Gruppe, dann die Erkennungs-Übungen
dazu — unmittelbares Abrufen, aber nie kalt.*

Zeichen werden in Akt 2 nachgezeichnet (Nachzeichnen-Repertoire der Wirtin, wie in
der Lernmechanik-Spec §5 vorgesehen), Grammatik nach dem Erkennen-Muster der
Reicher-Lern-Loop-Spec (Muster zeigen → aufdecken → Funktion).

Am Ende: eine Schlusszeile der Wirtin (rotierend, mindestens drei), dann der normale
Café-Raum mit der aktuellen Belegung. Kein Zwischenscreen „Folge abgeschlossen", keine
Zahl, kein Häkchen (Brief §6, INV-10).

### 3.5 „Erklär's mir nochmal" im normalen Besuch

Jeder Café-Turn bekommt neben dem heutigen Bedeutungs-Tipp einen Weg zur vollen
Erklärungskarte des Items („Erklär's mir nochmal"). Beides zählt als **Hinweis** und
bewertet den Turn wie heute als `hard` (Brief §4.4: nicht als Fehler, aber nicht
folgenlos). Für Items ohne Erklärungsblock (ältere Inhalte, Grundwortschatz) zeigt die
Karte das, was sie hat: Wort, Lesung, Bedeutung, Konzeptbild.

Damit gilt die Regel der Empfang-Spec auch im Café durchgängig: *Trifft die
Warteschlange auf ein Sprosse-0-Item, kommt zuerst die Begegnung.* Wer die
Nachbesprechung auslässt und direkt zur Wirtin geht, bekommt jedes Sprosse-0-Wort
trotzdem zuerst erklärt, dann abgefragt — nur ohne die Folgen-Reihenfolge.

### 3.6 Später, Abbruch, Wiederkommen

- Eine Nachbesprechung ist **offen**, bis Akt 1 vollständig gesehen wurde. Akt 2 ist
  normale Wiederholung; was dort liegen bleibt, bleibt schlicht fällig.
- Solange eine Nachbesprechung offen ist, **ist die Wirtin anwesend** — auch wenn
  sonst nichts fällig ist. Ihr Tisch trägt die Einladung: *„Wollen wir über die Folge
  reden?"* Das ist die diegetische Fassung von „da wartet noch was", ohne Zähler,
  Punkt oder Badge (INV-10). Ist nichts offen und nichts fällig, wischt sie wie heute
  den Tresen.
- Abbruch mitten in Akt 1: beim nächsten Mal geht es beim ersten noch nicht erklärten
  Item weiter.
- Eine Folge wird **einmal** nachbesprochen. Wer sie erneut liest, bekommt die Endkarte
  mit „Ins Café" trotzdem (dann landet er im normalen Café); die Wirtin erklärt nicht
  zweimal.

### 3.7 Grammatik: die Rollenverteilung (Ulis Entscheidung)

| | Café (Nachbesprechung) | Geführter Weg (Gleis 1) |
|---|---|---|
| **Was** | nur die Grammatikpunkte, die die gelesene Folge einführt | die systematische Reihe (`sequenceIndex`), unabhängig vom Manga |
| **Wie** | in der Szene der Folge, mit ihrem Beispiel | in kleinen Lektionen mit Kann-Ziel |
| **Wiederholt wo** | im Café (beide Quellen) | im Café (beide Quellen) |

Beide speisen **denselben** Karteikasten (ein Item-Raum, Lernmechanik-Spec §4.2). Ein
Grammatikpunkt, den eine Folge einführt, ist danach eingeführt; die Lektion des
geführten Weges zum selben Punkt findet ihn vor und überspringt die Begegnung (die
Einführung ist idempotent, `JourneyService` lässt Sprosse ≥ 1 aus). Umgekehrt erklärt
die Wirtin einen Punkt, den der geführte Weg schon gelehrt hat, trotzdem in der
Folgen-Szene — Erklären ist keine Einführung.

## 4. Regeln, die stehen bleiben — und eine Präzisierung

| Invariante | Wie sie gewahrt bleibt |
|---|---|
| **INV-1** (kein Gate) | Die Endkarte hat „Später". Die Folge ist gelesen, egal was danach kommt. |
| **INV-2** (Story: nie Bedeutung) | Erklärungen gibt es nur im Café. Der Reader zeigt weiterhin Audio + Kana. |
| **INV-3** (Budget) | P25 ist wortlos. Zeichen stehen schon im Manifest (`glyphs`), Grammatik kommt als eigene Liste dazu; der Validator prüft beide mit. |
| **INV-5** (keine Sprosse > 2 vor Ende) | Die Nachbesprechung öffnet erst nach dem letzten Panel; Akt 2 bewertet Sprosse 1–2. |
| **INV-6** (Produktion nicht im Story-Modus) | Nachzeichnen und Abfragen finden im Café statt, nicht im Reader. |
| **INV-8** (Café führt nichts ein) | Quelle der Nachbesprechung = Manifest der Folge **∩** Karteikasten. Nur was die Übergabe am Folgen-Ende eingeführt hat, liegt auf dem Tisch. Siehe Präzisierung unten. |
| **INV-9** (Bedeutung nur für Eingeführtes) | Erklärungskarten und „Erklär's mir nochmal" existieren nur für Items im Karteikasten. Kein Weg zu Ungelesenem. |
| **INV-10** (kein Café-Fortschritt) | Keine Marke außer „nachbesprochen ja/nein" pro Folge, und die schaltet nichts frei. Anwesenheit der Wirtin ist Belegung, kein Zähler. |

**Präzisierung von INV-8 — Variante ≠ Item.** Wenn die Wirtin sagt *„man kann auch
sagen ありがとうございます"*, führt sie **kein Item** ein: Die Variante bekommt keine
Karteikarte, wird nie abgefragt, taucht bei keinem Gast als Prompt oder erwartete
Antwort auf. Sie ist Wissen, das am eingeführten Wort hängt. Eine Variante wird erst
dann zum Item, wenn eine Folge sie selbst einführt — dann über den normalen Weg
(Budget, Übergabe, Nachbesprechung). Erzwingbar: Nach einer Nachbesprechung enthält
der Karteikasten exakt die Items des Manifests, keine Variante (§10).

**Neue Regel (Vorschlag für den Brief als INV-11):** *Die Nachbesprechung einer Folge
ist erst nach deren vollständigem Lesen erreichbar, und ihre Item-Quelle ist
ausschließlich die Schnittmenge aus Folgen-Manifest und Karteikasten.*

## 5. Datenmodell & Nahtstellen

### 5.1 Episodenschema (`episode.dart`)

| Feld | Status | Zweck |
|---|---|---|
| `EpisodeBudget.grammar: List<GrammarRef>` | neu | Grammatikpunkte, die die Folge einführt (Ids aus `GrammarPoints`) |
| `Episode.debrief: Map<String, DebriefNote>` | neu, optional | Erklärungsblock je Item-/Glyph-/Grammatik-Id: `usage` (deutsch), `variants: [{form, reading, meaning, note}]`, `mnemonic?` (Zeichen) |
| `StoryToken.grammarId: String?` | neu, optional | markiert die Blase, die ein Grammatikmuster zeigt (Folgen-Beispiel) |
| `Episode.outro` | aus PR #45 | Endkarte; endet jetzt an der Café-Tür |

- **Warum Folgen-Content und nicht Wörterbuch-Tabelle:** Die Wirtin erklärt in der
  Szene der Folge („so hat sie es zu dem Mann gesagt"), und die Wörter werden ohnehin
  pro Folge autoriert. Keine Migration der `LearningDb` nötig. Ein Wort, das eine
  spätere Folge nur wiederverwendet, steht nicht in deren Budget und wird dort nicht
  erneut erklärt.
- **Abgeleitet, nicht autoriert:** Erstauftritt-Panel eines Items (erstes Panel, dessen
  Token diese `itemId` trägt), „kommt vor in" für Zeichen (Budget-Wörter, deren
  `writtenForm` das Zeichen enthält), Folgen-Beispiel eines Grammatikpunkts (Blase,
  deren Token die `grammarId` trägt).
- Alle neuen Felder sind optional mit Fallback: fehlt `debrief`, zeigt die Karte Wort,
  Lesung, Bedeutung und Erstauftritt-Panel; fehlt `budget.grammar`, gibt es in dieser
  Folge keine Grammatik-Karten. Bestehende Folgen und Tests bleiben gültig.

### 5.2 Übergabe am Folgen-Ende (`EpisodeSrsHandoff`)

`introduceEpisode` führt neben `budget.items` (Wörter) künftig auch `budget.glyphs`
als `RefType.character` und `budget.grammar` als `RefType.grammar` ein — alle auf
Sprosse 0, idempotent wie heute. Erst dadurch liegen Zeichen und Grammatik der Folge
überhaupt im Karteikasten und damit auf dem Tisch der Wirtin (INV-8-konform).

Bekannte Vorbelastung, unverändert: die Kopplung `cando_ja_a1_kana` an alle
A1-Lexeme (Folge-Ticket, siehe Story-Engine-Notizen).

### 5.3 Café (`lib/features/cafe/`)

- **Zweite Item-Quelle.** Neben `getDueItems` (normaler Besuch) bekommt das Café eine
  Quelle `itemsForEpisode(episodeId)` = `learn_items`, gefiltert auf die Ids des
  Folgen-Manifests, in Manifest-Reihenfolge. Beide Quellen lesen ausschließlich
  `learn_items` — der strukturelle INV-9-Test (`cafe_inv9_test.dart`) wird um die
  zweite Quelle erweitert, nicht gelockert.
- **Belegung** (`CafeOccupancy`): bekommt zusätzlich `pendingDebrief: episodeId?`.
  Ist eine Nachbesprechung offen, ist die Wirtin anwesend, mit Einladungs-Prompt statt
  Turn-Prompt.
- **Route** (`CafeRoute`, `/review`): optionaler Parameter `debrief=<episodeId>`.
  Mit Parameter startet die Nachbesprechung dieser Folge; ohne wie heute. Ist die
  Folge nicht abgeschlossen oder ihre Nachbesprechung schon erledigt
  (`debriefDone`), fällt die Route auf den normalen Besuch zurück.
- **Nachbesprechungs-Ablauf** (`CafeDebriefScreen`, neu): Akt 1 = Sequenz von
  Erklärungskarten (§5.4) mit „Weiter"; nach jeder Karte eines **Sprosse-0-Items**
  `markEncountered` (Sprosse 0 → 1, wie die Lektions-Begegnung), Items auf höherer
  Sprosse bleiben unberührt. Akt 2 = bestehender `CafeTurnScreen`-Ablauf über
  dieselbe Item-Liste (Wirtin-Skript, `followUp`, `LadderReview.submit`).
- **Sprosse 0 im normalen Turn** (`CafeTurnScreen`): trifft die Wirtin auf ein
  Sprosse-0-Item, kommt zuerst die Erklärungskarte (mit `markEncountered`), dann der
  Turn — die Regel der Empfang-Spec, jetzt auch im Café (§3.5).
- **Turn-Inhalt** (`CafeTurnContent.forItem`): heute nur Lexeme. Wird polymorph über
  `RefType` wie `resolveExercise`: Zeichen → Nachzeichnen, Grammatik → Erkennen-Muster
  (Reicher-Lern-Loop §F). Für Typen ohne Inhalt: Item überspringen, nicht abstürzen.
- **„Erklär's mir nochmal"** (`CafeTurnScreen`): öffnet die Erklärungskarte des
  Items; setzt `hintUsed` (→ `CafeOutcome.hinted` → `hard`), genau wie der
  Bedeutungs-Tipp heute.

### 5.4 Die Erklärungskarte = Begegnung + Café-Zusatz

Wiederverwendet `EncounterView` (polymorph über `RefType`, `lib/features/encounter/`).
Neu ist nur ein Zusatzbereich, den das Café mitgibt: Erstauftritt-Miniatur mit
Wirtin-Zeile, Gebrauchstext, Varianten (jede mit „anhören"), „kommt vor in". Die Karte
bleibt ohne Bestehen/Durchfallen („Weiter"), wie in der Empfang-Spec.

### 5.5 Grammatik-Schema (Abhängigkeit)

Die Reicher-Lern-Loop-Spec (§F, PR #26) sieht vor: `GrammarPoints` +=
`pattern`, `explanation`, `example`, `contrast?` (Schema-Bump, Migration,
`build_runner`), Loader `_loadGrammar` für Begegnung **und** benotete Sprossen,
`GrammarCard` als Lehr-Karte. **Diese Spec erfindet dazu nichts Neues.** Landet PR #26
vorher, wird es benutzt; landet es nicht vorher, trägt der Umsetzungsplan dieser Spec
genau diese Felder mit denselben Namen, damit nichts auseinanderläuft.

### 5.6 Validator (`EpisodeValidator`)

Zusätzlich zu INV-3/INV-4:
- jeder Schlüssel in `debrief` ist im Manifest (Wörter, Zeichen oder Grammatik);
- keine Varianten-Form ist gleichzeitig `writtenForm` eines Budget-Items derselben
  Folge (sonst ist es kein „auch sagen", sondern ein zweites Item — dann gehört es ins
  Budget);
- jede `grammarId` im Budget hat mindestens eine Blase, deren Token sie trägt
  (das Folgen-Beispiel muss existieren);
- höchstens zwei Varianten je Item (§8: die Wirtin hält keinen Vortrag).

Verstöße schlagen beim Content-Build fehl, nicht zur Laufzeit.

### 5.7 Ablage

`StoryProgressStore` (SharedPreferences) bekommt `debriefIndex:<episodeId>`
(Fortschritt in Akt 1) und `debriefDone:<episodeId>`. Nichts davon ist Fortschritt im
Sinne von INV-10: Es schaltet nichts frei und wird nirgends gezählt.

## 6. Content für Folge 01 (Ulis Anteil, Claude entwirft die Texte)

**Panel P25** (neu, `A7` Café innen): siehe §3.1. Bis zum Render trägt die Endkarte den
Eintritt.

**Endkarte (`outro`):** Entwurf siehe §3.1, Uli formuliert nach Geschmack um.

**Erklärungsblock — Entwurf zum Gegenlesen** (Stimme: die Wirtin, warm, kurz):

| Item | Gebrauch (Entwurf) | „Man kann auch sagen …" |
|---|---|---|
| すみません | „Entschuldigung" — aber genauso: „Hallo, darf ich mal?" Sie benutzt es, um jemanden anzusprechen, nicht nur, um sich zu entschuldigen. | ごめんなさい (persönlicher: „tut mir leid"), すみませんでした (für etwas, das schon passiert ist) |
| あめ | Regen. Das erste Wort, das sie selbst gelesen hat. | — (Randbemerkung: mit anderer Betonung heißt あめ „Bonbon" — man hört den Unterschied) |
| かさ | Schirm. In P15 ist er nur ein Ding in der Hand, in P21 wird er zum Wort. | — (später als Kanji 傘) |
| これ | „das hier" — das Ding bei mir. | それ („das da", bei dir), あれ („das dort", weit weg) |
| こわれた | „kaputt" — genauer: „ist kaputtgegangen". Die Form sagt: es ist schon passiert. | こわれています (ist kaputt, als Zustand, höflich) |
| はい | „ja". Und beim Überreichen: „hier, bitte" (P21: はい、どうぞ). | ええ (weicher), うん (locker, unter Freunden) |
| どうぞ | „bitte, hier" — wenn man etwas gibt oder anbietet. Nicht das „bitte" einer Bitte. | — (das Gegenstück ist ありがとう) |
| ありがとう | „danke". | ありがとうございます (höflicher, zu Fremden und Älteren), どうも (kurz, beiläufig) |

**Zeichen** あ め か: Strichfolge (あ gebündelt; め muss gebündelt werden, sonst
stehend), „kommt vor in" ergibt sich (あめ, かさ). Merkbilder optional.

**Grammatik (Vorschlag, Ulis Entscheidung):** Folge 01 hat wenig Satzbau. Ein Punkt
bietet sich an: **〜た — „es ist schon passiert"** an こわれた (Muster: Verb-Stamm + た;
warum: die Form markiert, dass etwas geschehen ist; Beispiel aus der Folge: P17;
Kann-Ziel: verstehen, dass etwas passiert ist). Wer das für Folge 01 zu früh findet,
lässt `budget.grammar` leer; ab Folge 02 trägt jede Folge ein bis zwei Punkte.

**Folge 02 und weiter:** Jede Folge benennt im Manifest ihre Wörter, Zeichen und
Grammatikpunkte und liefert den Erklärungsblock. Der Content-Build erzwingt die Regeln
aus §5.6.

## 7. Anpassungen an der Lernmechanik-Spec (PR #43)

Drei Stellen, im selben PR-Stapel geändert:

1. **§3 Gleis 1, Punkt Grammatik:** „Vermittlung in kleinen Lektionen auf dem Gleis"
   bleibt; ergänzt wird, dass Grammatik, die eine Manga-Folge einführt, **zusätzlich**
   die Wirtin in der Nachbesprechung erklärt. Abruf beider im Café.
2. **§5 Eine erlebte Fälligkeit:** neuer Punkt „Nachbesprechung" — das Café hat eine
   zweite Item-Quelle (Manifest der gerade gelesenen Folge), beide Quellen liefern nur
   Eingeführtes, INV-8/9/10 unverändert.
3. **§7 Nicht behandelt:** Verweis auf diese Spec.

Die Reihenfolge in §9 der Lernmechanik-Spec bleibt; Schritt 2 („Café auf den gemeinsamen
Pool") umfasst dann beide Quellen.

## 8. Bewusst NICHT

- **Kein Café-Erzählbogen.** P25 gehört zur Folge. Die Wirtin bekommt keine
  Geschichte, keine Freundschaft, keine Entwicklung (Brief §6).
- **Keine neuen Items im Café.** Varianten werden nicht abgefragt, nie eingeführt.
- **Keine Erklärungen im Story-Modus.** Der Reader bleibt bei Audio + Kana (INV-2).
  Wer beim Lesen eine Erklärung will, geht ins Café.
- **Kein Zwang.** „Später" ist immer da; die Wirtin wartet, sie drängt nicht.
- **Kein Ersatz für die Grammatik-Reihe des geführten Weges** (Ulis Entscheidung).
- **Keine Zähler, Häkchen, Prozente** — auch nicht „3 von 8 erklärt".
- **Keine Varianten-Kaskade:** höchstens zwei Varianten pro Wort. Die Wirtin erklärt,
  sie hält keinen Vortrag.

## 9. Risiken

| Risiko | Umgang |
|---|---|
| Nachbesprechung wird lang (Folge 01: 8 + 3 + 0–1 Karten, dann ebenso viele Turns) | Akt 1 ist reines „Weiter"; Abbruch jederzeit, Fortsetzung beim nächsten Besuch (§3.6). Ab Folge 02 Budget-Disziplin wie bisher (≈ 8 Wörter). |
| Erklärungen widersprechen später der systematischen Grammatik-Reihe | Beide lesen dieselben `GrammarPoints`-Felder (§5.5); die Folge liefert nur das Beispiel, nicht eine zweite Erklärung. |
| Varianten wachsen still zu einem Schatten-Wortschatz | Höchstens zwei pro Wort; Validator §5.6; struktureller Test §10. |
| め ohne Strichfolge wirkt wie ein Fehler | Stehendes Zeichen plus Nachfahren ist erlaubt; め-SVG bündeln bleibt Folge-Ticket. |
| Deutsch sprechende Wirtin bricht die Fiktion | Ausnahme ist dieselbe wie beim freien Antippen (Brief §4.4) und wird als Café-Regel ausgesprochen: hier hilft dir jemand, in deiner Sprache. |

## 10. Teststrategie & Abnahme

Strukturell (im Stil von `cafe_inv9_test.dart`, jeder Verstoß ein Testfehler):
- Die Quelle der Nachbesprechung liefert nur Items, die (a) im Manifest der Folge
  stehen **und** (b) als `learn_items` existieren; ein Manifest-Item ohne Übergabe
  erscheint nicht.
- Nach einer vollständigen Nachbesprechung ist die Menge der `learn_items` exakt die
  Manifest-Menge — keine Variante ist Item geworden.
- Die Nachbesprechung ist vor dem letzten Panel nicht erreichbar (Route mit
  `debrief=` ohne abgeschlossene Folge fällt auf den normalen Besuch zurück).
- Belegung: offene Nachbesprechung → Wirtin anwesend bei leerer Fälligkeit; nichts
  offen + nichts fällig → Leerzustand unverändert.
- „Erklär's mir nochmal" → `CafeOutcome.hinted` → `hard`.
- Endkarte „Später" → Lesen-Tab, Folge gilt als gelesen; erneutes Öffnen startet bei
  der Titelkarte (PR #45 §2.7).
- Validator: die vier Regeln aus §5.6, je ein Negativfall.
- Übergabe führt Zeichen und Grammatik ein (Sprosse 0), idempotent bei Wiederholung.

**Abnahme:** Ulis Gerätetest auf dem S23, wie bei PR #45 sein ausdrücklicher Wunsch.
Messlatte: Er liest Folge 01 zu Ende, geht ohne Rückfrage ins Café, versteht bei jeder
Karte, was die Wirtin ihm sagt und warum, und erlebt Akt 2 als Gespräch, nicht als
Abfrage.

## 11. Grobe Reihenfolge (für den Implementierungsplan, nicht Teil dieses Designs)

1. **Übergang + Wörter:** Übergabe führt Zeichen mit ein; Endkarte mit „Ins Café";
   Route-Parameter; `CafeDebriefScreen` mit Akt 1 (Erklärungskarte = `EncounterView`
   + Café-Zusatz aus abgeleiteten Daten) und Akt 2 (bestehende Turns); offene
   Nachbesprechung in der Belegung; Prefs. Folge 01 ist damit nachbesprechbar, auch
   ohne Erklärungsblock.
2. **Erklärungsblock:** `Episode.debrief` (Gebrauch, Varianten, Merkbilder), Validator,
   „Erklär's mir nochmal", Folge-01-Texte aus §6.
3. **Zeichen im Café:** Turn-Inhalt polymorph, Nachzeichnen als Wirtin-Turn.
4. **Grammatik:** Schema aus Reicher-Lern-Loop §F (falls nicht schon da),
   `GrammarRef` im Budget, `StoryToken.grammarId`, `GrammarCard` in Akt 1,
   Erkennen-Turn in Akt 2, optionaler Folge-01-Punkt.
5. **P25** rendern und einhängen (Asset-Tausch, Ulis Content-Anteil).

Jeder Schritt ist einzeln shipbar und lässt die App lauffähig. Voraussetzung für 1 ist
die Endkarte aus PR #45 (Stapel: #44 → #45 → diese Umsetzung).
