import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_screen.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal-Folge ohne Panels: hier geht es um Belegung und Einladung, nicht
/// um den Ablauf der Nachbesprechung (cafe_debrief_screen_test.dart).
final _episode = Episode.fromJson({
  'id': 'ep_x',
  'seasonId': 's',
  'orderIndex': 1,
  'title': 'T',
  'locale': 'ja',
  'era': 'e',
  'budget': {'items': [], 'glyphs': []},
  'pages': [],
});

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  Future<StoryProgressStore> storeWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    return StoryProgressStore(await SharedPreferences.getInstance());
  }

  testWidgets('offene Nachbesprechung: die Wirtin ist da und lädt ein — ohne '
      'Zahl', (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-guest-wirtin')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsOneWidget);
    expect(find.textContaining('fällig'), findsNothing);
  });

  testWidgets('Tipp auf die einladende Wirtin öffnet die Nachbesprechung',
      (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cafe-guest-wirtin')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
  });

  testWidgets('erledigte Nachbesprechung: keine Einladung, Café leer wie zuvor',
      (tester) async {
    final store = await storeWith(
        {'story_completed_ep_x': true, 'story_debrief_done_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(db: db, debriefEpisode: _episode, progressStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsNothing);
  });

  testWidgets('openDebriefOnEntry öffnet die Nachbesprechung von selbst; '
      'zurück → der normale Raum', (tester) async {
    final store = await storeWith({'story_completed_ep_x': true});
    await tester.pumpWidget(MaterialApp(
        home: CafeScreen(
            db: db,
            debriefEpisode: _episode,
            progressStore: store,
            openDebriefOnEntry: true)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
    await tester.tap(find.text('Zurück ins Café'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
    // Eine leere Nachbesprechung ist gesehen und damit erledigt: die Wirtin
    // lädt nicht ewig weiter ein, das Café ist wieder das normale Café.
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsNothing);
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
  });
}
