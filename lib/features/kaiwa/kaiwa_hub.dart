import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/feature_gate.dart';
import '../../core/theme.dart';
import '../../models/conversation.dart';
import '../home/home_screen.dart';
import 'conversation_screen.dart';
import 'shadowing_screen.dart';

class KaiwaHub extends ConsumerWidget {
  const KaiwaHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider('ja'));

    return Scaffold(
      appBar: AppBar(title: const Text('会話 — Gespräche')),
      body: progressAsync.when(
        data: (progress) {
          final unlocked = FeatureGate.isKaiwaUnlocked(
            progress.completedLessons,
            progress.totalCardsLearned,
          );

          if (!unlocked) {
            return _LockedView(
              completedLessons: progress.completedLessons,
              totalCards: progress.totalCardsLearned,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionLabel(context, 'SHADOWING'),
              const SizedBox(height: 8),
              ...shadowingClips
                  .where((c) => c.minLevel <= (progress.completedLessons + 1))
                  .map((c) => _ClipCard(
                        clip: c,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ShadowingScreen(clip: c),
                          ),
                        ),
                      )),
              if (shadowingClips.every(
                  (c) => c.minLevel > (progress.completedLessons + 1)))
                _lockedHint(
                    context, 'Shadowing ab Lektion ${shadowingClips.first.minLevel}'),
              const SizedBox(height: 24),
              _InfoBanner(),
              const SizedBox(height: 16),
              _sectionLabel(context, 'SZENARIEN'),
              const SizedBox(height: 8),
              ...conversationScenarios.map((s) => _ScenarioCard(
                    scenario: s,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ConversationScreen(scenario: s),
                      ),
                    ),
                  )),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, st) => const SizedBox.shrink(),
      ),
    );
  }
}

Widget _sectionLabel(BuildContext context, String label) => Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink2,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.08,
          ),
    );

Widget _lockedHint(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.ink2,
              fontStyle: FontStyle.italic,
            ),
      ),
    );

class _ClipCard extends StatelessWidget {
  final ConversationClip clip;
  final VoidCallback onTap;

  const _ClipCard({required this.clip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip.titleDe,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      clip.context,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink2,
                          ),
                    ),
                    Text(
                      '${clip.lines.length} Zeilen · Ab Lektion ${clip.minLevel}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink2,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.headphones_outlined, color: AppColors.ink2),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Text('💬', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KI-Konversation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  'Freie Gespräche auf Japanisch. Anthropic API erforderlich.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final ConversationScenario scenario;
  final VoidCallback onTap;

  const _ScenarioCard({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.titleJp,
                      style: AppTheme.jpBody,
                    ),
                    Text(
                      scenario.titleDe,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _styleLabel(scenario.style),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.ink2,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.ink2),
            ],
          ),
        ),
      ),
    );
  }

  String _styleLabel(ConversationStyle style) {
    switch (style) {
      case ConversationStyle.casual:
        return 'Umgangssprache · Ab Lektion ${scenario.minLevel}';
      case ConversationStyle.polite:
        return 'Höflich · Ab Lektion ${scenario.minLevel}';
      case ConversationStyle.business:
        return 'Formell · Ab Lektion ${scenario.minLevel}';
    }
  }
}

class _LockedView extends StatelessWidget {
  final int completedLessons;
  final int totalCards;

  const _LockedView({
    required this.completedLessons,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Text(
              'Gespräche freischalten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _Requirement(
                    label: 'Lektionen abgeschlossen',
                    current: completedLessons,
                    required_: 25,
                  ),
                  const SizedBox(height: 8),
                  _Requirement(
                    label: 'Karten gelernt',
                    current: totalCards,
                    required_: 250,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final int current;
  final int required_;

  const _Requirement({
    required this.label,
    required this.current,
    required this.required_,
  });

  @override
  Widget build(BuildContext context) {
    final done = current >= required_;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16,
          color: done ? AppColors.green : AppColors.ink2,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $current / $required_',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: done ? AppColors.green : AppColors.ink,
              ),
        ),
      ],
    );
  }
}
