import 'cafe_occupancy.dart';

/// Stimmprofil eines Café-Gasts (Tonhöhe und Sprechtempo für die Sprachausgabe).
class GuestVoiceProfile {
  const GuestVoiceProfile({required this.pitch, required this.rate});

  final double pitch;
  final double rate;

  @override
  bool operator ==(Object other) =>
      other is GuestVoiceProfile && other.pitch == pitch && other.rate == rate;

  @override
  int get hashCode => Object.hash(pitch, rate);

  @override
  String toString() => 'GuestVoiceProfile(pitch: $pitch, rate: $rate)';
}

/// Das Stimmprofil des jeweiligen Gasts.
GuestVoiceProfile profileFor(CafeGuest g) => switch (g) {
  CafeGuest.wirtin => const GuestVoiceProfile(pitch: 1.0, rate: 0.5),
  CafeGuest.schulkind => const GuestVoiceProfile(pitch: 1.3, rate: 0.6),
  CafeGuest.vielredner => const GuestVoiceProfile(pitch: 0.8, rate: 0.4),
  CafeGuest.gleichaltrige => const GuestVoiceProfile(pitch: 1.1, rate: 0.5),
};
