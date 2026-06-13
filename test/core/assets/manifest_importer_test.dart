import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/assets/manifest_importer.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/packs/ja/ja_seed.dart';

const _testManifest = '''
# concept_id,gloss_key,asset_type,prompt,status
concept_dog,dog,image,A golden retriever dog,generated
concept_cat,cat,image,A tabby cat,todo
concept_water,water,image,A glass of water,generated
concept_eat,eat,clip,Person eating,todo
concept_what,what,none,,generated
''';

void main() {
  late LearningDb db;
  late ManifestImporter importer;

  setUp(() async {
    db = LearningDb.forTesting();
    await seedJaPack(db);
    importer = ManifestImporter(db);
  });

  tearDown(() => db.close());

  group('importCsv', () {
    test('imports only status=generated rows', () async {
      final count = await importer.importCsv(_testManifest);
      expect(count, 3); // dog, water, what
    });

    test('skips status=todo rows', () async {
      await importer.importCsv(_testManifest);
      final assets = await db.select(db.assets).get();
      final ids = assets.map((a) => a.conceptId).toSet();
      expect(ids.contains('concept_cat'), isFalse);
      expect(ids.contains('concept_eat'), isFalse);
    });

    test('inserts correct path for image assets', () async {
      await importer.importCsv(_testManifest);
      final assets = await db.select(db.assets).get();
      final dog = assets.firstWhere((a) => a.conceptId == 'concept_dog');
      expect(dog.type, 'image');
      expect(dog.path, 'assets/concept_dog.webp');
    });

    test('inserts correct path for clip assets', () async {
      final csvWithClip = '''
concept_eat,eat,clip,Person eating,generated
''';
      await importer.importCsv(csvWithClip);
      final assets = await db.select(db.assets).get();
      final eat = assets.firstWhere((a) => a.conceptId == 'concept_eat');
      expect(eat.path, 'assets/concept_eat.mp4');
    });

    test('inserts correct path for icon assets', () async {
      final csvWithIcon = '''
concept_what,what,icon,Question mark,generated
''';
      await importer.importCsv(csvWithIcon);
      final assets = await db.select(db.assets).get();
      final what = assets.firstWhere((a) => a.conceptId == 'concept_what');
      expect(what.path, 'assets/concept_what.svg');
    });

    test('none-type assets are stored with empty path', () async {
      await importer.importCsv(_testManifest);
      final assets = await db.select(db.assets).get();
      final what = assets.firstWhere((a) => a.conceptId == 'concept_what');
      expect(what.type, 'none');
      expect(what.path, '');
    });

    test('skips comment lines (#)', () async {
      final count = await importer.importCsv(_testManifest);
      expect(count, 3); // # line not counted
    });

    test('skips empty lines', () async {
      final csvWithBlanks = '''

concept_dog,dog,image,A dog,generated

concept_cat,cat,image,A cat,generated

''';
      final count = await importer.importCsv(csvWithBlanks);
      expect(count, 2);
    });

    test('is idempotent — importing twice does not duplicate', () async {
      await importer.importCsv(_testManifest);
      await importer.importCsv(_testManifest);
      final assets = await db.select(db.assets).get();
      expect(assets, hasLength(3));
    });

    test('returns count of imported assets', () async {
      final count = await importer.importCsv(_testManifest);
      expect(count, 3);
    });
  });
}
