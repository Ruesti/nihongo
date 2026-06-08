import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/feature_gate.dart';
import '../../core/theme.dart';
import '../../core/tts_service.dart';
import '../../models/travel_phrase.dart';

final _availableCountries = [
  ('jp', 'Japan', 'Japanisch', 'ja-JP'),
  ('es', 'Spanien', 'Spanisch', 'es-ES'),
  ('fr', 'Frankreich', 'Französisch', 'fr-FR'),
  ('it', 'Italien', 'Italienisch', 'it-IT'),
  ('de', 'Deutschland', 'Deutsch', 'de-DE'),
  ('us', 'USA', 'Englisch', 'en-US'),
  ('gb', 'Großbritannien', 'Englisch', 'en-GB'),
  ('kr', 'Südkorea', 'Koreanisch', 'ko-KR'),
  ('cn', 'China', 'Mandarin', 'zh-CN'),
  ('pt', 'Portugal', 'Portugiesisch', 'pt-PT'),
  ('br', 'Brasilien', 'Portugiesisch', 'pt-BR'),
  ('mx', 'Mexiko', 'Spanisch', 'es-MX'),
  ('tr', 'Türkei', 'Türkisch', 'tr-TR'),
  ('gr', 'Griechenland', 'Griechisch', 'el-GR'),
  ('th', 'Thailand', 'Thailändisch', 'th-TH'),
];

class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  String? _selectedCountry;
  TravelPack? _currentPack;
  bool _loading = false;
  TravelCategory? _filterCategory;

  Future<void> _selectCountry(
      String code, String name, String lang, String tts) async {
    setState(() {
      _selectedCountry = code;
      _currentPack = null;
      _filterCategory = null;
    });

    if (code == 'jp') {
      setState(() => _currentPack = japanPack);
      return;
    }

    // Check cache
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('travel_pack_$code');
    if (cached != null) {
      final pack = _parsePack(cached, code, name, lang, tts);
      if (pack != null) {
        setState(() => _currentPack = pack);
        return;
      }
    }

    // Check if free
    final isFree = await FeatureGate.canUseTravelCountry(code);
    if (!isFree) {
      _showPaywall(context, name);
      return;
    }

    // Generate via AI
    await _generate(code, name, lang, tts);
  }

  Future<void> _generate(
      String code, String name, String lang, String tts) async {
    setState(() => _loading = true);
    try {
      final json = await AnthropicClient.generateTravelPack(
        countryCode: code,
        countryName: name,
        targetLanguage: lang,
      );
      final pack = _parseGeneratedPack(json, code, name, lang, tts);
      if (pack != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('travel_pack_$code', json);
        setState(() => _currentPack = pack);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TravelPack? _parsePack(
      String json, String code, String name, String lang, String tts) {
    try {
      return _parseGeneratedPack(json, code, name, lang, tts);
    } catch (_) {
      return null;
    }
  }

  TravelPack? _parseGeneratedPack(
      String jsonStr, String code, String name, String lang, String tts) {
    final decoded = jsonDecode(jsonStr);
    // API returns either a bare array or {"phrases": [...]}
    final phraseList = decoded is List
        ? decoded
        : (decoded as Map<String, dynamic>)['phrases'] as List;
    final phrases = phraseList.map((p) {
      final catStr = p['category'] as String? ?? 'essential';
      final cat = TravelCategory.values.firstWhere(
        (c) => c.name == catStr,
        orElse: () => TravelCategory.essential,
      );
      return TravelPhrase(
        target: p['target'] as String,
        romanization: p['romanization'] as String?,
        germanDE: p['germanDE'] as String,
        context: p['context'] as String? ?? '',
        isEssential: p['isEssential'] as bool? ?? false,
        category: cat,
      );
    }).toList();

    return TravelPack(
      countryCode: code,
      countryName: name,
      targetLanguage: lang,
      ttsLocale: tts,
      phrases: phrases,
    );
  }

  void _showPaywall(BuildContext context, String country) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$country freischalten',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Das Travel Bundle schaltet alle Länder frei.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Travel Bundle — 2,99 €'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈ Reise-Schnellkurs'),
        actions: [
          if (_currentPack != null)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => setState(() {
                _currentPack = null;
                _selectedCountry = null;
              }),
              tooltip: 'Länderauswahl',
            ),
        ],
      ),
      body: _currentPack != null
          ? _PhraseList(
              pack: _currentPack!,
              filterCategory: _filterCategory,
              onCategoryFilter: (c) => setState(() => _filterCategory = c),
            )
          : _CountryPicker(
              countries: _availableCountries,
              selectedCode: _selectedCountry,
              loading: _loading,
              onSelect: (c) => _selectCountry(c.$1, c.$2, c.$3, c.$4),
            ),
    );
  }
}

class _CountryPicker extends StatelessWidget {
  final List<(String, String, String, String)> countries;
  final String? selectedCode;
  final bool loading;
  final void Function((String, String, String, String)) onSelect;

  const _CountryPicker({
    required this.countries,
    required this.selectedCode,
    required this.loading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Phrasen werden generiert…'),
          ],
        ),
      );
    }

    return ListView(
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
            'Wähle ein Reiseziel. Die wichtigsten 50 Phrasen — '
            'in 2–3 Stunden abhakbar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'KOSTENLOS',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.green,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
        ),
        const SizedBox(height: 8),
        ...countries
            .where((c) => c.$1 == 'jp' || c.$1 == 'es' || c.$1 == 'fr')
            .map((c) => _CountryTile(country: c, onTap: () => onSelect(c))),
        const SizedBox(height: 16),
        Text(
          'TRAVEL BUNDLE',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.ink2,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.08,
              ),
        ),
        const SizedBox(height: 8),
        ...countries
            .where((c) => c.$1 != 'jp' && c.$1 != 'es' && c.$1 != 'fr')
            .map((c) => _CountryTile(country: c, onTap: () => onSelect(c))),
      ],
    );
  }
}

class _CountryTile extends StatelessWidget {
  final (String, String, String, String) country;
  final VoidCallback onTap;

  const _CountryTile({required this.country, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (code, name, lang, _) = country;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(name),
        subtitle: Text(lang),
        trailing: const Icon(Icons.chevron_right, color: AppColors.ink2),
        onTap: onTap,
        dense: true,
      ),
    );
  }
}

class _PhraseList extends StatelessWidget {
  final TravelPack pack;
  final TravelCategory? filterCategory;
  final void Function(TravelCategory?) onCategoryFilter;

  const _PhraseList({
    required this.pack,
    required this.filterCategory,
    required this.onCategoryFilter,
  });

  @override
  Widget build(BuildContext context) {
    final categories = TravelCategory.values;
    final filtered = filterCategory != null
        ? pack.phrases.where((p) => p.category == filterCategory).toList()
        : pack.phrases;

    return Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              _FilterChip(
                label: 'Alle',
                selected: filterCategory == null,
                onTap: () => onCategoryFilter(null),
              ),
              ...categories.map((c) => _FilterChip(
                    label: c.labelDe,
                    selected: filterCategory == c,
                    onTap: () => onCategoryFilter(c),
                  )),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filtered.length,
            itemBuilder: (context, i) =>
                _PhraseCard(phrase: filtered[i], pack: pack),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.red : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.red : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.normal,
              ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatefulWidget {
  final TravelPhrase phrase;
  final TravelPack pack;

  const _PhraseCard({required this.phrase, required this.pack});

  @override
  State<_PhraseCard> createState() => _PhraseCardState();
}

class _PhraseCardState extends State<_PhraseCard> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _checked,
              activeColor: AppColors.green,
              onChanged: (v) => setState(() => _checked = v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.phrase.target,
                    style: widget.pack.countryCode == 'jp'
                        ? AppTheme.jpBody.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: _checked
                                ? TextDecoration.lineThrough
                                : null,
                          )
                        : Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: _checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                  ),
                  if (widget.phrase.romanization != null)
                    Text(
                      widget.phrase.romanization!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'DMmono',
                            color: AppColors.ink2,
                          ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    widget.phrase.germanDE,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (widget.phrase.context.isNotEmpty)
                    Text(
                      widget.phrase.context,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.ink2),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up_outlined, size: 20),
              color: AppColors.ink2,
              onPressed: () async {
                TtsService.instance.setLocale(widget.pack.ttsLocale);
                await TtsService.instance.speak(widget.phrase.target);
              },
            ),
          ],
        ),
      ),
    );
  }
}
