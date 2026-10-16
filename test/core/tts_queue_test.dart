import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo_app/core/tts_queue.dart';

void main() {
  test('Aufträge laufen nacheinander in Aufrufreihenfolge', () async {
    final q = TtsQueue();
    final log = <String>[];
    final gateA = Completer<void>();
    final a = q.run(() async {
      log.add('a:start');
      await gateA.future;
      log.add('a:end');
      return 1;
    });
    final b = q.run(() async {
      log.add('b');
      return 2;
    });
    await Future<void>.delayed(Duration.zero);
    expect(log, ['a:start']); // b wartet, bis a fertig ist
    gateA.complete();
    expect(await a, 1);
    expect(await b, 2);
    expect(log, ['a:start', 'a:end', 'b']);
  });

  test('ein werfender Auftrag bricht die Kette nicht ab', () async {
    final q = TtsQueue();
    final failing = q.run<void>(() async => throw StateError('boom'));
    final next = q.run(() async => 'weiter');
    await expectLater(failing, throwsStateError);
    expect(await next, 'weiter');
  });

  test('cancelPending verwirft wartende, nicht aber spätere Aufträge',
      () async {
    final q = TtsQueue();
    final log = <String>[];
    final gate = Completer<void>();
    final running = q.run(() async {
      log.add('laufend');
      await gate.future;
    });
    final pending = q.run(() async => log.add('wartend'));
    await Future<void>.delayed(Duration.zero);
    q.cancelPending();
    final later = q.run(() async => log.add('später'));
    gate.complete();
    await running;
    await expectLater(pending, throwsA(isA<TtsJobCancelled>()));
    await later;
    expect(log, ['laufend', 'später']);
  });
}
