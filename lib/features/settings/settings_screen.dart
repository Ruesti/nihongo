import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_key_service.dart';
import '../../core/language_module.dart';
import '../../core/purchases_service.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';
import '../language_select/language_select_screen.dart';

final _apiKeyProvider = FutureProvider<String?>((ref) => ApiKeyService.get());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _keyVisible = false;
  bool _saving = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    setState(() => _saving = true);
    await ApiKeyService.save(_keyCtrl.text);
    ref.invalidate(_apiKeyProvider);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API-Key gespeichert')),
      );
    }
  }

  Future<void> _deleteApiKey() async {
    await ApiKeyService.delete();
    ref.invalidate(_apiKeyProvider);
    _keyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyAsync = ref.watch(_apiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Sprache'),
          const SizedBox(height: 8),
          _LanguageCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'KI-Feedback (Anthropic API)'),
          const SizedBox(height: 8),
          _ApiKeyCard(
            apiKeyAsync: apiKeyAsync,
            controller: _keyCtrl,
            keyVisible: _keyVisible,
            onToggleVisibility: () =>
                setState(() => _keyVisible = !_keyVisible),
            onSave: _saveApiKey,
            onDelete: _deleteApiKey,
            saving: _saving,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Sprachausgabe (TTS)'),
          const SizedBox(height: 8),
          _TtsTestCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Furigana'),
          const SizedBox(height: 8),
          _FuriganaCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Käufe'),
          const SizedBox(height: 8),
          _PurchasesCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'App'),
          const SizedBox(height: 8),
          _AppInfoCard(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink2,
            letterSpacing: 0.08,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _ApiKeyCard extends StatelessWidget {
  final AsyncValue<String?> apiKeyAsync;
  final TextEditingController controller;
  final bool keyVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onSave;
  final VoidCallback onDelete;
  final bool saving;

  const _ApiKeyCard({
    required this.apiKeyAsync,
    required this.controller,
    required this.keyVisible,
    required this.onToggleVisibility,
    required this.onSave,
    required this.onDelete,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final hasKey = apiKeyAsync.asData?.value != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasKey)
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  const Text(
                    'API-Key hinterlegt',
                    style: TextStyle(
                        color: AppColors.green, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onDelete,
                    child: const Text('Löschen'),
                  ),
                ],
              )
            else ...[
              Text(
                'Für KI-Feedback und KI-Konversation benötigst du einen '
                'Anthropic API-Key. Dieser wird nur lokal gespeichert.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: !keyVisible,
                decoration: InputDecoration(
                  hintText: 'sk-ant-...',
                  suffixIcon: IconButton(
                    icon: Icon(
                        keyVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: onToggleVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  child: Text(saving ? 'Speichern…' : 'Speichern'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Kosten: ~0,01 € pro KI-Gespräch (Claude Haiku)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TtsTestCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sprache: Japanisch (ja-JP)',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('Nutzt System-TTS (offline verfügbar)',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  TtsService.instance.speak('こんにちは、たまごです。'),
              child: const Text('Test'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuriganaCard extends StatefulWidget {
  @override
  State<_FuriganaCard> createState() => _FuriganaCardState();
}

class _FuriganaCardState extends State<_FuriganaCard> {
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      setState(() => _enabled = p.getBool('furigana_enabled') ?? true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: const Text('Furigana anzeigen'),
        subtitle: const Text('Lesehilfe über Kanji'),
        value: _enabled,
        activeColor: AppColors.red,
        onChanged: (val) async {
          setState(() => _enabled = val);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('furigana_enabled', val);
        },
      ),
    );
  }
}

class _PurchasesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Käufe wiederherstellen',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final ok = await PurchasesService.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Käufe wiederhergestellt'
                        : 'Keine Käufe gefunden'),
                  ));
                }
              },
              child: const Text('Wiederherstellen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(activeLanguageProvider);
    final module = moduleForCode(lang);
    return Card(
      child: ListTile(
        leading: Text(module.flagEmoji, style: const TextStyle(fontSize: 24)),
        title: Text(module.nameDE),
        subtitle: Text(module.nameNative),
        trailing: const Icon(Icons.chevron_right, color: AppColors.ink2),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const LanguageSelectScreen(),
          ),
        ),
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nihongo — Japanisch lernen',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Version 0.1.0',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Softbrew Studio',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}
