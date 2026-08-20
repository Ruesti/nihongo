import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/manga_step_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadComicPackForStep returns a pack for a bundled asset', () async {
    final pack = await loadComicPackForStep('assets/comic/ja_l0.json');
    expect(pack, isNotNull);
    expect(pack!.languageCode, 'ja');
  });

  test('loadComicPackForStep returns null for a missing asset', () async {
    expect(await loadComicPackForStep('assets/comic/does_not_exist.json'), isNull);
  });
}
