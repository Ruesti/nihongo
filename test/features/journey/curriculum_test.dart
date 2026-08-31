import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/features/journey/curriculum.dart';

const _json = {
  'languageCode': 'ja',
  'title': 'Neko no hi',
  'steps': [
    {
      'id': 'c1-lesson',
      'kind': 'lesson',
      'chapterRef': 'Kapitel 1',
      'characterIds': ['char_ja_a', 'char_ja_i'],
      'lexemeIds': ['lex_ja_cat'],
      'grammarIds': <String>[],
    },
    {
      'id': 'c1-manga',
      'kind': 'manga',
      'chapterRef': 'Kapitel 1',
      'comicAsset': 'assets/comic/ja_l0.json',
    },
  ],
};

void main() {
  test('parses a mixed lesson/manga curriculum', () {
    final c = Curriculum.fromJson(_json);
    expect(c.languageCode, 'ja');
    expect(c.steps, hasLength(2));

    final lesson = c.steps[0];
    expect(lesson, isA<LessonStep>());
    expect((lesson as LessonStep).characterIds, ['char_ja_a', 'char_ja_i']);
    expect(lesson.lexemeIds, ['lex_ja_cat']);
    expect(lesson.chapterRef, 'Kapitel 1');

    final manga = c.steps[1];
    expect(manga, isA<MangaStep>());
    expect((manga as MangaStep).comicAsset, 'assets/comic/ja_l0.json');
  });
}
