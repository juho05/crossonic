import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Result.ok exposes its value', () {
      const result = Result<int>.ok(42);
      expect(result, isA<Ok<int>>());
      expect((result as Ok<int>).value, 42);
    });

    test('Result.error exposes its error', () {
      final error = Exception('boom');
      final result = Result<int>.error(error);
      expect(result, isA<Err<int>>());
      expect((result as Err<int>).error, same(error));
    });

    test('tryValue returns the value on success and null on error', () {
      expect(const Result<int>.ok(7).tryValue, 7);
      expect(Result<int>.error(Exception('x')).tryValue, isNull);
    });

    test('can be exhaustively matched on its sealed variants', () {
      String describe(Result<int> r) => switch (r) {
            Ok(:final value) => 'ok:$value',
            Err() => 'err',
          };
      expect(describe(const Result.ok(1)), 'ok:1');
      expect(describe(Result.error(Exception('x'))), 'err');
    });
  });
}