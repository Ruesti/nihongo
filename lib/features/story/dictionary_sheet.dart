import 'package:flutter/material.dart';

import '../../core/language_module.dart' show ScriptGroup;
import 'dictionary.dart';
import 'dictionary_groups.dart';

/// Browses [entries] by gojūon row — no search field. Looking something up
/// requires knowing its reading well enough to find the right row and
/// character (brief §3.2 — the friction is deliberate). The sheet opens with
/// a header that names the book and says how to browse, and every row shows
/// its kana plus the romanization of its first sound: without that, the row
/// index read as a column of unrelated characters (device test 30.9.). An entry's
/// [DictionaryEntry.meaning] only renders once its id is in [knownIds];
/// otherwise only the headword shows. A margin note, when present, always
/// shows regardless of known-state and has no gesture handler at all — not
/// merely undecorated, genuinely unresolvable (§3.5), matching how locked
/// tokens render inert in the panel reader (P3).
class DictionarySheet extends StatefulWidget {
  final List<DictionaryEntry> entries;
  final Set<String> knownIds;

  const DictionarySheet({
    super.key,
    required this.entries,
    required this.knownIds,
  });

  @override
  State<DictionarySheet> createState() => _DictionarySheetState();
}

class _DictionarySheetState extends State<DictionarySheet> {
  static const _otherGroupName = 'Weitere';

  ScriptGroup? _selectedGroup;

  bool _matchesGroup(DictionaryEntry entry, ScriptGroup group) {
    return entry.headword.isNotEmpty &&
        group.characters.contains(entry.headword[0]);
  }

  List<DictionaryEntry> _entriesForGroup(ScriptGroup group) {
    return widget.entries.where((e) => _matchesGroup(e, group)).toList();
  }

  /// Entries whose headword doesn't start with any gojūon-row character —
  /// e.g. a katakana or kanji headword, or an empty headword. Without this
  /// bucket such an entry would never appear anywhere when browsing.
  List<DictionaryEntry> get _otherEntries {
    return widget.entries
        .where((e) => dictionaryGroups.every((g) => !_matchesGroup(e, g)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final group = _selectedGroup;
    final textTheme = Theme.of(context).textTheme;
    if (group == null) {
      final other = _otherEntries;
      return ListView(
        key: const ValueKey('dictionary-group-list'),
        children: [
          Padding(
            key: const ValueKey('dictionary-header'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wörterbuch', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Kein Suchfeld: Blättere zur Reihe des ersten Zeichens, '
                  'dort steht das Wort. Bedeutungen stehen nur bei Wörtern, '
                  'die du schon gelernt hast.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final g in dictionaryGroups)
            ListTile(
              key: ValueKey('dictionary-group-${g.name}'),
              title: Text(g.name),
              subtitle: Text(g.characters.join(' ')),
              trailing: Text(
                g.romanizations.first,
                style: textTheme.labelLarge,
              ),
              onTap: () => setState(() => _selectedGroup = g),
            ),
          if (other.isNotEmpty)
            ListTile(
              key: const ValueKey('dictionary-group-other'),
              title: const Text(_otherGroupName),
              subtitle: const Text('Katakana, Kanji und anderes'),
              onTap: () => setState(
                () => _selectedGroup = const ScriptGroup(
                  name: _otherGroupName,
                  characters: [],
                  romanizations: [],
                ),
              ),
            ),
        ],
      );
    }

    final entries =
        group.name == _otherGroupName ? _otherEntries : _entriesForGroup(group);

    return Column(
      key: const ValueKey('dictionary-entry-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              key: const ValueKey('dictionary-back'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Zurück',
              onPressed: () => setState(() => _selectedGroup = null),
            ),
            Text(group.name, style: textTheme.titleMedium),
            if (group.characters.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  group.characters.join(' '),
                  style: textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              for (final entry in entries) _entryTile(entry),
            ],
          ),
        ),
      ],
    );
  }

  Widget _entryTile(DictionaryEntry entry) {
    final known = widget.knownIds.contains(entry.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.headword,
            style: entry.marginNote != null
                ? const TextStyle(decoration: TextDecoration.underline)
                : null,
          ),
          if (known)
            Text(
              entry.meaning,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Color(0xFF2A4D8F),
              ),
            ),
          if (entry.marginNote != null)
            Text(
              entry.marginNote!,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
        ],
      ),
    );
  }
}
