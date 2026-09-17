import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'episode.dart';
import 'episodes/folge_01_regen.dart';

/// Alle gebündelten Folgen in Serienreihenfolge — die eine Stelle, die weiß,
/// welche Folgen es gibt (Reader, Café-Nachbesprechung). Heute: Folge 01.
/// Beim ersten Zugriff validiert: ein Schema-Verstoß wirft und erscheint
/// ehrlich als Fehler statt still falschen Inhalt zu zeigen.
final storyEpisodesProvider =
    Provider<List<Episode>>((ref) => [loadFolge01()]);
