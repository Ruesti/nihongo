import 'package:flutter/material.dart';

import '../../core/language_module.dart' show ScriptGroup;
import 'dictionary.dart';
import 'dictionary_groups.dart';

/// Browses [entries] by gojūon row — no search field. Looking something up
/// requires knowing its reading well enough to find the right row and
/// character (brief §3.2 — the friction is deliberate). An entry's
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
  ScriptGroup? _selectedGroup;

  List<DictionaryEntry> _entriesForGroup(ScriptGroup group) {
    return widget.entries
        .where((e) => group.characters.contains(e.headword[0]))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final group = _selectedGroup;
    if (group == null) {
      return ListView(
        key: const ValueKey('dictionary-group-list'),
        children: [
          for (final g in dictionaryGroups)
            ListTile(
              key: ValueKey('dictionary-group-${g.name}'),
              title: Text(g.name),
              onTap: () => setState(() => _selectedGroup = g),
            ),
        ],
      );
    }

    return Column(
      key: const ValueKey('dictionary-entry-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const ValueKey('dictionary-back'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedGroup = null),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final entry in _entriesForGroup(group)) _entryTile(entry),
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
