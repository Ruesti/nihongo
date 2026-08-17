# Stroke-order SVG attribution

Stroke-order data from [KanjiVG](https://kanjivg.tagaini.net) by Ulrich Apel,
licensed under [CC-BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

Files are named `<hex-codepoint>.svg` (lowercase, no leading zero), e.g.
`3042.svg` for あ (U+3042) — the KanjiVG source repo names the same file
`03042.svg` (5-digit zero-padded hex).

## Bundled files

Fetched from `https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/`:

| File | Kana | Codepoint |
| --- | --- | --- |
| `3042.svg` | あ | U+3042 |
| `3044.svg` | い | U+3044 |
| `3046.svg` | う | U+3046 |
| `3048.svg` | え | U+3048 |
| `304a.svg` | お | U+304A |
| `65e5.svg` | 日 (kanji, pre-existing) | U+65E5 |

To add more kana, fetch `kanji/<5-digit-zero-padded-hex>.svg` from the
KanjiVG repo and save it here without the leading zero, then add the
codepoint to `_bundledKanaCodepoints` in `lib/data/kana_strokes.dart`.
