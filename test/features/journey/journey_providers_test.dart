import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';
import 'package:nihongo_app/features/journey/journey_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('currentStepProvider resolves the first step of the bundled JA arc',
      () async {
    SharedPreferences.setMockInitialValues({});
    final db = LearningDb.forTesting();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      learningDbProvider.overrideWith((ref) => db),
    ]);
    addTearDown(container.dispose);

    final step = await container.read(currentStepProvider.future);
    expect(step, isNotNull);
    expect(step, isA<LessonStep>()); // arc opens with a lesson
  });
}
