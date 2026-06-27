import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date JSON', () {
    test('round-trips a full date', () {
      final date = Date(year: 2021, month: 3, day: 5);
      final restored = Date.fromJson(date.toJson());
      expect(restored, date);
      expect(restored.year, 2021);
      expect(restored.month, 3);
      expect(restored.day, 5);
    });

    test('omits absent components and restores them as null', () {
      final date = Date(year: 2021);
      final json = date.toJson();
      expect(json.containsKey('month'), isFalse);
      expect(json.containsKey('day'), isFalse);

      final restored = Date.fromJson(json);
      expect(restored.year, 2021);
      expect(restored.month, isNull);
      expect(restored.day, isNull);
    });
  });

  group('Date comparison', () {
    test('orders by year, then month, then day', () {
      expect(Date(year: 2020) < Date(year: 2021), isTrue);
      expect(Date(year: 2021, month: 5) > Date(year: 2021, month: 3), isTrue);
      expect(
        Date(year: 2021, month: 3, day: 10) >
            Date(year: 2021, month: 3, day: 2),
        isTrue,
      );
    });

    test('treats a missing month/day as the first', () {
      expect(Date(year: 2021), Date(year: 2021, month: 1, day: 1));
      expect(Date(year: 2021).hashCode, isA<int>());
    });

    test('compareTo is consistent with the ordering operators', () {
      final earlier = Date(year: 2020, month: 12);
      final later = Date(year: 2021, month: 1);
      expect(earlier.compareTo(later), lessThan(0));
      expect(later.compareTo(earlier), greaterThan(0));
      expect(earlier.compareTo(Date(year: 2020, month: 12)), 0);
    });

    test('sorts a list chronologically', () {
      final dates = [
        Date(year: 2021, month: 6),
        Date(year: 2019),
        Date(year: 2021, month: 1),
        Date(year: 2020, month: 12, day: 31),
      ]..sort();
      expect(dates.map((d) => d.toString()), [
        '2019',
        '2020-12-31',
        '2021-01',
        '2021-06',
      ]);
    });
  });
}