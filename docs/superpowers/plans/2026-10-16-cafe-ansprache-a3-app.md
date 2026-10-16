# Plan A3 — Das Café spricht dich an: Vollbild, Fläche, Sprechen, Gästestimme (App)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Jede Café-Station zeigt den Gast bildschirmfüllend mit Blick zum Lerner, die Übung in einer Fläche darüber, den Satz als Blase, hörbar über eine abschaltbare Gästestimme; das Sprechen beim Schulmädchen nennt die Bedeutung und beim zweiten Versuch die Kana.

**Architecture:** Drei neue Bausteine (`cafe_portraits.dart` Bildwahl mit Rückfallkette, `cafe_overlay.dart` Fläche und Blase, `cafe_voice.dart` Gästestimme mit austauschbarer Quelle) und ein neu geschriebener `StationFrame`, der Bild, Zurück-Chip und Fläche stapelt und die Blasenzeile spricht. Die Stationen liefern nur noch Stimmung, Zeile und Inhalt; der Besuchs-Bildschirm schaltet das Vollbild und nutzt denselben Rahmen für Raum und Abschluss. Ohne Ansprache-Bilder (Plan A2) läuft alles über die Rückfallkette mit den alten Stammplatz-Bildern.

**Tech Stack:** Flutter, flutter_tts 4.2, speech_to_text 7, shared_preferences, bestehende `TtsService`/`SttService`-Singletons, `ReaderSystemUi` aus dem Reader.

**Spec:** `docs/superpowers/specs/2026-10-15-cafe-ansprache-design.md` §3 (Bildschirm), §4 (Sprechen), §5 (Stimme), §6 (Dateien), §7 (Invarianten), §8 (Tests), §11 (Abnahme). Bilder: §2.4 (Tabelle, Rückfallkette).

## Global Constraints

- Fläche (Spec §3.2): hoch unten, volle Breite, Höhe **höchstens die Hälfte** des Schirms; quer rechts, volle Höhe, Breite `max(Drittel, 360 dp)`, höchstens die Hälfte. Farbe `Color(0xCC1A1D21)`, Schrift weiß. Blase (§3.3): cremefarben `Color(0xF2FFF8E7)` mit Rahmen `Color(0xFF444444)` wie die Reader-Blasen, dunkle Schrift, Spitze nach oben (hoch) bzw. links (quer).
- Bestehende Schlüssel bleiben: `cafe-station-scene`, `cafe-station-voice`, `cafe-station-next`, `cafe-station-later`, alle `wirtin-*`, `schul-*`, `cafe-visit-*`. Neu: `cafe-back`, `cafe-station-name`, `cafe-voice-toggle`, `cafe-overlay`, `schul-meaning`, `schul-kana`.
- Stimmung (Spec §3.5): `fragend`, solange eine Antwort erwartet wird (auch während das Mikro läuft); `zufrieden` bei richtig, `abwinkend` bei falsch oder nichts gehört, sobald eine Bewertung oder Zwischenbewertung angezeigt wird. Bildnummer je Aufgabe fest (INV-25).
- Stimme (Spec §5): Schlüssel `cafe_voice_enabled` in SharedPreferences, Standard `true`. Profile: Wirtin pitch 1,0 rate 0,5; Schulmädchen 1,3 / 0,6; alter Mann 0,8 / 0,4; Gleichaltrige 1,1 / 0,5. Gesprochen werden nur Blasenzeilen (INV-26). Vor dem Mikro `stop()`.
- Bedeutung über `meaningForConcept(found.concept.id, fallback: found.concept.glossKey)` wie in `wirtin_station.dart:117`.
- Tests: `flutter test --no-pub <datei>`; Fenstergröße in Widget-Tests über `tester.view.physicalSize`, `devicePixelRatio = 1.0`, `addTearDown(tester.view.reset)`; hoch = `Size(400, 1400)` wie `schulmaedchen_station_test`, quer = `Size(1400, 640)`.
- Build-Nummer für das S23 muss über 2012 liegen (`--build-number=2013`).

## Review Focus

1. Drehen des Handys mitten in einer Aufgabe: Nummer und Stimmung bleiben, nur das Format wechselt; nichts wird neu geladen (Task 5: Test mit Größenwechsel im selben Pump).
2. Gästestimme an, aber keine deutsche Stimme auf dem Gerät: Station läuft, nichts wird gesprochen, kein Fehler (Task 3: `hasGerman` false → `say` ruft `speak` nicht).
3. Schnelles Weiter, während die Stimme noch spricht: die alte Zeile wird gestoppt, die neue gesprochen, nicht beide (Task 3 und 5: Reihenfolge `stop` vor `speak` protokolliert).
4. Sprechen beim Schulmädchen ohne Panel (Wort nur gehört, nie in einer Blase): Bedeutung und Mikro erscheinen trotzdem, kein leeres Bild (Task 7).
5. Fläche in quer mit Kana-Tastatur: Breite ≥ 360 dp, Tastatur nicht abgeschnitten, Inhalt scrollt (Task 4: Test quer 1400 × 640 mit 400 dp hohem Kind).

---

### Task 1: Bildwahl mit Rückfallkette (`cafe_portraits.dart`)

**Files:**
- Create: `lib/features/cafe/cafe_portraits.dart`, `lib/features/cafe/cafe_portrait_library.g.dart` (nur falls nicht vorhanden, Inhalt unten), `assets/comic/cafe/ansprache/.gitkeep`
- Modify: `pubspec.yaml` (nach Z. 75 `- assets/comic/cafe/ansprache/`, nur falls nicht vorhanden)
- Test: `test/features/cafe/cafe_portraits_test.dart`, `test/features/cafe/cafe_portraits_assets_test.dart`

**Interfaces:**
- Consumes: `CafeGuest` (`cafe_occupancy.dart`), `PanelFormat { landscape, portrait }` (`story/episode.dart`), `cafeSceneLibrary`/`sceneAsset`/`stammplatzOf` (`cafe_scenes.dart`), `cafePortraitFiles` aus der `.g.dart`:

  ```dart
  // GENERIERT von tool/comic/gen_portraits_dart.py — nicht von Hand ändern.
  /// Vorhandene Ansprache-Bilder: '{gast}_{stimmung}' → Format → Nummern.
  const Map<String, Map<String, List<int>>> cafePortraitFiles = {};
  ```
- Produces:
  - `enum CafeMood { fragend, zufrieden, abwinkend }`
  - `const String cafePortraitDir = 'assets/comic/cafe/ansprache';`
  - `String portraitStem(CafeGuest g)` → `wirtin`, `schulkind`, `vielredner`, `gleichaltrige` (= `CafeGuest.name`).
  - `String formatKey(PanelFormat f)` → `quer` für landscape, `hoch` für portrait.
  - `String portraitPath(CafeGuest g, CafeMood m, int n, PanelFormat f)` → `'$cafePortraitDir/${stem}_${m.name}_${n}_${formatKey(f)}.jpg'`.
  - `List<int> availableVariants(Map<String, Map<String, List<int>>> files, CafeGuest g, CafeMood m, PanelFormat f)`.
  - `int portraitVariant(String itemId, String visitKey, int available)` → 1…available, deterministisch (`('$itemId|$visitKey'.hashCode.abs() % available) + 1`); `available <= 0` → 1.
  - `class PortraitChoice { final String asset; final bool letterbox; final bool isPortrait; }` (`isPortrait` false = Stammplatz-Szene oder Fläche).
  - `PortraitChoice? resolvePortraitIn(files, CafeGuest g, CafeMood m, int n, PanelFormat f)`: Kette gewünscht → `fragend` gleiche Nummer gleiches Format → gewünscht im anderen Format (`letterbox: true`) → `fragend` anderes Format (`letterbox: true`) → `null`.
  - `PortraitChoice resolvePortrait(CafeGuest g, CafeMood m, int n, PanelFormat f, CafeLight light, {Map<String, Map<String, List<int>>> files = cafePortraitFiles})`: wie oben mit `files`, bei `null` → `PortraitChoice(asset: sceneAsset(stammplatzOf(g), light), letterbox: true, isPortrait: false)`.

- [ ] **Step 1: Write the failing tests** (`cafe_portraits_test.dart`; `files` als lokale Tabelle im Test):

```dart
test('portraitPath baut den Namen aus Gast, Stimmung, Nummer, Format', () {
  expect(portraitPath(CafeGuest.schulkind, CafeMood.abwinkend, 3, PanelFormat.portrait),
      'assets/comic/cafe/ansprache/schulkind_abwinkend_3_hoch.jpg');
});
test('portraitVariant ist deterministisch, 1-basiert und stabil', () {
  final a = portraitVariant('lex_ja_ame', 'folge_01', 5);
  expect(a, portraitVariant('lex_ja_ame', 'folge_01', 5)); expect(a, inInclusiveRange(1, 5));
  expect(portraitVariant('x', 'y', 0), 1);
});
test('Rückfallkette: Stimmung → fragend → anderes Format → null', () {
  final files = {'wirtin_fragend': {'quer': [1, 2], 'hoch': [1]}, 'wirtin_zufrieden': {'quer': [1]}};
  expect(resolvePortraitIn(files, CafeGuest.wirtin, CafeMood.zufrieden, 1, PanelFormat.landscape)!.asset, endsWith('wirtin_zufrieden_1_quer.jpg'));
  expect(resolvePortraitIn(files, CafeGuest.wirtin, CafeMood.zufrieden, 2, PanelFormat.landscape)!.asset, endsWith('wirtin_fragend_2_quer.jpg'));
  final other = resolvePortraitIn(files, CafeGuest.wirtin, CafeMood.zufrieden, 1, PanelFormat.portrait)!;
  expect(other.asset, endsWith('wirtin_zufrieden_1_quer.jpg')); expect(other.letterbox, isTrue);
  expect(resolvePortraitIn(files, CafeGuest.vielredner, CafeMood.fragend, 1, PanelFormat.portrait), isNull);
});
test('resolvePortrait fällt auf die Stammplatz-Szene zurück', () {
  final c = resolvePortrait(CafeGuest.vielredner, CafeMood.fragend, 1, PanelFormat.portrait, CafeLight.tag);
  expect(c.isPortrait, isFalse); expect(c.asset, sceneAsset(CafeMotif.vielrednerZeitung, CafeLight.tag));
});
```

`cafe_portraits_assets_test.dart` nach dem Muster von `cafe_scenes_assets_test.dart`: jede Zeile in `cafePortraitFiles` hat ihre Datei unter `assets/comic/cafe/ansprache/` (`File(...).existsSync()`), und jede `.jpg` im Ordner steht in der Tabelle (unvollständige Tabelle erlaubt, hängende Zeilen nicht).

- [ ] **Step 2: Run** `flutter test --no-pub test/features/cafe/cafe_portraits_test.dart` → FAIL (Datei fehlt)
- [ ] **Step 3: Implement** `cafe_portraits.dart`; `.g.dart` mit leerer Tabelle anlegen, falls Plan A2 sie nicht schon angelegt hat; `.gitkeep` und pubspec-Eintrag ebenso.
- [ ] **Step 4: Run** beide Testdateien → PASS; `flutter analyze --no-pub` ohne neue Meldungen.
- [ ] **Step 5: Commit** `feat(cafe): Ansprache-Bilder — Tabelle, Variante, Rückfallkette`

### Task 2: Zerlegung der Zeilen und Stimmprofile

**Files:**
- Create: `lib/features/cafe/voice_segments.dart`, `lib/features/cafe/cafe_voice.dart` (Datenteil)
- Test: `test/features/cafe/voice_segments_test.dart`

**Interfaces:**
- Produces:
  - `enum VoiceLang { de, ja }`; `class VoiceSegment { final String text; final VoiceLang lang; }` (const, `==`/`hashCode`, `toString`).
  - `List<VoiceSegment> splitSegments(String line)`: Läufe aus Hiragana (U+3041–U+309F), Katakana (U+30A0–U+30FF), Kanji (U+4E00–U+9FFF) und `ー` werden `ja`; alles andere `de`. Japanische Stücke tragen nur die Schrift (keine Anführungszeichen, keine Satzzeichen); deutsche Stücke werden getrimmt; leere Stücke entfallen; ein deutsches Stück, das nur aus Satzzeichen besteht, entfällt.
  - `class GuestVoiceProfile { final double pitch; final double rate; }` (const); `GuestVoiceProfile profileFor(CafeGuest g)` mit den Werten aus Global Constraints.

- [ ] **Step 1: Write the failing tests**

```dart
test('gemischter Satz', () => expect(splitSegments('Nee. Hör zu: あめ. Jetzt du.'),
    [VoiceSegment('Nee. Hör zu:', VoiceLang.de), VoiceSegment('あめ', VoiceLang.ja), VoiceSegment('Jetzt du.', VoiceLang.de)]));
test('nur deutsch', () => expect(splitSegments('Setz dich.'), [VoiceSegment('Setz dich.', VoiceLang.de)]));
test('nur japanisch mit Dehnungsstrich', () => expect(splitSegments('コーヒー'), [VoiceSegment('コーヒー', VoiceLang.ja)]));
test('Anführungszeichen bleiben beim deutschen Stück', () => expect(splitSegments('Wie heißt ‚Regen‘? Sag\'s.'), [VoiceSegment('Wie heißt ‚Regen‘? Sag\'s.', VoiceLang.de)]));
test('Kanji zählt japanisch', () => expect(splitSegments('Das Schild sagt 駅.'), [VoiceSegment('Das Schild sagt', VoiceLang.de), VoiceSegment('駅', VoiceLang.ja)]));
test('Profile', () { expect(profileFor(CafeGuest.schulkind), const GuestVoiceProfile(pitch: 1.3, rate: 0.6)); expect(profileFor(CafeGuest.vielredner).pitch, 0.8); });
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** beide Dateien (Profil-Tabelle in `cafe_voice.dart`).
- [ ] **Step 4: Run** → PASS
- [ ] **Step 5: Commit** `feat(cafe): Gästestimme — Zerlegung in Sprachstücke, Stimmprofile`

### Task 3: Gästestimme — Quelle, Fassade, Einstellung, TtsService-Erweiterung

**Files:**
- Modify: `lib/core/tts_service.dart`, `lib/features/cafe/cafe_voice.dart`
- Test: `test/features/cafe/cafe_voice_test.dart`

**Interfaces:**
- Produces in `cafe_voice.dart`:
  - `abstract class SpeechEngine { Future<bool> setLanguage(String locale); Future<void> setPitch(double v); Future<void> setRate(double v); Future<void> speakAndWait(String text); Future<void> stop(); Future<List<String>> voiceNamesFor(String langPrefix); Future<void> setVoiceByName(String name); }`
  - `abstract class VoiceSource { Future<void> speak(List<VoiceSegment> segments, GuestVoiceProfile profile, CafeGuest guest); Future<void> stop(); Future<bool> hasGerman(); }`
  - `class DeviceTtsSource implements VoiceSource { DeviceTtsSource(SpeechEngine engine); }`: `speak` setzt je Stück `setLanguage('de-DE')` bzw. `'ja-JP'`, `setPitch(profile.pitch)`, `setRate(profile.rate)`, dann `speakAndWait`; eine neue `speak`-Anfrage bricht eine laufende ab (Laufnummer: Stücke einer überholten Anfrage werden nicht mehr gesprochen). `hasGerman` = `setLanguage('de-DE')` liefert true und `voiceNamesFor('de')` ist nicht leer; Ergebnis wird gemerkt. Stimmenwahl: gibt es ≥ 2 deutsche Stimmen, bekommt `vielredner` die erste, deren Name `male`/`männlich`/`#male` enthält, sonst die zweite; die übrigen Gäste die erste; `setVoiceByName` vor dem Sprechen des deutschen Stücks; nach einem japanischen Stück bleibt die japanische Stimmwahl dem `TtsService` überlassen (wie heute).
  - `class CafeVoicePrefs { static const key = 'cafe_voice_enabled'; Future<bool> isEnabled(); Future<void> setEnabled(bool v); }` über `SharedPreferences.getInstance()`, Standard `true`.
  - `class CafeVoice { CafeVoice({required VoiceSource source, required Future<bool> Function() isEnabled}); CafeVoice.silent(); Future<void> say(CafeGuest guest, String line); Future<void> stop(); }`: `say` → `isEnabled()` false → nichts; `source.hasGerman()` false → nichts; sonst `stop()` dann `source.speak(splitSegments(line), profileFor(guest), guest)`; leere Zerlegung → nichts. `CafeVoice.silent()` spricht nie, `stop` ist ein No-op.
- Produces in `tts_service.dart`: `class TtsService implements SpeechEngine` mit den sechs Methoden; `setLanguage` nutzt `_tts.setLanguage` + `isLanguageAvailable`; `speakAndWait` setzt `awaitSpeakCompletion(true)` einmalig und ruft `speak`; `voiceNamesFor` filtert `getVoices` nach `locale` beginnt mit Präfix; bestehende Methoden unverändert (`init`, `speak`, `speakSlow`, `stop`, `setLocale`).

- [ ] **Step 1: Write the failing tests** (`FakeSpeechEngine` protokolliert Aufrufe als Strings: `lang:de-DE`, `pitch:1.3`, `rate:0.6`, `voice:X`, `speak:…`, `stop`; `FakeVoiceSource` protokolliert `speak(segments, guest)`/`stop`, `german` schaltbar):

```dart
test('DeviceTtsSource spricht Stücke mit Sprache und Profil', () async {
  await src.speak(splitSegments('Hör zu: あめ. Jetzt du.'), profileFor(CafeGuest.schulkind), CafeGuest.schulkind);
  expect(engine.log, ['lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Hör zu:', 'lang:ja-JP', 'pitch:1.3', 'rate:0.6', 'speak:あめ', 'lang:de-DE', 'pitch:1.3', 'rate:0.6', 'speak:Jetzt du.']);
});
test('neue Anfrage überholt die alte', () async { /* engine.speakAndWait wartet auf Completer; zweites speak → erstes bricht nach dem laufenden Stück ab */ });
test('hasGerman false ohne deutsche Stimme', () async { engine.languages = {'ja-JP'}; expect(await src.hasGerman(), isFalse); });
test('alter Mann bekommt die männliche Stimme', () async { engine.voices = {'de': ['de-DE-x-female', 'de-DE-x-male']}; await src.speak([VoiceSegment('Na.', VoiceLang.de)], profileFor(CafeGuest.vielredner), CafeGuest.vielredner); expect(engine.log, contains('voice:de-DE-x-male')); });
test('CafeVoice: aus → nichts; kein Deutsch → nichts; sonst stop dann speak', () async {
  final v = CafeVoice(source: fake, isEnabled: () async => false); await v.say(CafeGuest.wirtin, 'Setz dich.'); expect(fake.log, isEmpty);
  fake.german = false; final v2 = CafeVoice(source: fake, isEnabled: () async => true); await v2.say(CafeGuest.wirtin, 'Setz dich.'); expect(fake.log, isEmpty);
  fake.german = true; await v2.say(CafeGuest.wirtin, 'Setz dich.'); expect(fake.log, ['stop', 'speak:[Setz dich.|de] wirtin']);
});
test('CafeVoicePrefs Standard an, speichert aus', () async { SharedPreferences.setMockInitialValues({}); expect(await CafeVoicePrefs().isEnabled(), isTrue); await CafeVoicePrefs().setEnabled(false); expect(await CafeVoicePrefs().isEnabled(), isFalse); });
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** `cafe_voice.dart` komplett und die `SpeechEngine`-Methoden im `TtsService` (keine Tests für die Plattformaufrufe; `flutter analyze` prüft die Schnittstelle).
- [ ] **Step 4: Run** → PASS; `flutter analyze --no-pub` sauber.
- [ ] **Step 5: Commit** `feat(cafe): Gästestimme — Gerätequelle, Fassade, Einstellung, TtsService-Erweiterung`

### Task 4: Fläche und Blase (`cafe_overlay.dart`)

**Files:**
- Create: `lib/features/cafe/cafe_overlay.dart`
- Test: `test/features/cafe/cafe_overlay_test.dart`

**Interfaces:**
- Produces:
  - `enum TailDirection { up, left }`
  - `class GuestBubble extends StatelessWidget { GuestBubble({required String name, required String line, required TailDirection tail, Widget? trailing}); }`: Name klein (`cafe-station-name`), Zeile (`cafe-station-voice`), cremefarben mit Rahmen, Spitze gezeichnet per `CustomPaint`; `trailing` rechts in der Namenszeile (Lautsprecher).
  - `class CafeOverlay extends StatelessWidget { CafeOverlay({required Widget bubble, required Widget child, Widget? bottom}); }`: liest `MediaQuery.orientationOf`; hoch: `Align(bottomCenter)` + `ConstrainedBox(maxHeight: höhe/2)`; quer: `Align(centerRight)` + Breite `max(breite/3, 360).clamp(…, breite/2)`, volle Höhe; Hintergrund `Color(0xCC1A1D21)`, `DefaultTextStyle` weiß; innen `Column(bubble, Expanded(SingleChildScrollView(child)), bottom?)`; Schlüssel `cafe-overlay`.
  - `class CafeBackChip extends StatelessWidget { CafeBackChip({required VoidCallback onPressed}); }`: Optik wie `_BackChip` im Reader (`Color(0x99000000)`, Kreis, weißer Pfeil, Tooltip „Zurück“), Schlüssel `cafe-back`; Position oben links mit `SafeArea`.
  - `TailDirection tailFor(Orientation o)` → up bei portrait, left bei landscape.

- [ ] **Step 1: Write the failing tests** (Pump mit `MaterialApp(home: Scaffold(body: Stack(children: [Container(), CafeOverlay(...)])))`):

```dart
testWidgets('hoch: unten, volle Breite, höchstens halbe Höhe, Spitze nach oben', (t) async {
  t.view.physicalSize = const Size(400, 1400); t.view.devicePixelRatio = 1.0; addTearDown(t.view.reset);
  await t.pumpWidget(app(child: const SizedBox(height: 2000)));
  final r = t.getRect(find.byKey(const ValueKey('cafe-overlay')));
  expect(r.width, 400); expect(r.height, lessThanOrEqualTo(700)); expect(r.bottom, 1400);
  expect(find.byType(SingleChildScrollView), findsOneWidget);
});
testWidgets('quer: rechts, mindestens 360 dp breit, höchstens halb, volle Höhe, Inhalt scrollt', (t) async {
  t.view.physicalSize = const Size(1400, 640); /* … */ await t.pumpWidget(app(child: const SizedBox(height: 2000)));
  final r = t.getRect(find.byKey(const ValueKey('cafe-overlay')));
  expect(r.right, 1400); expect(r.height, 640); expect(r.width, closeTo(466.7, 1)); // 1400/3 > 360
});
testWidgets('quer schmal: Breite wird auf 360 angehoben', (t) async { t.view.physicalSize = const Size(800, 400); /* … */ expect(r.width, 360); });
testWidgets('Blase zeigt Name und Zeile', (t) async { /* find.byKey name/voice; Text-Inhalt */ });
testWidgets('Zurück-Chip ruft onPressed', (t) async { /* tap cafe-back → Zähler 1 */ });
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** `cafe_overlay.dart`.
- [ ] **Step 4: Run** → PASS
- [ ] **Step 5: Commit** `feat(cafe): Fläche, Blase und Zurück-Chip für das Vollbild-Café`

### Task 5: Stationsrahmen neu (`StationFrame`)

**Files:**
- Modify: `lib/features/cafe/stations/station_frame.dart` (neu geschrieben)
- Test: `test/features/cafe/station_frame_test.dart` (neu)

**Interfaces:**
- Consumes: Task 1 (`resolvePortrait`, `CafeMood`), Task 3 (`CafeVoice`), Task 4 (`CafeOverlay`, `GuestBubble`, `CafeBackChip`, `tailFor`), `stationTitles`, `guestOf`, `CafeLight`, `PanelFormat`.
- Produces:
  - `class StationFrame extends StatefulWidget { StationFrame({required CafeStation station, required CafeLight light, required CafeMood mood, required int variant, required String line, required Widget child, required VoidCallback? onNext, String nextLabel = 'Weiter', VoidCallback? onLater, CafeVoice? voice, Widget? bubbleTrailing, Map<String, Map<String, List<int>>> files = cafePortraitFiles}); }` — `files` nur für Tests einspeisbar, geht an `resolvePortrait`.
  - Aufbau: `Scaffold(body: Stack)` ohne AppBar: `Positioned.fill(Image.asset(choice.asset, key: 'cafe-station-scene', fit: letterbox ? BoxFit.contain : BoxFit.cover, alignment: hoch ? topCenter : centerLeft, errorBuilder → Container(0xFF2A3035)))`, dunkler Grund hinter Letterbox; `CafeBackChip(onPressed: Navigator.maybePop)`; `CafeOverlay(bubble: GuestBubble(name: stationTitles[station], line, tail: tailFor(orientation), trailing: bubbleTrailing), child, bottom: Knopfzeile mit cafe-station-later / cafe-station-next wie heute)`.
  - Format: `MediaQuery.orientationOf(context) == portrait ? PanelFormat.portrait : PanelFormat.landscape`.
  - Sprechen: in `initState` und in `didUpdateWidget`, wenn `line` sich ändert → `voice?.say(guestOf(station), line)`; in `dispose` → `voice?.stop()`.
  - `typedef Speak`, `stationTitles`, `guestOf` bleiben in der Datei.

- [ ] **Step 1: Write the failing tests** (`FakeVoice` = `CafeVoice` mit `FakeVoiceSource` aus Task 3, Protokoll über die Quelle; Pump `MaterialApp(home: StationFrame(...))`):

```dart
testWidgets('keine AppBar, Bild füllt den Schirm, Fläche und Blase da', (t) async { /* find.byType(AppBar) findsNothing; cafe-station-scene Rect == Schirm; cafe-overlay, cafe-station-voice mit Zeile, cafe-station-name 'Die Wirtin', cafe-back */ });
testWidgets('Stimmung ändert das Bild, Nummer bleibt', (t) async {
  final files = {'wirtin_fragend': {'hoch': [1, 2, 3]}, 'wirtin_zufrieden': {'hoch': [1, 2, 3]}};
  String asset() => (t.widget<Image>(find.byKey(const ValueKey('cafe-station-scene'))).image as AssetImage).assetName;
  await pump(mood: CafeMood.fragend, variant: 2, files: files); expect(asset(), endsWith('wirtin_fragend_2_hoch.jpg'));
  await pump(mood: CafeMood.zufrieden, variant: 2, files: files); expect(asset(), endsWith('wirtin_zufrieden_2_hoch.jpg'));
  await pump(mood: CafeMood.abwinkend, variant: 2, files: files); expect(asset(), endsWith('wirtin_fragend_2_hoch.jpg')); // Rückfall auf fragend
  await pump(mood: CafeMood.fragend, variant: 2, files: const {}); expect(asset(), sceneAsset(CafeMotif.wirtinTresen, CafeLight.tag)); // Stammplatz
});
testWidgets('Zeile wird beim Aufbau und bei Änderung gesprochen, dispose stoppt', (t) async {
  await pump(line: 'Setz dich.'); expect(fake.log, ['stop', 'speak:[Setz dich.|de] wirtin']);
  await pump(line: 'Genau so.'); expect(fake.log.last, 'speak:[Genau so.|de] wirtin');
  await pump(line: 'Genau so.'); expect(fake.log.length, 4); // gleiche Zeile → nicht erneut
  await t.pumpWidget(const SizedBox()); expect(fake.log.last, 'stop');
});
testWidgets('Drehen behält Zeile und Knöpfe, Fläche wechselt die Seite', (t) async { /* hoch → quer im selben Test, cafe-overlay Rect prüfen */ });
testWidgets('Später weiter und Weiter wie bisher', (t) async { /* Keys, onNext null → disabled */ });
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement** den Rahmen. Bestehende Stationstests laufen in diesem Task noch nicht (Signatur ändert sich); sie werden in Task 6/7 angepasst. Vorübergehend kompilieren die Stationen über Default-Werte: `mood = CafeMood.fragend`, `variant = 1`, `line` = bisheriges `voiceLine` — dazu in diesem Task in beiden Stationen nur den Parameternamen `voiceLine` → `line` umstellen und `mood`/`variant` mit festen Werten übergeben.
- [ ] **Step 4: Run** `station_frame_test`, `wirtin_station_test`, `schulmaedchen_station_test`, `cafe_visit_screen_test` → PASS (Tests, die eine AppBar oder einen 120-dp-Streifen erwarten, gibt es nicht; Tests mit `cafe-station-next` müssen das Scrollen in der Fläche nicht ändern, weil der Knopf unten fest steht).
- [ ] **Step 5: Commit** `feat(cafe): Stationsrahmen im Vollbild — Bild, Zurück-Chip, Fläche, Blase, Stimme`

### Task 6: Wirtin — Stimmung, Zeile, Variante, Mikro-Stopp

**Files:**
- Modify: `lib/features/cafe/stations/wirtin_station.dart`
- Test: `test/features/cafe/wirtin_station_test.dart`

**Interfaces:**
- Consumes: `StationFrame` (Task 5), `portraitVariant` (Task 1), `CafeVoice` (Task 3).
- Produces: Konstruktor erhält zusätzlich `CafeVoice voice = const CafeVoice.silent()` und `String visitKey = ''`. Zustände → Stimmung: `_listening` → fragend; `_feedback == null` → fragend; `_succeeded` → zufrieden; sonst abwinkend. Zeile: `_feedback ?? 'Setz dich. Das hier hattest du in der Folge:'`. Variante: `portraitVariant(itemId, visitKey, 5)` je Wort, im State gemerkt beim Laden. Vor `evaluator.evaluate` → `await widget.voice.stop()`. Das Feedback-`Text` mit `wirtin-feedback` entfällt, die Zeile steht in der Blase (`cafe-station-voice`).

- [ ] **Step 1: Write the failing tests** (bestehende `pump` erweitern um `voice`):

```dart
testWidgets('Stimmung: fragend → zufrieden bei Erfolg', (t) async { /* Blase zeigt Opener; Mikro tippen mit Score 0.9 → cafe-station-voice 'Genau so.'; StationFrame.mood == zufrieden (find.byType(StationFrame) → widget.mood) */ });
testWidgets('Stimmung: abwinkend nach Fehlversuch, fragend beim zweiten Mikro', (t) async { /* Score 0.1 → 'Fast. …' + abwinkend; Mikro erneut (gated) → während listening fragend */ });
testWidgets('nichts gehört → abwinkend, zählt nicht', (t) async { /* Score -1 */ });
testWidgets('Variante bleibt über beide Versuche, nächstes Wort kann wechseln', (t) async { /* widget.variant vorher/nachher */ });
testWidgets('Stimme wird vor dem Mikro gestoppt und spricht das Feedback', (t) async { expect(fake.log, containsAllInOrder(['speak:[Setz dich. Das hier hattest du in der Folge:|de] wirtin', 'stop', 'speak:[Genau so.|de] wirtin'])); });
```

Bestehende Tests, die `wirtin-feedback` suchen, auf `cafe-station-voice` umstellen.

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `wirtin_station_test` → PASS
- [ ] **Step 5: Commit** `feat(cafe): Wirtin — Stimmung, Blasenzeile, feste Bildnummer, Stimme`

### Task 7: Schulmädchen — Bedeutung → Sprechen, Stimmung, Zeile

**Files:**
- Modify: `lib/features/cafe/stations/schulmaedchen_station.dart`
- Test: `test/features/cafe/schulmaedchen_station_test.dart`

**Interfaces:**
- Consumes: wie Task 6; `meaningForConcept`; `PanelWithBubble(mode: blank, format: landscape)`.
- Produces: Konstruktor zusätzlich `CafeVoice voice = const CafeVoice.silent()`, `String visitKey = ''`. `_Word` bekommt `meaning` (geladen wie in der Wirtin). Neue States `bool _showKana`, `bool _lastCorrect`, `int _variant`. `_kindFor`: ungerader Index → `seeSpeak` **auch ohne Panel** (Spec §4 Punkt 1: Panel nur, wenn es eins gibt).
  - Zeilen: hearWrite `'Hör zu und schreib es. Schnell!'`; seeSpeak `'Wie heißt ‚${meaning}‘? Sag\'s.'`; nach falschem 1. Versuch im seeSpeak `'Nee. Hör zu: ${reading}. Jetzt du.'` + `_showKana = true` + `_say(reading)`; nach falschem 1. Versuch im hearWrite wie heute `'Nee. Nochmal — aber richtig diesmal.'`; richtig 1 `'Ha, gewusst!'`, richtig 2 `'Siehst du, geht doch.'`, beide falsch `'Das heißt ${reading}. Kommt wieder dran.'`, nichts gehört `'Ich hab nichts gehört. Schreib es lieber.'`. Zeile = `_feedback ?? aufgabe`.
  - Stimmung: `_listening` → fragend; `_graded` → `_lastCorrect ? zufrieden : abwinkend`; `_feedback != null` (Zwischenbewertung) → abwinkend, außer `_typed.isNotEmpty` oder `_listening` → fragend; sonst fragend.
  - seeSpeak-Inhalt: `Text(meaning, key: 'schul-meaning', groß)`; `if (_showKana) Text(reading, key: 'schul-kana')`; Panel-Miniatur (`schul-panel`) nur wenn Panel und Blase vorhanden, Höhe höchstens 2/5 der Fläche (`FractionallySizedBox` oder `ConstrainedBox(maxHeight: 0.4 * flächeHöhe)` über `LayoutBuilder`); Mikro und „lieber schreiben“ wie heute. Vor `evaluator.evaluate` → `voice.stop()`. `schul-feedback` entfällt (Zeile in der Blase).

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('seeSpeak zeigt Bedeutung und Frage, keine Kana', (t) async { /* ids[1] mit Episode; schul-meaning 'Regen'; cafe-station-voice "Wie heißt ‚Regen‘? Sag's."; schul-kana findsNothing */ });
testWidgets('falsch → Vorsagen, Kana sichtbar, abwinkend; zweiter Versuch richtig → hard', (t) async { /* Score 0.1 dann 0.9; speak-Log enthält reading nach dem Fehler; schul-kana findsOneWidget; Ergebnis in DB hard */ });
testWidgets('seeSpeak ohne Panel funktioniert', (t) async { /* Episode ohne Panel für das Wort: schul-panel findsNothing, schul-mic findsOneWidget */ });
testWidgets('hearWrite unverändert', (t) async { /* bestehender Test, Zeile 'Hör zu und schreib es. Schnell!' */ });
testWidgets('Stimmung fragend beim Tippen nach Fehlversuch', (t) async { /* hearWrite falsch → abwinkend; Kana tippen → fragend */ });
```

Bestehende Tests mit `schul-feedback` auf `cafe-station-voice` umstellen; Tests, die bei ungeradem Index ohne Panel `hearWrite` erwarten, auf das neue Verhalten anpassen.

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `schulmaedchen_station_test` → PASS
- [ ] **Step 5: Commit** `feat(cafe): Schulmädchen — Bedeutung → Sprechen mit Vorsagen und Kana, Stimmung, Stimme`

### Task 8: Besuchs-Bildschirm im Vollbild, Raum und Abschluss in der Fläche, Verdrahtung

**Files:**
- Modify: `lib/features/cafe/cafe_visit_screen.dart`, `lib/features/cafe/cafe_route.dart`
- Test: `test/features/cafe/cafe_visit_screen_test.dart`, `test/features/cafe/cafe_route_test.dart`

**Interfaces:**
- Consumes: `ReaderSystemUi`/`SystemChromeReaderUi` (`story/reader_system_ui.dart`), `RecordingSystemUi`-Muster aus `test/features/story/story_reader_fullscreen_test.dart:19`, Tasks 1–7.
- Produces: beide Konstruktoren erhalten `ReaderSystemUi systemUi = const SystemChromeReaderUi()`, `CafeVoice voice = const CafeVoice.silent()`; `initState` → `systemUi.enterImmersive()`, `dispose` → `systemUi.exitImmersive()` und `voice.stop()`. Stationen bekommen `voice` und `visitKey: visitId`. Keine AppBars mehr; alle drei Zweige als `Stack` mit Bild, `CafeBackChip` (pop) und `CafeOverlay`:
  - Raum: Bild `sceneAsset(CafeMotif.leer, _light)` (cover), Blase der Wirtin `'Setz dich. Wer ist heute da?'` (gesprochen), Inhalt = Gästereihe und Knöpfe wie heute (Keys bleiben).
  - Leerzustand: Bild `wirtin_tresen`, Blase `'Die Wirtin wischt den Tresen und nickt dir zu.'`, Knopf `cafe-visit-practice-anyway`.
  - Abschluss: Bild `resolvePortrait(CafeGuest.wirtin, CafeMood.zufrieden, portraitVariant('abschluss', visitId, 5), format, _light)`, Blase = erste Zeile von `summaryLines`, Inhalt = die übrigen Zeilen (`cafe-visit-summary-line-$i` bleibt, Zeile 0 in der Blase) und `cafe-visit-leave`.
- `cafe_route.dart`: baut `CafeVoice(source: DeviceTtsSource(TtsService.instance), isEnabled: CafeVoicePrefs().isEnabled)` einmal und übergibt `voice:`.

- [ ] **Step 1: Write the failing tests** (`afterEpisode()`-Wrapper um `systemUi: recorder`, `voice: fakeVoice` erweitern):

```dart
testWidgets('Vollbild beim Betreten, Ende beim Verlassen', (t) async { /* recorder.calls == ['enter']; Screen entfernen → ['enter','exit'] */ });
testWidgets('Raum ohne AppBar mit Bild, Blase und Start', (t) async { /* find.byType(AppBar) findsNothing; cafe-visit-room; cafe-station-voice 'Setz dich. Wer ist heute da?'; cafe-visit-start */ });
testWidgets('Abschluss zeigt Wirtin zufrieden und Zeilen', (t) async { /* nach Durchlauf: cafe-visit-summary, Zeile 0 in cafe-station-voice, cafe-visit-leave; Image asset endsWith wirtin_tresen_tag.jpg (Rückfall) */ });
testWidgets('Zurück-Chip verlässt das Café', (t) async { /* cafe-back → Navigator pop */ });
```

`cafe_route_test`: CafeRoute übergibt eine `CafeVoice` (Widget-Parameter prüfen).

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `cafe_visit_screen_test`, `cafe_route_test` → PASS
- [ ] **Step 5: Commit** `feat(cafe): Besuch im Vollbild — Raum und Abschluss in der Fläche, Stimme verdrahtet`

### Task 9: Schalter in den Einstellungen und in der Fläche

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`, `lib/features/cafe/stations/station_frame.dart` (Lautsprecher als `bubbleTrailing`-Standard)
- Test: `test/features/settings/settings_screen_test.dart` (anlegen, falls nicht vorhanden), `test/features/cafe/station_frame_test.dart`

**Interfaces:**
- Produces: `_GuestVoiceCard` nach dem Muster `_FuriganaCard` (Z. 251): Abschnitt `'Gäste im Café'`, `SwitchListTile(title: 'Gäste sprechen', key: 'settings-cafe-voice')`, liest/schreibt `CafeVoicePrefs`; Untertitel `'Auf diesem Gerät ist keine deutsche Stimme installiert.'`, wenn `DeviceTtsSource(TtsService.instance).hasGerman()` false liefert (asynchron, Standard leer). In `StationFrame`: `CafeVoiceToggle` (`cafe-voice-toggle`, `IconButton` volume_up/volume_off), liest `CafeVoicePrefs().isEnabled()` beim Aufbau, Tipp kehrt um, speichert und ruft bei „aus“ `voice?.stop()`; als Standard für `bubbleTrailing`, wenn `voice != null`.

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('Schalter speichert cafe_voice_enabled', (t) async { SharedPreferences.setMockInitialValues({}); /* pump SettingsScreen in ProviderScope; tap settings-cafe-voice → prefs false */ });
testWidgets('Lautsprecher in der Blase schaltet um und stoppt', (t) async { /* StationFrame mit voice; tap cafe-voice-toggle → prefs false, fake.log.last == 'stop'; Icon volume_off */ });
```

- [ ] **Step 2: Run** → FAIL
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS
- [ ] **Step 5: Commit** `feat(cafe): Gästestimme abschaltbar — Einstellungen und Lautsprecher in der Blase`

### Task 10: Vollsuite, Emulator-Bogen, S23, PR

**Files:** keine Code-Änderung außer Fixes.

- [ ] **Step 1:** `flutter analyze --no-pub` → 0 Fehler, keine neuen Warnungen gegenüber der Stapelspitze (7 alte unused imports).
- [ ] **Step 2:** `flutter test --no-pub` → alle grün bis auf die 8 bekannten Tokenizer-Tests (`test/mining_packs/ja/`).
- [ ] **Step 3:** Emulator (`~/bin/emu-nuc.sh`, Fahrweg aus `android-emulator-nuc`): APK `flutter build apk --debug --build-number=2013`, installieren, Folge 1 lesen bis ins Café; Screenshots hoch: Raum, Wirtin Aufgabe, Wirtin nach Erfolg, Schulmädchen Bedeutung → Sprechen, nach Fehlversuch (Kana), Abschluss; dann quer (`adb shell settings put system user_rotation 1` + `accelerometer_rotation 0`): Wirtin, Schulmädchen mit Tastatur. Bogen unter `~/cafe-a3-emulator.png` (Montage), Einzelbilder `~/cafe-a3-shots/`. Prüfen: Fläche ≤ halbe Höhe hoch, rechts quer ≥ 360 dp, Gesicht frei (mit Stammplatz-Bildern als Platzhalter ist das die alte Szene), keine Kopfleiste.
- [ ] **Step 4:** S23: `scp` der APK auf den Laptop, `adb -s RFCW220PB7W install -r`, auf `Success` prüfen, `dumpsys package com.softbrew.nihongo_app | grep versionCode` → 2013. Uli testet Stimme, Mikro, Drehen (Spec §11).
- [ ] **Step 5:** Draft-PR auf den Stapel (Basis: der Branch, auf dem der Plan ausgeführt wird), PR-Text mit Bogenpfad, Vollsuite-Zahlen, offenen Punkten (Stimmen auf dem S23, Bilder aus A2 ausstehend).
