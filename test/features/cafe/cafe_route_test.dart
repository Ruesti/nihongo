import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/app/knowledge_providers.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/cafe/cafe_route.dart';
import 'package:nihongo_app/features/story/episode_registry.dart';
import 'package:nihongo_app/features/story/story_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningDb db;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = LearningDb.forTesting();
  });
  tearDown(() => db.close());

  Widget app(Widget child) => ProviderScope(
        overrides: [learningDbProvider.overrideWithValue(db)],
        child: MaterialApp(home: child),
      );

  testWidgets('ohne Folge: freier Besuch (hier leer)', (tester) async {
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
  });

  testWidgets('mit beendeter Folge: Weg 1 mit dem Raum der vier Gäste',
      (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await tester.pumpWidget(app(CafeRoute(episodeId: episode.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
  });

  testWidgets('mit Folge, aber Besuch schon erledigt: freier Besuch',
      (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await store.markCafeVisitDone(episode.id);
    await tester.pumpWidget(app(CafeRoute(episodeId: episode.id)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
  });

  testWidgets('ohne Folge, aber Weg 1 mit „Später weiter" unterbrochen: '
      'der Café-Tab setzt diesen Besuch fort', (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await store.saveCafeVisitPosition(episode.id, 0, 1);
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-room')), findsOneWidget);
    expect(find.byKey(const ValueKey('cafe-visit-resume')), findsOneWidget);
  });

  testWidgets('ohne Folge, Folge beendet, aber keine gespeicherte Position: '
      'freier Besuch', (tester) async {
    final store = StoryProgressStore(await SharedPreferences.getInstance());
    final episode = ProviderContainer().read(storyEpisodesProvider).first;
    await store.markCompleted(episode.id);
    await tester.pumpWidget(app(const CafeRoute()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('cafe-visit-empty')), findsOneWidget);
  });
}
