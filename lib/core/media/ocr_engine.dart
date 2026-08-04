import 'dart:io';

/// One recognized text region on a page: the text and its bounding box
/// (pixel coordinates). The raw material of a [SpatialAnchor] (§5).
class OcrBox {
  final String text;
  final int left;
  final int top;
  final int right;
  final int bottom;

  const OcrBox({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, int> toRect() =>
      {'left': left, 'top': top, 'right': right, 'bottom': bottom};
}

/// An OCR engine: an image → recognized text boxes. An interface (not a
/// concrete Tesseract call) so the manga source adapter and its tests
/// depend on the capability, not the tool — the same shape as
/// `AvExtractor` wrapping ffmpeg. Manga OCR quality is an engine
/// concern; the SpatialAnchor pipeline path is engine-agnostic.
abstract interface class OcrEngine {
  Future<List<OcrBox>> recognize(File image);
}
