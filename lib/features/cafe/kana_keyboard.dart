import 'package:flutter/material.dart';

import '../../data/kana_data.dart';

/// Vergleichsform für Kana-Antworten (Spec Global Constraints): ohne
/// Leerzeichen und ohne die Satzzeichen, die in Blasen vorkommen.
String normalizeKana(String s) =>
    s.replaceAll(RegExp(r'[\s！？。、…・!?.,]'), '');

const _dakutenCycle = {
  'か': 'が', 'が': 'か', 'き': 'ぎ', 'ぎ': 'き', 'く': 'ぐ', 'ぐ': 'く',
  'け': 'げ', 'げ': 'け', 'こ': 'ご', 'ご': 'こ',
  'さ': 'ざ', 'ざ': 'さ', 'し': 'じ', 'じ': 'し', 'す': 'ず', 'ず': 'す',
  'せ': 'ぜ', 'ぜ': 'せ', 'そ': 'ぞ', 'ぞ': 'そ',
  'た': 'だ', 'だ': 'た', 'ち': 'ぢ', 'ぢ': 'ち', 'つ': 'づ', 'づ': 'つ',
  'て': 'で', 'で': 'て', 'と': 'ど', 'ど': 'と',
  'は': 'ば', 'ば': 'ぱ', 'ぱ': 'は', 'ひ': 'び', 'び': 'ぴ', 'ぴ': 'ひ',
  'ふ': 'ぶ', 'ぶ': 'ぷ', 'ぷ': 'ふ', 'へ': 'べ', 'べ': 'ぺ', 'ぺ': 'へ',
  'ほ': 'ぼ', 'ぼ': 'ぽ', 'ぽ': 'ほ',
};

const _smallCycle = {
  'や': 'ゃ', 'ゃ': 'や', 'ゆ': 'ゅ', 'ゅ': 'ゆ', 'よ': 'ょ', 'ょ': 'よ',
  'つ': 'っ', 'っ': 'つ', 'あ': 'ぁ', 'ぁ': 'あ', 'い': 'ぃ', 'ぃ': 'い',
  'う': 'ぅ', 'ぅ': 'う', 'え': 'ぇ', 'ぇ': 'え', 'お': 'ぉ', 'ぉ': 'お',
};

String _replaceLast(String s, Map<String, String> cycle) {
  if (s.isEmpty) return s;
  final last = s.substring(s.length - 1);
  final next = cycle[last];
  return next == null ? s : s.substring(0, s.length - 1) + next;
}

/// ゛゜-Taste: das letzte Zeichen stimmhaft / halbstimmhaft / zurück.
String applyDakuten(String s) => _replaceLast(s, _dakutenCycle);

/// 小-Taste: das letzte Zeichen klein (ゃゅょっ, ぁぃぅぇぉ) und zurück.
String applySmall(String s) => _replaceLast(s, _smallCycle);

/// Eingebaute Hiragana-Tastatur (Spec §6.1): 50-Laute-Raster in Spalten je
/// Reihe (hiraganaGroups), dazu ゛゜, 小 und ⌫. Keine System-Tastatur nötig.
/// [value] ist der bisherige Text, [onChanged] bekommt den neuen.
class KanaKeyboard extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const KanaKeyboard({super.key, required this.value, required this.onChanged});

  /// Tastengröße 38×38 (Schrift 18); die Rasterhöhe folgt (5 Reihen × 38 =
  /// 190). Ist die Fläche schmaler als 10 × 38, schrumpfen die Tasten, bis
  /// alle zehn Spalten nebeneinander passen (360-dp-Gerät abzüglich Rand).
  static const keyExtent = 38.0;
  static const _columns = 10; // あ行 … わ行

  Widget _key(String label, String keyName, VoidCallback onTap,
          {double extent = keyExtent}) =>
      SizedBox(
        width: extent,
        height: extent,
        child: OutlinedButton(
          key: ValueKey('kana-key-$keyName'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 18)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value.isEmpty ? ' ' : value,
            key: const ValueKey('kana-keyboard-value'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28),
          ),
        ),
        LayoutBuilder(builder: (context, c) {
          final extent = c.maxWidth.isFinite
              ? (c.maxWidth / _columns).clamp(24.0, keyExtent)
              : keyExtent;
          return SizedBox(
            height: 5 * extent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // あ行 rechts wie in der 50-Laute-Tafel
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in hiraganaGroups.reversed)
                    Column(
                      children: [
                        for (final kana in group.characters)
                          _key(kana, kana, () => onChanged(value + kana),
                              extent: extent),
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _key('゛゜', 'dakuten', () => onChanged(applyDakuten(value))),
            const SizedBox(width: 8),
            _key('小', 'small', () => onChanged(applySmall(value))),
            const SizedBox(width: 8),
            _key('⌫', 'backspace', () {
              if (value.isNotEmpty) {
                onChanged(value.substring(0, value.length - 1));
              }
            }),
          ],
        ),
      ],
    );
  }
}
