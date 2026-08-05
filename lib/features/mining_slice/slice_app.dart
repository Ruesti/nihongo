import 'package:flutter/material.dart';

import 'opening_gate.dart';
import 'slice_repository.dart';

/// The vertical-slice app shell: a Material app whose home is the
/// opening screen. Deliberately small — the slice's point is to make the
/// already-proven mining pipeline *visible* end to end, not to be the
/// final app shell. It boots from a [SliceRepository] the caller has
/// already seeded (see `main_mining.dart`).
class SliceApp extends StatelessWidget {
  final SliceRepository repo;

  const SliceApp({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3B5BA5));
    return MaterialApp(
      title: 'Softbrew · Mining-Slice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3B5BA5), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: OpeningGate(repo: repo),
    );
  }
}
