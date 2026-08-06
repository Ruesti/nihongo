import 'package:flutter/material.dart';

import '../opening/opening_screen.dart';
import '../opening/opening_state.dart';
import 'reader_screen.dart';
import 'slice_repository.dart';

/// Hosts the real [OpeningScreen] (§8) and wires it to the slice: it
/// loads the proof state from real snapshot history, asks Datum for a
/// line, and re-loads both whenever the reader returns — so the Then/Now
/// proof appears the moment a passage has been read a second time.
class OpeningGate extends StatefulWidget {
  final SliceRepository repo;

  const OpeningGate({super.key, required this.repo});

  @override
  State<OpeningGate> createState() => _OpeningGateState();
}

class _OpeningGateState extends State<OpeningGate> {
  late Future<(OpeningState, String?)> _future = _load();

  Future<(OpeningState, String?)> _load() async {
    final state = await widget.repo.openingState();
    return (state, widget.repo.openingDatumLine(state));
  }

  Future<void> _openReader() async {
    // Rank the passages by i+1 suitability for the learner now, so the
    // session starts on the gentlest comprehensible content.
    final passages = await widget.repo.readingOrder();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(repo: widget.repo, passages: passages),
    ));
    if (!mounted) return;
    // Block body, not an arrow: `setState(() => _future = _load())` would
    // return the assigned Future from the callback, which Flutter rejects
    // ("do async work first, then setState synchronously"). Assigning the
    // future object is itself synchronous — the FutureBuilder re-runs it.
    setState(() {
      _future = _load(); // reflect the reading just done
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(OpeningState, String?)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (state, datumLine) = snapshot.data!;
          return OpeningScreen(
            state: state,
            datumLine: datumLine,
            onContinueReading: _openReader,
            // The slice bundles a single work; "Bibliothek" opens the
            // same reader. A real library screen is out of slice scope.
            onLibrary: _openReader,
          );
        },
      ),
    );
  }
}
