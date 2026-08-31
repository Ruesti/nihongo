import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/journey_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to 0 and round-trips per language', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final p = JourneyProgress(prefs);

    expect(p.stepIndex('ja'), 0);
    await p.setStepIndex('ja', 3);
    expect(p.stepIndex('ja'), 3);
    expect(p.stepIndex('es'), 0); // per-language isolation
  });
}
