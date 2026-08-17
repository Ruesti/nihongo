import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/knowledge_providers.dart';
import '../../core/pipeline/knowledge_bridge.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_prefs.dart';
import 'onboarding_providers.dart';
import 'placement_service.dart';

/// The one-time first-run reception, spoken by Datum (warmer register).
/// welcome → method → placement → (startpoint) → apply + finish.
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onFinished;
  final String languageId;
  final String languageCode;

  const OnboardingFlow({
    super.key,
    required this.onFinished,
    this.languageId = 'lang_ja',
    this.languageCode = 'ja',
  });

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

enum _Step { welcome, method, placement, startpoint }

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  _Step _step = _Step.welcome;
  bool _knowsHiragana = false;
  bool _knowsKatakana = false;

  Future<void> _finish({required bool fromZero}) async {
    final profile = PlacementProfile(
      fromZero: fromZero,
      knowsHiragana: _knowsHiragana,
      knowsKatakana: _knowsKatakana,
      knownWordLexemeIds: const [], // micro-check wiring is a later increment
    );
    final db = ref.read(learningDbProvider);
    final KnowledgeBridge? bridge = ref.read(knowledgeBridgeProvider);
    await PlacementService(db, bridge).apply(
      profile,
      languageId: widget.languageId,
      languageCode: widget.languageCode,
    );
    final prefs = await SharedPreferences.getInstance();
    await OnboardingPrefs(prefs).markComplete(profile);
    // Flip the session-live flag so the router's redirect sees completion
    // immediately — SharedPreferences alone only takes effect after an app
    // restart, which was the cause of the first-run redirect loop.
    ref.read(onboardingCompleteProvider.notifier).state = true;
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _Step.welcome => _WelcomeStep(
                title: l.welcomeTitle,
                body: l.welcomeBody,
                cta: l.continueLabel,
                onNext: () => setState(() => _step = _Step.method),
              ),
            _Step.method => _MethodStep(
                beats: [
                  l.methodEncounterFirst,
                  l.methodNoGamification,
                  l.methodOffline,
                ],
                cta: l.continueLabel,
                onNext: () => setState(() => _step = _Step.placement),
              ),
            _Step.placement => _PlacementStep(
                question: l.placementQuestion,
                fromZero: l.placementFromZero,
                knowSome: l.placementKnowSome,
                onFromZero: () => _finish(fromZero: true),
                onKnowSome: () => setState(() => _step = _Step.startpoint),
              ),
            _Step.startpoint => _StartpointStep(
                hiragana: l.placementHiragana,
                katakana: l.placementKatakana,
                cta: l.continueLabel,
                knowsHiragana: _knowsHiragana,
                knowsKatakana: _knowsKatakana,
                onHiragana: (v) => setState(() => _knowsHiragana = v),
                onKatakana: (v) => setState(() => _knowsKatakana = v),
                onDone: () => _finish(fromZero: false),
              ),
          },
        ),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final String title, body, cta;
  final VoidCallback onNext;
  const _WelcomeStep(
      {required this.title,
      required this.body,
      required this.cta,
      required this.onNext});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          FilledButton(onPressed: onNext, child: Text(cta)),
        ],
      );
}

class _MethodStep extends StatelessWidget {
  final List<String> beats;
  final String cta;
  final VoidCallback onNext;
  const _MethodStep(
      {required this.beats, required this.cta, required this.onNext});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final b in beats) ...[
            Text(b, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
          ],
          const Spacer(),
          FilledButton(onPressed: onNext, child: Text(cta)),
        ],
      );
}

class _PlacementStep extends StatelessWidget {
  final String question, fromZero, knowSome;
  final VoidCallback onFromZero, onKnowSome;
  const _PlacementStep(
      {required this.question,
      required this.fromZero,
      required this.knowSome,
      required this.onFromZero,
      required this.onKnowSome});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          FilledButton(onPressed: onFromZero, child: Text(fromZero)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onKnowSome, child: Text(knowSome)),
        ],
      );
}

class _StartpointStep extends StatelessWidget {
  final String hiragana, katakana, cta;
  final bool knowsHiragana, knowsKatakana;
  final ValueChanged<bool> onHiragana, onKatakana;
  final VoidCallback onDone;
  const _StartpointStep(
      {required this.hiragana,
      required this.katakana,
      required this.cta,
      required this.knowsHiragana,
      required this.knowsKatakana,
      required this.onHiragana,
      required this.onKatakana,
      required this.onDone});
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
              value: knowsHiragana,
              title: Text(hiragana),
              onChanged: onHiragana),
          SwitchListTile(
              value: knowsKatakana,
              title: Text(katakana),
              onChanged: onKatakana),
          const Spacer(),
          FilledButton(onPressed: onDone, child: Text(cta)),
        ],
      );
}
