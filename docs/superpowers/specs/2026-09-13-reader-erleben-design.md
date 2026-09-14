# Design: Reader-Erleben — die Folge als erlebbare Geschichte

**Datum:** 2026-09-13
**Status:** Von Uli freigegeben („passt"); finale Abnahme ausdrücklich per
Gerätetest — *„ich muss das einmal erleben, um es beurteilen zu können."*
**Basis:** Branch `wire/w3-story-reader` (PR #44, Story-Reader in der App).
**Anlass:** Ulis erster Gerätetest von Folge 01. Befund: Die Mechanik stand,
das Erleben fiel durch — leere Platzhalter-Panels, Text unter statt im Bild,
Anleitungen und Feedback auf Japanisch (für einen Anfänger unlesbar),
Erfolg unsichtbar, Nachzeichnen ohne Aufgabe und ohne Vorlage.

---

## 1. Grundprinzip: Zwei Ebenen

- **Japanisch ist die Welt.** Es lebt ausschließlich im Artwork: Dialog in
  Sprechblasen (Lettering im Bild, Nutzerentscheidung „Option A"), Schilder,
  Beschriftungen. Antippen macht es zugänglich (Audio + Wörterbuch).
- **Deutsch ist Erzählstimme und Bedienung.** Erzählkästen, Titelkarte,
  Aufgaben („Sprich nach: …"), Feedback („Fast — hör noch einmal").
  **Kein Meta-Text ist je japanisch.** Die bisherigen japanischen
  UI-Texte (`なぞって:`, `よくできました ✓`, `もう一度どうぞ`) verstoßen
  dagegen und werden ersetzt.

Uli-Anforderung dahinter: *Die Geschichte muss tragen* — Spannung ist der
Lernmotor. Folge 01 hat eine Geschichte (stille Ankunft im Regen,
verlaufener Zettel, „Ich hätte anrufen sollen", die halbtote Shotengai,
das erste Wort im Café); dieses Design sorgt dafür, dass sie ankommt.

## 2. Das Erlebnis, Schritt für Schritt

### 2.1 Titelkarte (neu)
Vor Panel 1: Folgentitel („Folge 1 — Regen"), 1–3 Sätze deutsche
Anmoderation (wer, wo, Stimmung), „Tippe, um zu beginnen". Der bewusst
wortlose Bildauftakt (Panels 1–6) liest sich damit als Filmanfang, nicht
als Defekt.

### 2.2 Panels mit Sprechblasen im Bild
- Dialog-Lettering ist Teil des Artworks (Option A). Die App rendert
  KEINEN japanischen Dialogtext mehr unter dem Panel.
- Pro Blase liegt im Episodenformat eine Tippfläche — das Schema hat dafür
  bereits `StoryBubble.hitArea` (Polygon, normierte Koordinaten relativ
  zum Panelbild); es wird jetzt erstmals mit Daten gefüllt und gerendert.
  Tap auf die Fläche = anhören + Wörterbuch (bisheriges Verhalten, neuer Ort).
- **Fallback (Übergang):** Ein Panel, dessen Blasen keine `hitArea` haben,
  rendert den Dialog wie heute unter dem Bild. So bleibt die App mit den
  aktuellen Panels lauffähig, bis die neuen Bilder da sind — App-Umbau und
  Bild-Produktion blockieren sich nicht.

### 2.3 Erzählkästen (deutsch, App-gerendert)
`thoughts` (deutsche Gedanken/Erzähltexte) erscheinen als klassische
rechteckige Erzählkästen am oberen oder unteren Panelrand, comic-gestylt
(nicht als nackte Textzeile). Rechteckige Kästen funktionieren als Overlay;
nur organische Blasenformen gehören ins Artwork.

### 2.4 Sprechmoment (umgebaut)
- Aufgabe deutsch: „Hör zu und sprich nach:" + großes japanisches Ziel.
- Buttons: „anhören", „nachsprechen" (wie gehabt).
- Feedback deutsch: Erfolg „Gut! ✓" · Misserfolg „Fast — hör noch einmal
  und versuch's gleich nochmal."
- **Erfolg: die Geschichte reagiert (Weg 1, Nutzerentscheidung).** Das Sheet
  schließt sich von selbst (kurz verzögert, damit das ✓ ankommt), das Panel
  blendet weich auf sein **Reaktions-Bild** über (die Wirtin lächelt, nickt,
  schiebt den Tee hin), dazu erscheint eine deutsche Erzählzeile
  („Die Wirtin versteht dich."). Erfolg fühlt sich an wie: *ich wurde
  verstanden.*
- Kein Gate (INV-1 unverändert): „weiter" überspringt jederzeit; ohne
  Erfolg bleibt schlicht das Original-Panel — kein Story-Ast, kein Malus.

### 2.5 Nachzeichnen (umgebaut)
- Aufgabe deutsch: „Zeichne das Zeichen nach:".
- **Ghost-Vorlage:** Das Zielzeichen liegt groß und hellgrau IN der
  Zeichenfläche; man fährt es nach, statt ins Leere zu malen.
- Feedback deutsch; Erfolg → Reaktions-Bild + Erzählzeile wie beim Sprechen.

### 2.6 Folgen-Ende (neu)
Endkarte mit deutschem Erzählhaken auf die nächste Folge (z. B. „Der
Zettel ist unleserlich. Aber der Name des Cafés kommt ihr bekannt vor …")
und Rückkehr zum Lesen-Tab. Kein abrupter Schluss mehr.

### 2.7 Wiederbetreten (Fix)
Eine abgeschlossene Folge startet beim erneuten Öffnen bei der Titelkarte.
Der aktuelle Zustand (Start auf dem letzten Panel, Nachzeichen-Dialog
öffnet sofort wieder) entfällt.

## 3. Datenformat (Episodenschema)

Bestehendes bleibt; neu bzw. erstmals genutzt:

| Feld | Status | Zweck |
|---|---|---|
| `StoryBubble.hitArea` | existiert, wird erstmals befüllt/gerendert | Tippfläche der Blase im Bild (normierte Koordinaten) |
| `Episode.intro` (String, deutsch) | neu | Anmoderation der Titelkarte |
| `Episode.outro` (String, deutsch) | neu | Erzählhaken der Endkarte |
| `StoryInteraction.reactionAsset` (String?) | neu | Reaktions-Bild des Panels nach Erfolg |
| `StoryInteraction.reactionCaption` (String?, deutsch) | neu | Erzählzeile zur Reaktion |

Alle neuen Felder sind optional mit definiertem Fallback: Die Titelkarte
erscheint immer — fehlt `intro`, zeigt sie nur den Titel. Fehlt
`reactionAsset`, zeigt der Erfolg nur die Erzählzeile bzw. das deutsche
✓-Feedback. Bestehende Folgen und Tests bleiben gültig.

## 4. Content-Seite (Ulis Anteil, außerhalb des App-Plans)

- Panels mit Dialog: Blasen + japanisches Lettering im Bild (ckpt-6-Neurender).
- Pro Blase eine Tippfläche; dafür liefert der Umsetzungsplan ein
  **Klick-Werkzeug** (Bild ansehen, Rechteck aufziehen → Koordinaten),
  niemand tippt Zahlen.
- Pro Sprech-/Zeichenmoment ein Reaktions-Bild (Panel-Variante).
- Pro Folge zwei kurze deutsche Texte (Anmoderation, Endhaken).

**Prototyp zuerst (Abnahme-Strategie):** Damit Uli das Erlebnis beurteilen
kann, BEVOR er finale Renderarbeit investiert, erzeugt der Umsetzungsplan
provisorisches Lettering: Sprechblasen + japanischer Text werden
programmatisch (Skript, NotoSansJP) auf die vorhandenen Panels vom 8.9.
komponiert, Reaktions-Bilder provisorisch als erkennbar veränderte
Panel-Variante. Hässlich ist erlaubt — beurteilt wird das ERLEBNIS,
nicht das Artwork. Der Tausch gegen finale Bilder bleibt reiner
Asset-Austausch.

## 5. Bewusst NICHT (unverändert gültige Invarianten)

- Keine Punkte, Streaks, Abzeichen, Freischaltungen (INV-10).
- Keine Story-Verzweigung: das Reaktions-Bild ist ein Bonusbild im selben
  Panel-Slot, kein Ast.
- Kein Gate: jede Interaktion bleibt überspringbar (INV-1).
- Kein Furigana-Umschalter, keine Panel-Animationen (später denkbar).

## 6. Abnahme

Ulis Gerätetest des Prototyps auf dem S23 ersetzt das schriftliche
Spec-Review (sein ausdrücklicher Wunsch). Messlatte: Er kann die Folge
ohne eine einzige Rückfrage lesen — er weiß immer, was die App von ihm
will, erlebt eine Geschichte, und ein Erfolg fühlt sich nach Antwort der
Geschichte an.
