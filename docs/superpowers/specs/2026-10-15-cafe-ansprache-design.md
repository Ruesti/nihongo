# Design: Das Café spricht dich an — Vollbild, Ansprache-Bilder, Gästestimme, Sprechen mit Ansage

Stand 15.10.2026. Nachtrag zur Spec „Das Café als Übungsraum“ (8.10.,
`2026-10-08-cafe-uebungsraum-design.md`) und zur Spec vom 2.10. (§6.1 Bilder,
§6.3 Vollbild). Was hier steht, geht vor; was hier nicht steht, bleibt wie dort.

## 0. Auslöser und Entscheidungen

Uli 15.10. nach Plan A auf dem S23 (Build 2012): „Das Café gefällt mir noch nicht.
Erstens ist das Bild der jeweiligen Person viel zu klein. Hatte eher an Fullscreen
gedacht, Frage und Aufgabe als Overlay. Die jeweilige Person soll einen direkt
ansprechen, also Bild so, als würde sie direkt ansprechen, nicht Standardbild mit
unbestimmter Blickrichtung. Beim Sprechen weiß man gar nicht, was man sagen soll.“
Dazu: „Könnte man auch einen Audio-Modus einbauen, abschaltbar, dass der Gast seine
Frage richtig spricht?“

Befund im Code (Plan A): `StationFrame` zeigt das Stammplatz-Bild als 120 dp hohen
Streifen über einer Kopfleiste, darunter kursiv die Stimm-Zeile, darunter die Übung.
Die fünf Café-Bilder zeigen die Gäste von der Seite, keiner sieht in die Kamera.
Beim Schulmädchen „Sehen → Sprechen“ steht nur das Panel mit leerer Blase und
„Was steht da? Sag es. Los.“ — nichts sagt, welches Wort gemeint ist.

Entscheidungen (Uli, 15.10.):

1. **Bilder:** je Gast drei Stimmungen (fragend, zufrieden, abwinkend), **je Stimmung
   fünf Varianten** für Abwechslung. Licht nur Tag; die anderen Lichter später.
2. **Sprechen:** erst Bedeutung → Sprechen; bei Fehler sagt sie das Wort vor und zeigt
   die Kana, der zweite Versuch ist Nachsprechen.
3. **Satz der Person:** als oberste Zeile der Fläche, gestaltet wie eine Blase mit
   Spitze zur Person. Keine Blase im Bild.
4. **Stimme:** jetzt die Sprachausgabe des Handys mit Stimmprofil je Gast, sauber
   getrennt, damit später vorproduzierte Tondateien nur die Quelle austauschen.

Die Kamera ist Mira. Der Gast sieht in die Kamera, also den Lerner an. Das bisherige
Verbot von Nahaufnahmen (Spec 2.10. §6.1) gilt für die Ansprache-Bilder nicht.

## 1. Ziel und Nicht-Ziele

**Ziel:** Jede Station fühlt sich an wie ein Gegenüber, das mit dir redet: Gast
bildschirmfüllend, Blick zu dir, Gesicht reagiert auf deine Antwort, Satz hörbar.
Jede Aufgabe sagt, was zu tun ist.

**Nicht-Ziele (hier):**

- Die vier Lichter für die Ansprache-Bilder (kommt mit Runde 2 der Café-Bilder).
- Vorproduzierte Tondateien (Stufe B der Stimme, später; §5 hält den Platz frei).
- Neue Inhalte der Stationen (Grammatik, Zeichen-Erklärung, Nachzeichnen): eigene
  Spec „Nachbereitung der Folge“ (16.10., `2026-10-16-cafe-nachbereitung-zeichen-design.md`).
- Stationen 3 und 4 (alter Mann, Gleichaltrige): bleiben Plan B, bekommen aber den
  neuen Rahmen und die Bilder aus dieser Spec geschenkt.
- Download-Paket für Bilder: bleibt wie in der Spec vom 2.10. ein späterer Schritt.

## 2. Bilder „Ansprache“

### 2.1 Umfang und Bildregel

4 Gäste × 3 Stimmungen × 5 Varianten = **60 Motive**, Licht Tag, je **hoch und quer**
= 120 Dateien, JPEG q88, grob 30 MB. Die App wird spürbar größer (Risiko §10).

| Gast | Stammplatz (Hintergrund) | fragend | zufrieden | abwinkend |
|---|---|---|---|---|
| Wirtin | Tresen | warm, Augenbrauen hoch, Mund offen wie beim Sprechen | Lächeln, Nicken | Kopf leicht schief, Hand hebt kurz ab, freundlich |
| Schulmädchen | Nische mit Heften | frech, Kinn vor, Mund offen | Grinsen, Daumen oder Faust | Augen verdreht, Hand winkt ab |
| Alter Mann | Zeitung am Fenster | brummig, Blick über die Zeitung | zufriedenes Brummen, Nicken | Zeitung sinkt, Stirn gerunzelt |
| Gleichaltrige | Kaffeetasse | gleichgültig-freundlich, fragender Blick | kurzes Lächeln | Schulterzucken |

Regeln für jedes Bild:

- **Blick in die Kamera.** Halbnah: Kopf bis Hüfte. Die Figur allein, keine zweite
  Person (Mira bleibt hinter der Kamera).
- **Hoch:** Gesicht in der oberen Hälfte des Bildes; die untere Hälfte ist Raum,
  Tisch, Tresen — dort liegt später die Fläche.
- **Quer:** Figur in der linken Hälfte; rechts Raum — dort liegt die Fläche.
- Stil, Serienregeln und Figurenbeschreibungen wie die Panels und die Café-Motive
  (Look A → Manga D70; feste Figurenbeschreibungen aus `cafe_motifs.py`).
- Hoch und quer sind **zwei eigene Erzeugungen** derselben Nummer, kein Beschnitt.
  Dreht man das Handy mitten in einer Aufgabe, erscheint dieselbe Nummer im anderen
  Format: derselbe Gast, dieselbe Stimmung, ein anderes Bild. Das ist in Ordnung.

### 2.2 Erzeugung (`tool/comic/cafe_ansprache.py`)

1. **fragend** je Gast und Format als Text-zu-Bild im Foto-Look (quer 1664 × 928,
   hoch 928 × 1664; feste Seeds), dann Manga-Durchgang D70 (`manga_graph`), dann
   Auslieferungsgröße (quer 1920 × 1072, hoch 1080 × 1936) wie `folge01_finish.py`.
2. **zufrieden** und **abwinkend** je als **Bearbeitung des fertigen fragend-Fotos**
   mit dem Edit-Modell (Prompt: nur Gesichtsausdruck, Kopfhaltung, Hand ändern; Kleidung,
   Licht, Hintergrund, Bildausschnitt gleich), danach derselbe Manga-Durchgang. So
   bleibt beim Wechsel im Bildschirm dieselbe Person in derselben Haltung, nur das
   Gesicht ändert sich.
3. **Bögen** über `make_sheets.py`/`sheet.py`: je Gast und Stimmung ein Bogen mit
   Nummer, Seed und Format. Picks und Streichungen in `picks_ansprache.txt`,
   Nachbesserungen in `overrides_ansprache.txt` (Muster wie `picks_foto.txt`).
4. README-Abschnitt „Café-Ansprache“ mit Rezept, Seeds, Laufzeiten.

Tests in `tool/comic/test_ansprache.py`: Prompt-Tabelle vollständig (4 × 3 × beide
Formate), Dateinamen aus (Gast, Stimmung, Nummer, Format) eindeutig, Picks-Datei
parst und verweist nur auf vorhandene Kandidaten.

### 2.3 Ulis Anteil: Gate und zwei Runden

- **Gate:** Wirtin, ein fragend-Bild plus seine zwei Bearbeitungen, beide Formate, zwei
  Seeds, ein Bogen. Uli sagt ja oder nein zu Blick, Nähe, Stil, Bearbeitungsweg.
- **Runde 1 (fragend):** je Gast **acht** Kandidaten je Format. Uli streicht; fünf
  bleiben. Bleiben weniger, rendert Claude mit neuen Seeds nach.
- **Runde 2 (zufrieden, abwinkend):** Bearbeitungen der fünf gewählten fragend-Bilder,
  je Gast ein Bogen (5 × 2 × 2 Formate). Uli streicht; Claude bessert mit anderem Seed
  oder Prompt nach, bis jede Zelle voll ist.

### 2.4 Ablage und Bibliothek in der App

- Dateien: `assets/comic/cafe/ansprache/{gast}_{stimmung}_{n}_{format}.jpg` mit
  `gast` ∈ wirtin, schulkind, vielredner, gleichaltrige; `stimmung` ∈ fragend,
  zufrieden, abwinkend; `n` 1–5; `format` ∈ quer, hoch. Beispiel:
  `schulkind_abwinkend_3_hoch.jpg`.
- `lib/features/cafe/cafe_portraits.dart`: `enum CafeMood { fragend, zufrieden,
  abwinkend }`; `portraitAsset(guest, mood, n, format)`; Tabelle
  `cafePortraitLibrary` führt je (Gast, Stimmung), **welche Nummern** in **welchen
  Formaten** vorliegen; `portraitVariant(itemId, visitKey, available)` wählt die
  Nummer deterministisch (Hash aus Wort und Besuch, modulo Anzahl), damit Tests sie
  vorhersagen und die Nummer über beide Versuche gleich bleibt.
- **Rückfallkette:** gewünschte (Stimmung, Nummer, Format) → dieselbe Nummer in
  `fragend` → anderes Format eingepasst (Letterbox, nie verzerrt) → Stammplatz-Szene
  aus `cafe_scenes.dart` → neutrale dunkle Fläche. Nie ein Absturz, nie ein leerer
  Schirm. Während der Bildrunden läuft die App mit dieser Kette.
- Strukturtest: jede Tabellenzeile hat ihre Datei, jede Datei ihre Zeile; die Tabelle
  darf unvollständig sein (Runden laufen), aber nie auf Dateien zeigen, die fehlen.

## 3. Bildschirm

### 3.1 Vollbild

`CafeVisitScreen` ruft beim Betreten `ReaderSystemUi.enterImmersive()` und beim
Verlassen `exitImmersive()` (derselbe injizierbare Adapter wie im Reader; der Übergang
Endkarte → Café bleibt im Vollbild). Beide Handylagen; `OrientationBuilder` wählt das
Format. Keine Kopfleiste (`AppBar`) mehr im Café; Zurück ist ein halbdurchsichtiger
Chip oben links über dem Bild (wie im Reader), Schlüssel `cafe-back`.

### 3.2 Die Fläche (`lib/features/cafe/cafe_overlay.dart`, Widget `CafeOverlay`)

- Dunkel, halbdurchsichtig, weiße Schrift (wie der Gedankenkasten des Readers).
- **Hoch:** unten, Breite voll, **Höhe höchstens die Hälfte** des Schirms. Ist der
  Inhalt höher (Kana-Tastatur, Laut-Kacheln), scrollt die Fläche innen; das Bild
  dahinter bleibt stehen.
- **Quer:** rechts, volle Höhe, Breite **ein Drittel, mindestens aber 360 dp** (die
  Kana-Tastatur passt auf 360 dp), höchstens die Hälfte. Die Figur steht links.
- Aufbau von oben: Blase (§3.3) · Lautsprecher-Symbol (§5.1) rechts in der Blasenzeile
  · Inhalt der Station (scrollt) · Knopfzeile unten: links „Später weiter“
  (`cafe-station-later`), rechts „Weiter“ (`cafe-station-next`).
- Die eingebaute Kana-Tastatur ist Teil des Inhalts, keine Systemtastatur; es gibt
  keinen `viewInsets`-Fall.

### 3.3 Die Blase (`GuestBubble`)

Oberste Zeile der Fläche: der Name des Gastes klein, darunter der Satz, Schlüssel
`cafe-station-voice`. Die Form ist eine helle Blase mit kleiner Spitze **nach oben**
(hoch) bzw. **nach links** (quer), zur Person hin. Sie liegt immer an derselben Stelle,
egal welche der fünf Varianten gezogen wurde; sie berührt nie das Gesicht (hoch: das
Gesicht ist in der oberen Bildhälfte, die Fläche in der unteren; quer: links/rechts).

### 3.4 Der Stationsrahmen (`StationFrame`, neu)

Eingaben: `station`, `mood` (§3.5), `variant` (Nummer), `line` (der Satz), `child`,
`onNext`, `nextLabel`, `onLater`. Aufbau: `Stack` mit dem Bild hinter allem
(`BoxFit.cover`; hoch oben verankert, quer links verankert; Schlüssel
`cafe-station-scene`), darüber Zurück-Chip und `CafeOverlay`. Die Schlüssel von Plan A
(`cafe-station-scene`, `cafe-station-voice`, `cafe-station-next`,
`cafe-station-later`) bleiben, damit die bestehenden Stationstests weiterlaufen; nur
der Kopfleisten-Titel entfällt (der Name steht in der Blase).

### 3.5 Stimmung und Reaktion

- Das Bild ist **fragend**, solange eine Antwort erwartet wird.
- Sobald eine Bewertung angezeigt wird, wechselt es: **zufrieden** bei richtig (auch
  im zweiten Versuch), **abwinkend** bei falsch oder nichts gehört. Das gilt auch für die
  Zwischenbewertung nach einem falschen ersten Versuch; beginnt der zweite Versuch,
  ist das Bild wieder fragend.
- Die **Nummer bleibt** über alle Versuche einer Aufgabe dieselbe; nur die Stimmung
  wechselt. Die nächste Aufgabe zieht eine neue Nummer (§2.4).
- Der Satz in der Blase wechselt mit: Aufgabe → Reaktionssatz (bestehende Texte der
  Stationen; die Wirtin behält ihre, das Schulmädchen bekommt die aus §4).

### 3.6 Raum und Abschluss (`CafeVisitScreen`)

| Bildschirm | Hinter der Fläche | In der Fläche |
|---|---|---|
| Raum | `leer` im Licht der Stunde, Vollbild | Blase der Wirtin („Setz dich …“), Reihe der Stationen mit Stammplatz-Miniaturen wie heute, Fortsetzen-Frage, Start |
| Leerzustand | `wirtin_tresen` | Satz der Wirtin, „trotzdem üben“ |
| Abschluss | Wirtin **zufrieden**, Nummer aus dem Besuch | Abschluss-Sätze wie heute (kein Zähler, INV-10), „Gehen“ |

Alle Schlüssel des Besuchs-Bildschirms bleiben.

## 4. Sprechen beim Schulmädchen: „Bedeutung → Sprechen“

Ersetzt „Sehen → Sprechen“ (Übungsraum §3.2). Der Wechsel gerade/ungerade mit
„Hören → Schreiben“ bleibt; Hören → Schreiben bleibt unverändert.

1. **Aufgabe:** Blase „Wie heißt ‚{Bedeutung}‘? Sag's.“ In der Fläche die deutsche
   Bedeutung groß (`meaningForConcept`, wie bei der Wirtin). Gibt es das Panel mit
   der Blase des Wortes, steht es klein darunter mit leerer Blase
   (`PanelWithBubble`, `blank`, quer, höchstens zwei Fünftel der Fläche) als
   Erinnerung an die Szene. Darunter Mikro („sagen“) und „lieber schreiben“ wie heute.
2. **Versuch 1:** Spracherkennung und Bewertung wie heute (`SttSpeakEvaluator`;
   leeres Ergebnis ist kein Versuch: „Ich hab nichts gehört. Schreib es lieber.“).
3. **Falsch:** Bild abwinkend, Blase „Nee. Hör zu: {Kana}. Jetzt du.“; sie spricht das
   Wort einmal japanisch vor (`TtsService.speak`); die Kana erscheinen groß in der
   Fläche unter der Bedeutung. Dann Bild fragend, **Versuch 2 = Nachsprechen**.
4. **Bewertung** unverändert: erster Versuch richtig `good` („Ha, gewusst!“), zweiter
   richtig `hard` („Siehst du, geht doch.“), beide falsch `again` („Das heißt {Kana}.
   Kommt wieder dran.“).

„lieber schreiben“ wechselt wie heute zur Kana-Tastatur; dann gilt die Bewertung des
Schreibens.

## 5. Gästestimme (Audio-Modus)

### 5.1 Schalter

- Einstellung `cafe_voice_enabled` (`shared_preferences`), Standard **an**. In
  `SettingsScreen` ein Schalter „Gäste sprechen“ mit Hinweis, wenn keine deutsche
  Stimme auf dem Gerät ist (§5.4).
- In der Blasenzeile der Fläche ein Lautsprecher-Symbol (`cafe-voice-toggle`), das
  denselben Wert umschaltet und speichert. Aus heißt sofort still.

### 5.2 Baustein `lib/features/cafe/cafe_voice.dart`

- `VoiceSegment(text, lang)` mit `lang` ∈ de, ja.
- `GuestVoiceProfile(pitch, rate, preferredVoice)`; Tabelle je `CafeGuest`:
  Wirtin 1,0 / normal; Schulmädchen 1,3 / schnell; alter Mann 0,8 / langsam;
  Gleichaltrige 1,1 / normal. (Bei `flutter_tts` auf Android ist Rate 0,5 das normale
  Tempo; schnell 0,6, langsam 0,4.)
- `abstract class VoiceSource { Future<void> speak(List<VoiceSegment>, GuestVoiceProfile);
  Future<void> stop(); Future<bool> hasGerman(); }`
  - `DeviceTtsSource`: nutzt `TtsService` (bestehend; bekommt `setLanguage`,
    `setPitch`, `setRate`, `awaitCompletion` als Erweiterung). Spricht die Stücke
    nacheinander, jedes in seiner Sprache, mit dem Profil des Gastes. Hat das Gerät
    mehrere deutsche Stimmen, ordnet es je Gast eine feste zu (weiblich für Wirtin,
    Schulmädchen, Gleichaltrige; männlich für den alten Mann, erkannt am Stimmnamen,
    sonst nach Reihenfolge); sonst eine Stimme und nur Tonhöhe/Tempo.
  - `ClipSource` (später, Stufe B): spielt Tondateien je Zeile; fehlt eine, Rückfall
    auf `DeviceTtsSource`. Hier nur als Schnittstelle vorgesehen, nicht gebaut.
- `CafeVoice` (Fassade, per Provider injiziert): `say(CafeGuest, String line)`,
  `stop()`, `enabled`. `say` zerlegt die Zeile (§5.3), stoppt eine laufende Ausgabe
  und spricht.

### 5.3 Zerlegung (`lib/features/cafe/voice_segments.dart`)

`splitSegments(String line) → List<VoiceSegment>`: Läufe aus Hiragana, Katakana,
Kanji und ー werden `ja`, alles andere `de`. Anführungszeichen und Satzzeichen bleiben
beim deutschen Stück; ein japanisches Stück trägt nur die Schrift. Beispiel:
„Nee. Hör zu: あめ. Jetzt du.“ → de „Nee. Hör zu:“ · ja „あめ“ · de „. Jetzt du.“
(die App spricht „Jetzt du“, das Satzzeichen ist stumm).

### 5.4 Regeln

- Gesprochen wird **jede Blasenzeile**, sobald sie erscheint: Aufgabe, Reaktion,
  Raum-Begrüßung, Abschluss-Sätze. Nicht gesprochen: Tasten, Kacheln, Bedeutung,
  Kana in der Fläche (die gehören zur Übung; die Wirtin spricht Wörter wie heute über
  `speak`/`speakSlow`, das bleibt).
- Eine neue Zeile unterbricht die alte (`stop`, dann `speak`).
- Vor dem Start der Spracherkennung ruft die Station `CafeVoice.stop()`; während
  `listening` wird nicht gesprochen. Nach der Erkennung spricht die Reaktion.
- Beim Verlassen einer Station oder des Cafés: `stop()`.
- Fehlt eine deutsche Stimme (`hasGerman()` false), schweigt die Gästestimme ohne
  Fehler; die Einstellung zeigt den Hinweis „Auf diesem Gerät ist keine deutsche
  Stimme installiert“. Die japanische Sprachausgabe der Übungen ist davon unberührt.
- Tests laufen mit einer `FakeVoiceSource`, die Aufrufe protokolliert.

## 6. Komponenten und Dateien

| Datei | Neu/Änderung | Aufgabe |
|---|---|---|
| `tool/comic/cafe_ansprache.py`, `test_ansprache.py`, `picks_ansprache.txt`, `overrides_ansprache.txt` | neu | Erzeugung, Bögen, Picks (§2.2) |
| `assets/comic/cafe/ansprache/*.jpg` | neu | 120 Bilder (§2.4) |
| `lib/features/cafe/cafe_portraits.dart` | neu | Stimmungen, Tabelle, Variante, Rückfall (§2.4) |
| `lib/features/cafe/cafe_overlay.dart` | neu | Fläche, Blase, Lautsprecher (§3.2, §3.3) |
| `lib/features/cafe/stations/station_frame.dart` | neu geschrieben | Vollbild-Rahmen (§3.4) |
| `lib/features/cafe/stations/wirtin_station.dart`, `schulmaedchen_station.dart` | Änderung | Stimmung je Zustand, Stimme, Sprechen nach §4 |
| `lib/features/cafe/cafe_visit_screen.dart` | Änderung | Vollbild, Raum und Abschluss in der Fläche (§3.1, §3.6) |
| `lib/features/cafe/cafe_voice.dart`, `voice_segments.dart` | neu | Gästestimme (§5) |
| `lib/core/tts_service.dart` | Erweiterung | Sprache, Tonhöhe, Tempo, Stimmenliste, Warten auf Ende |
| `lib/features/settings/settings_screen.dart` | Änderung | Schalter „Gäste sprechen“ |
| `pubspec.yaml` | Änderung | neuer Asset-Ordner |

Keine Änderung an der Datenbank.

## 7. Invarianten (Fortsetzung der Übungsraum-Spec)

- **INV-24** Jede Station zeigt den Gast bildschirmfüllend mit Blick zum Lerner; die
  Fläche verdeckt nie das Gesicht (hoch: höchstens die untere Hälfte; quer: rechts).
- **INV-25** Innerhalb einer Aufgabe bleibt die Bildnummer gleich; nur die Stimmung
  wechselt, und sie wechselt genau mit der Anzeige einer Bewertung.
- **INV-26** Die Gästestimme spricht nur Blasenzeilen, nie Antworten oder Kana der
  Übung; sie ist abschaltbar und schweigt, solange das Mikro aufnimmt.
- **INV-27** Jede Sprech-Aufgabe nennt, was zu sagen ist: die Bedeutung beim ersten
  Versuch, Kana und Vorsagen beim zweiten.
- INV-9 (die Stimm-Zeile verrät nie die Antwort) bleibt: „Wie heißt ‚Regen‘?“ nennt
  die Bedeutung, nicht das Wort; die Kana erscheinen erst nach dem Fehlversuch.

## 8. Tests

- **Fläche:** Widget-Tests mit Fenstergrößen hoch (1080 × 2340 bei 3×) und quer:
  Höhe ≤ halbe Höhe bzw. Breite = max(Drittel, 360 dp) ≤ Hälfte; Inhalt scrollt
  innen; Blase oben mit Spitze in der richtigen Richtung; Zurück-Chip vorhanden; keine
  AppBar.
- **Bilder:** `portraitVariant` deterministisch und stabil über Versuche; Rückfallkette
  Stufe für Stufe; Strukturtest der Bibliothek (unvollständig erlaubt, hängende Zeilen
  nicht).
- **Reaktion:** Wirtin und Schulmädchen zeigen fragend bei Aufgabe, zufrieden bei
  richtig, abwinkend bei falsch/nichts gehört, fragend wieder beim zweiten Versuch;
  Nummer unverändert.
- **Sprechen §4:** Bedeutung sichtbar, Kana nicht; nach Fehlversuch Vorsagen
  aufgerufen und Kana sichtbar; Bewertung good/hard/again wie heute; „lieber
  schreiben“ unverändert.
- **Stimme:** `splitSegments` (gemischte Sätze, nur deutsch, nur japanisch,
  Anführungszeichen); Profil je Gast; `say` stoppt vorher; Schalter aus = kein Aufruf;
  `stop` vor dem Mikro und beim Verlassen; `hasGerman` false = still, Hinweis in den
  Einstellungen; Reaktionssatz wird gesprochen.
- **Raum/Abschluss:** Vollbild betreten/verlassen über einen Fake-Adapter; Abschluss
  zeigt Wirtin zufrieden.
- **Pipeline:** `test_ansprache.py` (§2.2).
- Vollsuite grün (bis auf die bekannten Tokenizer-Tests), Emulator-Bogen je Station in
  beiden Lagen, S23-Gerätetest für Stimme, Mikro und Vollbild.

## 9. Pläne

- **Plan A2 — Ansprache-Bilder** (GPU-Box, `tool/comic`): Skript und Tests, Gate,
  Runde 1, Runde 2, Ablage und Bibliothekstabelle, Bögen für Uli. Wartezeiten liegen
  bei Ulis Picks; die App-Arbeit wartet nicht darauf.
- **Plan A3 — Vollbild, Sprechen, Stimme** (App): `CafeOverlay`, `StationFrame`,
  `cafe_portraits.dart` mit Rückfallkette, Stationen und Besuch umgestellt, Sprechen
  nach §4, Gästestimme, Einstellung, Tests, Vollsuite, Emulator, S23. Läuft mit den
  alten Stammplatz-Bildern als Platzhalter, bis Runde 1 da ist.
- Beide gestapelt auf #62 (`impl/cafe-uebungsraum-a`). **Plan B** (alter Mann,
  Gleichaltrige, Folge-01-Inhalte) kommt danach auf dem neuen Rahmen; die Spec
  „Nachbereitung der Folge“ (in Arbeit) kann Plan B erweitern.

## 10. Risiken und offene Punkte

- **Größe der App:** +30 MB Bilder. Bis zum Download-Paket in Kauf genommen (Uli weiß
  es). Sollte der Build über 200 MB gehen, zuerst die Qualität auf q82 senken.
- **Stimmen auf dem S23:** Welche deutschen Stimmen installiert sind (Samsung TTS,
  Google TTS) und wie sie mit Tonhöhe 0,8 bzw. 1,3 klingen, zeigt erst der
  Gerätetest. Klingt es albern, werden die Profile enger (0,9 bis 1,15).
- **Gemischte Sätze:** Der Wechsel zwischen deutscher und japanischer Stimme kostet je
  Stück eine kurze Pause. Stört das, wird der japanische Teil in Klammern stumm
  gelassen und nur die Übung spricht ihn.
- **Edit-Weg für Stimmungen:** Ob das Edit-Modell den Ausdruck sauber ändert, ohne das
  Gesicht zu verfremden, entscheidet das Gate. Fällt es durch, werden zufrieden und
  abwinkend als eigene Erzeugungen mit festem Seed gerendert (Haltung ähnlich, nicht
  gleich).
- Katakana auf der Tastatur und die Lichter bleiben spätere Schritte.

## 11. Abnahme

1. Emulator-Bogen: Wirtin und Schulmädchen je hoch und quer, je Aufgabe, Reaktion
   richtig, Reaktion falsch; Raum und Abschluss. Uli sieht Bildgröße, Fläche, Blase.
2. S23: eine Runde im Café mit Stimme an, dann aus; Sprechen mit Fehlversuch und
   Nachsprechen; Drehen des Handys mitten in einer Aufgabe.
3. Uli: „Die Person spricht mich an, ich weiß immer, was ich tun soll.“
