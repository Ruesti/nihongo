import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the first-run onboarding flow has already been completed.
///
/// Initialized at boot in `main.dart` from the persisted `onboarding_complete`
/// SharedPreferences flag (`overrideWith` sets the initial state for a
/// `StateProvider`). Defaults to `false` so an un-overridden app (e.g. in a
/// test missing the override) safely routes to onboarding.
///
/// Session-live: a `StateProvider` (not a plain `Provider`) so
/// `OnboardingFlow` can flip it to `true` in-memory the moment onboarding
/// finishes, without waiting for an app restart to re-read SharedPreferences.
final onboardingCompleteProvider = StateProvider<bool>((_) => false);
