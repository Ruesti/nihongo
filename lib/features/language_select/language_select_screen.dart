import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/db/learning_db.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';
import 'language_options.dart';

final activeLanguageProvider = StateProvider<String>((ref) => 'ja');

final availableLanguagesProvider = FutureProvider<List<LanguageOption>>(
  (ref) => loadAvailableLanguages(ref.watch(learningDbProvider)),
);

const _nameDE = {
  'ja': 'Japanisch',
  'es': 'Spanisch',
  'ko': 'Koreanisch',
  'ar': 'Arabisch',
  'hi': 'Hindi',
  'zh': 'Chinesisch',
};

const _flagEmoji = {
  'ja': '🇯🇵',
  'es': '🇪🇸',
  'ko': '🇰🇷',
  'ar': '🇸🇦',
  'hi': '🇮🇳',
  'zh': '🇨🇳',
};

class LanguageSelectScreen extends ConsumerWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeLanguageProvider);
    final languagesAsync = ref.watch(availableLanguagesProvider);

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
          languagesAsync.when(
            data: (options) => Column(
              children: options
                  .map((o) => _LanguageCard(
                        option: o,
                        isActive: o.code == active,
                        onSelect: () async {
                          ref.read(activeLanguageProvider.notifier).state =
                              o.code;
                          TtsService.instance.setLocale(o.ttsVoice);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('active_language', o.code);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ))
                  .toList(),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Text('Sprachen konnten nicht geladen werden.'),
          ),
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
  final LanguageOption option;
  final bool isActive;
  final VoidCallback onSelect;

  const _LanguageCard({
    required this.option,
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
              Text(_flagEmoji[option.code] ?? '🏳️', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _nameDE[option.code] ?? option.code,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.nameNative,
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
                        if (option.needsScriptTrack) _Tag('Schrift'),
                        if (option.toneSystem != 'none') _Tag('Töne'),
                        if (option.isRtl) _Tag('RTL'),
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
