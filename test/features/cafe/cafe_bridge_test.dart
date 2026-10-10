import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/db/mining_db.dart';
import 'package:nihongo_app/core/ladder/rung_defs.dart';
import 'package:nihongo_app/core/pipeline/fsrs_knowledge_source.dart';
import 'package:nihongo_app/core/pipeline/knowledge_bridge.dart';
import 'package:nihongo_app/core/pipeline/sentence_scoring.dart'
    show Knowledge;
import 'package:nihongo_app/features/cafe/cafe_scenes.dart';
import 'package:nihongo_app/features/cafe/stations/schulmaedchen_station.dart';
import 'package:nihongo_app/features/story/episode.dart';
import 'package:nihongo_app/features/story/speak_evaluator.dart';

/// Mirrors `ladder_review_test.dart`'s `_knows` exactly: reads through
/// `FsrsKnowledgeSource.load`, the same canonical read path
/// `ReviewScreen`-parity code uses, filtered by mining's BCP-47
/// `languageCode`. This proves the café's projection lands in the SAME
/// bucket the rest of the app reads from — not just that some row landed
/// somewhere.
Future<Knowledge> _knows(MiningDb db, String lemma,
        {required String languageCode}) async =>
    (await FsrsKnowledgeSource.load(db, languageCode: languageCode))
        .call(lemma);

class _Always implements SpeakEvaluator {
  @override
  Future<double> evaluate(String target) async => 1.0;
}

Episode _episode() => Episode.fromJson({
      'id': 'ep_t', 'seasonId': 's', 'orderIndex': 1, 'title': 'T',
      'locale': 'ja', 'era': 'e',
      'budget': {
        'items': [
          {'id': 'lex_ja_dog', 'refType': 'lexeme'},
        ],
        'glyphs': [],
      },
      'pages': [],
    });

void main() {
  testWidgets('a Schulmädchen-Station with a bridge projects the reviewed lexeme into '
      'the shared mining store', (tester) async {
    final learning = LearningDb.forTesting();
    final mining = MiningDb.forTesting();
    addTearDown(() async {
      await learning.close();
      await mining.close();
    });
    await learning.into(learning.concepts).insert(ConceptsCompanion.insert(
        id: 'concept_dog',
        glossKey: 'dog',
        partOfSpeech: 'noun',
        defaultAssetType: const Value('image')));
    await learning.into(learning.lexemes).insert(LexemesCompanion.insert(
        id: 'lex_ja_dog',
        languageId: 'lang_ja',
        conceptId: 'concept_dog',
        writtenForm: '犬',
        reading: 'いぬ'));
    await learning.addLearnItemAtRung('lang_ja', RefType.lexeme, 'lex_ja_dog',
        rung: 3);

    // Before: mining knows nothing about 犬 under the canonical 'ja' bucket.
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.unknown);

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: SchulmaedchenStation(
        db: learning,
        languageId: 'lang_ja',
        episode: _episode(),
        itemIds: const ['lex_ja_dog'],
        startIndex: 0, // Hören→Schreiben
        bridge: KnowledgeBridge(mining),
        speak: (_) async {},
        evaluator: _Always(),
        light: CafeLight.tag,
        onPosition: (_) {},
        onDone: (_) {},
        onLater: () {},
      ),
    ));
    await tester.pumpAndSettle();

    // Produce the word on the kana keyboard (い・ぬ), then submit.
    for (final c in 'いぬ'.runes.map(String.fromCharCode)) {
      await tester.ensureVisible(find.byKey(ValueKey('kana-key-$c')));
      await tester.tap(find.byKey(ValueKey('kana-key-$c')));
      await tester.pump();
    }
    await tester.tap(find.byKey(const ValueKey('schul-submit')));
    await tester.pumpAndSettle();

    // After: the graded review projected into mining under 'ja' — the same
    // bucket ReviewScreen and the KnowledgeBoot backfill use (rung 3 → known).
    expect(await _knows(mining, '犬', languageCode: 'ja'), Knowledge.known);

    // Negative: nothing landed in the dead 'lang_ja' bucket (the on-ramp
    // pack id, not the BCP-47 mining code). If this fails, the café is
    // still projecting to the wrong bucket.
    final wrongBucket = await mining.select(mining.vocabItems).get()
      ..retainWhere((v) => v.languageCode == 'lang_ja');
    expect(wrongBucket, isEmpty);
    expect(await _knows(mining, '犬', languageCode: 'lang_ja'),
        Knowledge.unknown);
  });
}
