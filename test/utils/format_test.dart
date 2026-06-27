import 'package:crossonic/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('shows mm:ss without an hours segment when under an hour', () {
      expect(formatDuration(const Duration(minutes: 2, seconds: 3)), '02:03');
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('adds an hours segment once the duration reaches an hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });

    test('uses minute/second remainders rather than totals', () {
      expect(formatDuration(const Duration(minutes: 90)), '1:30:00');
    });

    test('long form spells out the units and only shows hours when present',
        () {
      expect(
        formatDuration(const Duration(minutes: 2, seconds: 3), long: true),
        '02min 03s',
      );
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3),
            long: true),
        '1h 02min 03s',
      );
    });
  });

  group('formatDateValues', () {
    test('renders only the parts that are provided', () {
      expect(formatDateValues(2021), '2021');
      expect(formatDateValues(2021, 3), '2021-03');
      expect(formatDateValues(2021, 3, 5), '2021-03-05');
    });

    test('zero-pads each component', () {
      expect(formatDateValues(7, 1, 2), '0007-01-02');
    });
  });

  group('formatDate / formatDateTime', () {
    test('formats a local DateTime', () {
      final d = DateTime(2021, 3, 5, 13, 30, 45);
      expect(formatDate(d), '2021-03-05');
      expect(formatDateTime(d), '2021-03-05 13:30:45');
    });
  });

  group('formatBoolToYesNo', () {
    test('maps booleans to yes/no', () {
      expect(formatBoolToYesNo(true), 'yes');
      expect(formatBoolToYesNo(false), 'no');
    });
  });

  group('formatDouble', () {
    test('rounds to the requested number of decimals', () {
      expect(formatDouble(3.14159), '3.14');
      expect(formatDouble(1.236), '1.24');
      expect(formatDouble(2.7, precision: 0), '3.0');
    });

    test('keeps whole numbers as decimals', () {
      expect(formatDouble(2), '2.0');
    });
  });
}