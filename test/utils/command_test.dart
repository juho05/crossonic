import 'dart:async';

import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Command0', () {
    test('starts idle with no result', () {
      final command = Command0(() async => const Result.ok(1));
      expect(command.running, isFalse);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
      expect(command.result, isNull);
    });

    test('on success it completes and exposes the value', () async {
      final command = Command0(() async => const Result.ok(42));
      await command.execute();

      expect(command.running, isFalse);
      expect(command.completed, isTrue);
      expect(command.error, isFalse);
      expect(command.result, isA<Ok<int>>());
      expect((command.result! as Ok<int>).value, 42);
    });

    test('on failure it reports an error and exposes the Err result', () async {
      final failure = Exception('x');
      final command = Command0<int>(() async => Result.error(failure));
      await command.execute();

      expect(command.running, isFalse);
      expect(command.error, isTrue);
      expect(command.completed, isFalse);
      expect(command.result, isA<Err<int>>());
      expect((command.result! as Err<int>).error, same(failure));
    });

    test('is running while the action is in flight', () async {
      final gate = Completer<Result<int>>();
      final command = Command0(() => gate.future);

      final future = command.execute();
      expect(command.running, isTrue);

      gate.complete(const Result.ok(1));
      await future;
      expect(command.running, isFalse);
    });

    test('cannot be launched again until the previous run finishes', () async {
      final gate = Completer<Result<int>>();
      var invocations = 0;
      final command = Command0(() {
        invocations++;
        return gate.future;
      });

      final first = command.execute();
      final ignored = command.execute();

      gate.complete(const Result.ok(1));
      await Future.wait([first, ignored]);

      expect(invocations, 1);
    });

    test('notifies listeners when running starts and when it finishes',
        () async {
      final command = Command0(() async => const Result.ok(1));
      var notifications = 0;
      command.addListener(() => notifications++);

      await command.execute();

      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('clearResult resets the completion state', () async {
      final command = Command0(() async => const Result.ok(1));
      await command.execute();
      expect(command.completed, isTrue);

      command.clearResult();

      expect(command.result, isNull);
      expect(command.completed, isFalse);
      expect(command.error, isFalse);
    });
  });

  group('Command1', () {
    test('passes the argument to the action', () async {
      int? received;
      final command = Command1<int, int>((arg) async {
        received = arg;
        return Result.ok(arg * 2);
      });

      await command.execute(21);

      expect(received, 21);
      expect((command.result! as Ok<int>).value, 42);
    });
  });
}