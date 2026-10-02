import 'package:flutter/services.dart';

/// Schaltet die Systemleisten beim Lesen aus und danach wieder ein (Spec
/// Manga-Vollbild §7.1). Als Schnittstelle, damit Widget-Tests beobachten
/// können, was der Reader schaltet, ohne `SystemChrome` zu berühren.
abstract class ReaderSystemUi {
  Future<void> enterImmersive();
  Future<void> exitImmersive();
}

/// Echte Umsetzung über `SystemChrome`. `immersiveSticky`: Leisten weg, ein
/// Wisch vom Rand zeigt sie kurz. Beim Verlassen kommen alle Leisten zurück.
class SystemChromeReaderUi implements ReaderSystemUi {
  const SystemChromeReaderUi();

  @override
  Future<void> enterImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  Future<void> exitImmersive() => SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
}
