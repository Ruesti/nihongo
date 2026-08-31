import '../../core/language_pack/language_pack.dart' show Dictionary, Sense;

/// A tiny bundled lemma→meaning dictionary so tapping an L2 word in the comic
/// shows a real gloss (instead of "—"). Keyed on lemma; the pos argument is
/// ignored (WordTapHandler always passes ''). Grows with the curriculum;
/// a full JMdict-backed dictionary is a later concern.
class BundledDictionary implements Dictionary {
  final Map<String, List<Sense>> _byLemma;
  const BundledDictionary(this._byLemma);

  @override
  List<Sense> lookup(String lemma, String pos) => _byLemma[lemma] ?? const [];
}

/// The Japanese first-chapter vocabulary (matches the seeded lexemes).
const BundledDictionary jaBundledDictionary = BundledDictionary({
  '猫': [Sense(pos: 'n', glosses: ['Katze'])],
  '犬': [Sense(pos: 'n', glosses: ['Hund'])],
  '水': [Sense(pos: 'n', glosses: ['Wasser'])],
  '食べる': [Sense(pos: 'v', glosses: ['essen'])],
  '何': [Sense(pos: 'pron', glosses: ['was'])],
});
