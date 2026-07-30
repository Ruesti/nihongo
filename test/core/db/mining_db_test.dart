import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/mining_db.dart';

void main() {
  late MiningDb db;

  setUp(() => db = MiningDb.forTesting());
  tearDown(() => db.close());

  group('MiningDb', () {
    test('creates all tables without error', () async {
      // If schema creation is broken, this throws before we get here.
      expect(await db.installedLanguagePacks(), isEmpty);
    });

    test('registerLanguagePack inserts a row readable via installedLanguagePacks',
        () async {
      await db.registerLanguagePack(
        code: 'ja',
        name: 'Japanese',
        hasReadings: true,
      );

      final packs = await db.installedLanguagePacks();

      expect(packs, hasLength(1));
      expect(packs.single.code, 'ja');
      expect(packs.single.hasReadings, isTrue);
    });

    test('registerLanguagePack upserts on conflict rather than duplicating',
        () async {
      await db.registerLanguagePack(code: 'ja', name: 'Japanese', hasReadings: true);
      await db.registerLanguagePack(code: 'ja', name: 'Japanese (renamed)', hasReadings: true);

      final packs = await db.installedLanguagePacks();

      expect(packs, hasLength(1));
      expect(packs.single.name, 'Japanese (renamed)');
    });
  });
}
