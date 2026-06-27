import 'package:crossonic/utils/throttle.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const delay = Duration(seconds: 1);

  group('Throttle (leading + trailing)', () {
    test('fires immediately on the first call', () {
      fakeAsync((async) {
        var count = 0;
        Throttle(action: () => count++, delay: delay)();
        expect(count, 1);
      });
    });

    test('coalesces calls during the window into a single trailing call', () {
      fakeAsync((async) {
        var count = 0;
        final throttle = Throttle(action: () => count++, delay: delay);

        throttle();
        throttle();
        throttle();
        expect(count, 1, reason: 'only the leading call fires immediately');

        async.elapse(delay);
        expect(count, 2, reason: 'a single trailing call fires after the delay');
      });
    });

    test('does not schedule a trailing call when only called once', () {
      fakeAsync((async) {
        var count = 0;
        Throttle(action: () => count++, delay: delay)();

        async.elapse(delay);
        expect(count, 1);
      });
    });
  });

  group('Throttle (trailing only)', () {
    test('defers the first call to the end of the window', () {
      fakeAsync((async) {
        var count = 0;
        final throttle = Throttle(
          action: () => count++,
          delay: delay,
          leading: false,
        );

        throttle();
        expect(count, 0);

        async.elapse(delay);
        expect(count, 1);
      });
    });
  });

  group('Throttle1', () {
    test('the trailing call uses the most recent argument', () {
      fakeAsync((async) {
        final received = <int>[];
        final throttle = Throttle1<int>(
          action: received.add,
          delay: delay,
        );

        throttle(1);
        throttle(2);
        throttle(3);
        expect(received, [1], reason: 'leading call uses the first argument');

        async.elapse(delay);
        expect(received, [1, 3], reason: 'trailing call uses the latest');
      });
    });
  });
}