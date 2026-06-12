import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';

void main() {
  late LearningDb db;

  setUp(() {
    db = LearningDb.forTesting();
  });

  tearDown(() async => db.close());

  test('fresh DB has no languages', () async {
    final rows = await db.select(db.languages).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no concepts', () async {
    final rows = await db.select(db.concepts).get();
    expect(rows, isEmpty);
  });

  test('fresh DB has no learn_items', () async {
    final rows = await db.select(db.learnItems).get();
    expect(rows, isEmpty);
  });
}
