import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the first-run onboarding flow has already been completed.
/// Overridden at boot in `main.dart` from the persisted `onboarding_complete`
/// SharedPreferences flag. Defaults to `false` so an un-overridden app
/// (e.g. in a test missing the override) safely routes to onboarding.
final onboardingCompleteProvider = Provider<bool>((_) => false);
