import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// One text segment extracted from an EPUB, in reading order. Segments
/// are block-level (paragraph/heading/list-item), then split at Unicode
/// sentence terminators so a single giant `<p>` holding a whole story
/// (as Gutenberg/Aozora conversions often produce) becomes usable
/// sentence-sized units instead of one 6000-character span.
///
/// Sentence splitting here is language-blind: it keys on the Unicode
/// sentence-terminator characters (｡．！？!?…), a *script* property, not
/// a per-language rule — the same discipline `sentence_scoring.dart`
/// uses to detect punctuation via `\p{P}` rather than an IPADIC POS
/// tag. No `if (lang == 'ja')` anywhere (§2.2 seam discipline).
class EpubBlock {
  final String text;
  final int ordinal;

  const EpubBlock({required this.text, required this.ordinal});
}

// A sentence terminator (any script), optionally followed by closing
// quotes/brackets that belong with the sentence it ends. The split
// happens *after* that group.
final _sentenceSplit = RegExp(r'(?<=[。．.！？!?…]["»）】」』）\)\]]*)\s*');

class EpubParseException implements Exception {
  final String message;
  const EpubParseException(this.message);
  @override
  String toString() => 'EpubParseException: $message';
}

const _containerPath = 'META-INF/container.xml';
const _opfNs = 'http://www.idpf.org/2007/opf';
const _containerNs = 'urn:oasis:names:tc:opendocument:xmlns:container';

const _blockTags = {
  'p', 'div', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'li', 'blockquote', 'dd', 'dt', 'figcaption', 'pre',
};

/// Parses an EPUB (from its raw bytes) into ordered [EpubBlock]s by
/// following the standard container → OPF → spine chain, then
/// extracting block-level text from each spine document in order.
/// Tolerant of the real-world messiness EPUBs carry (non-XHTML-strict
/// markup, entities) via the `html` package rather than a strict XML
/// parser for the content documents.
List<EpubBlock> parseEpub(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final filesByPath = <String, ArchiveFile>{
    for (final f in archive.files) f.name: f,
  };

  String readString(String path) {
    final file = filesByPath[path];
    if (file == null) {
      throw EpubParseException('Missing file in EPUB: $path');
    }
    return utf8.decode(file.content as List<int>);
  }

  // 1. container.xml -> OPF path
  final containerXml = XmlDocument.parse(readString(_containerPath));
  final rootfile = containerXml
      .findAllElements('rootfile', namespace: _containerNs)
      .firstWhere(
        (e) => e.getAttribute('media-type') == 'application/oebps-package+xml',
        orElse: () => throw const EpubParseException(
            'No OPF rootfile in container.xml'),
      );
  final opfPath = rootfile.getAttribute('full-path')!;
  final opfDir = p.dirname(opfPath);

  // 2. OPF -> manifest (id->href) + spine (ordered idrefs)
  final opf = XmlDocument.parse(readString(opfPath));
  final manifest = <String, String>{};
  for (final item in opf.findAllElements('item', namespace: _opfNs)) {
    final id = item.getAttribute('id');
    final href = item.getAttribute('href');
    if (id != null && href != null) manifest[id] = href;
  }

  final spineRefs = opf
      .findAllElements('itemref', namespace: _opfNs)
      .map((e) => e.getAttribute('idref'))
      .whereType<String>()
      .toList();
  if (spineRefs.isEmpty) {
    throw const EpubParseException('OPF spine is empty');
  }

  // 3. Each spine document, in order -> block-level text
  final blocks = <EpubBlock>[];
  var ordinal = 0;
  for (final idref in spineRefs) {
    final href = manifest[idref];
    if (href == null) continue;
    final docPath = p.normalize(p.join(opfDir, href));
    final file = filesByPath[docPath];
    if (file == null) continue;

    final doc =
        html_parser.parse(utf8.decode(file.content as List<int>));
    for (final el in doc.querySelectorAll(_blockTags.join(','))) {
      // Skip a block whose text is fully contained in a nested block we
      // also visit — take only leaf-ish blocks to avoid double-counting
      // a <div> and its inner <p>.
      final hasBlockChild =
          el.children.any((c) => _blockTags.contains(c.localName));
      if (hasBlockChild) continue;

      final blockText = _normalizeWhitespace(el.text);
      if (blockText.isEmpty) continue;
      for (final sentence in _splitSentences(blockText)) {
        blocks.add(EpubBlock(text: sentence, ordinal: ordinal++));
      }
    }
  }

  return blocks;
}

/// Splits a normalized block into sentence-sized pieces at Unicode
/// sentence terminators. A block with no terminator (a heading, a
/// title) stays a single segment.
List<String> _splitSentences(String block) {
  return block
      .split(_sentenceSplit)
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

final _wsPattern = RegExp(r'\s+');

String _normalizeWhitespace(String s) => s.replaceAll(_wsPattern, ' ').trim();
