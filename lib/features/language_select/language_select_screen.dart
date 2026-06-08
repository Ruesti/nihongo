import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/language_module.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';

final activeLanguageProvider = StateProvider<String>((ref) => 'ja');

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sprache wählen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Jede Sprache hat einen eigenen Lernfortschritt und SRS-Stack. '
              'Du kannst jederzeit wechseln — ohne Datenverlust.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VERFÜGBAR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                ),
          ),
          const SizedBox(height: 8),
          ...allModules.map((m) => _LanguageCard(
                module: m,
                isActive: m.code == active,
                onSelect: () async {
                  ref.read(activeLanguageProvider.notifier).state = m.code;
                  TtsService.instance.setLocale(m.ttsLocale);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('active_language', m.code);
                  if (context.mounted) Navigator.of(context).pop();
                },
              )),
          const SizedBox(height: 16),
          Text(
            'BALD VERFÜGBAR',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.ink2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.08,
                ),
          ),
          const SizedBox(height: 8),
          ...['🇹🇷 Türkisch', '🇩🇪 Deutsch', '🇧🇷 Portugiesisch']
              .map((label) => _ComingSoonCard(label: label)),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final LanguageModule module;
  final bool isActive;
  final VoidCallback onSelect;

  const _LanguageCard({
    required this.module,
    required this.isActive,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(module.flagEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          module.nameDE,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          module.nameNative,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.ink2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (module.hasScript)
                          _Tag('Schrift'),
                        if (module.hasToneSystem)
                          _Tag('Töne'),
                        if (module.hasGender)
                          _Tag('Genus'),
                        if (module.hasConjugation)
                          _Tag('Konjugation'),
                        _Tag('${module.curriculum.length} Lektionen'),
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle, color: AppColors.green, size: 20)
              else
                const Icon(Icons.chevron_right, color: AppColors.ink2, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.ink2,
            ),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final String label;

  const _ComingSoonCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.45,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(label.split(' ').first, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Text(
                label.split(' ').skip(1).join(' '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'bald',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink2,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
