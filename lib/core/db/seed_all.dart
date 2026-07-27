import 'learning_db.dart';
import '../../packs/ar/ar_seed.dart';
import '../../packs/es/es_seed.dart';
import '../../packs/hi/hi_seed.dart';
import '../../packs/ja/ja_seed.dart';
import '../../packs/ko/ko_seed.dart';
import '../../packs/zh/zh_seed.dart';

Future<void> seedAllPacks(LearningDb db) async {
  await seedJaPack(db);
  await seedEsPack(db);
  await seedKoPack(db);
  await seedArPack(db);
  await seedHiPack(db);
  await seedZhPack(db);
}
