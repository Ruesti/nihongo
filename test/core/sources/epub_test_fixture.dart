import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Builds a minimal but spec-valid EPUB in memory (mimetype +
/// META-INF/container.xml + OPF with manifest/spine + XHTML content
/// docs), so EPUB tests need no committed binary fixture. [chapters] is
/// a list of chapters, each a list of block-level HTML strings.
Uint8List buildEpub(List<List<String>> chapters) {
  final archive = Archive();

  void addFile(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  // mimetype must be first and stored (uncompressed) per spec; for a
  // parser test the ordering/compression doesn't matter to ZipDecoder,
  // so a normal entry is fine.
  addFile('mimetype', 'application/epub+zip');
  addFile('META-INF/container.xml', '''
<?xml version="1.0"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');

  final manifestItems = StringBuffer();
  final spineItems = StringBuffer();
  for (var i = 0; i < chapters.length; i++) {
    final href = 'chap$i.xhtml';
    manifestItems.writeln(
        '<item href="$href" id="chap$i" media-type="application/xhtml+xml"/>');
    spineItems.writeln('<itemref idref="chap$i"/>');
    final body = chapters[i].join('\n');
    addFile('OEBPS/$href', '''
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><head><title>c$i</title></head>
<body>$body</body></html>''');
  }

  addFile('OEBPS/content.opf', '''
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="id">test-epub</dc:identifier>
    <dc:title>Test</dc:title>
    <dc:language>ja</dc:language>
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine>
$spineItems  </spine>
</package>''');

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// A ZIP that is not a valid EPUB (no META-INF/container.xml) — the
/// parser should reject it with an [EpubParseException], not crash.
Uint8List buildBrokenEpub() {
  final archive = Archive();
  final bytes = utf8.encode('not an epub');
  archive.addFile(ArchiveFile('random.txt', bytes.length, bytes));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}
