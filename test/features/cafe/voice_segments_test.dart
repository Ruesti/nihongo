import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/cafe/cafe_occupancy.dart';
import 'package:nihongo_app/features/cafe/cafe_voice.dart';
import 'package:nihongo_app/features/cafe/voice_segments.dart';

void main() {
  test('gemischter Satz', () => expect(splitSegments('Nee. Hör zu: あめ. Jetzt du.'),
      [VoiceSegment('Nee. Hör zu:', VoiceLang.de), VoiceSegment('あめ', VoiceLang.ja), VoiceSegment('Jetzt du.', VoiceLang.de)]));
  test('nur deutsch', () => expect(splitSegments('Setz dich.'), [VoiceSegment('Setz dich.', VoiceLang.de)]));
  test('nur japanisch mit Dehnungsstrich', () => expect(splitSegments('コーヒー'), [VoiceSegment('コーヒー', VoiceLang.ja)]));
  test('Anführungszeichen bleiben beim deutschen Stück', () => expect(splitSegments('Wie heißt ‚Regen‘? Sag\'s.'), [VoiceSegment('Wie heißt ‚Regen‘? Sag\'s.', VoiceLang.de)]));
  test('Kanji zählt japanisch', () => expect(splitSegments('Das Schild sagt 駅.'), [VoiceSegment('Das Schild sagt', VoiceLang.de), VoiceSegment('駅', VoiceLang.ja)]));
  test('leer und nur Satzzeichen', () {
    expect(splitSegments(''), isEmpty);
    expect(splitSegments(' ... '), isEmpty);
  });
  test('Profile', () {
    expect(profileFor(CafeGuest.schulkind), const GuestVoiceProfile(pitch: 1.3, rate: 0.6));
    expect(profileFor(CafeGuest.vielredner).pitch, 0.8);
    expect(profileFor(CafeGuest.wirtin), const GuestVoiceProfile(pitch: 1.0, rate: 0.5));
    expect(profileFor(CafeGuest.gleichaltrige), const GuestVoiceProfile(pitch: 1.1, rate: 0.5));
  });
}
