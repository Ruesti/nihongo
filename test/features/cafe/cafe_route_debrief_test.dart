import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _folge01 = 'ep_ja_shotengai_01';

void main() {
  late LearningDb db;
  setUp(() => db = LearningDb.forTesting());
  tearDown(() async => db.close());

  Widget app(Widget home) => ProviderScope(
        overrides: [learningDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: home),
      );

  testWidgets('offene Nachbesprechung von Folge 01 → die Wirtin lädt im '
      'Café-Tab ein', (tester) async {
    SharedPreferences.setMockInitialValues({'story_completed_$_folge01': true});
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-invite')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });

  testWidgets('debriefEpisodeId + offen → die Nachbesprechung öffnet sich von '
      'selbst', (tester) async {
    SharedPreferences.setMockInitialValues({'story_completed_$_folge01': true});
    await tester.pumpWidget(app(const CafeRoute(debriefEpisodeId: _folge01)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsOneWidget);
  });

  testWidgets('debriefEpisodeId ohne offene Nachbesprechung → normaler Besuch',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(app(const CafeRoute(debriefEpisodeId: _folge01)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-debrief-screen')), findsNothing);
  });
}
