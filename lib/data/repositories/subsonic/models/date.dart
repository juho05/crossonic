import 'package:crossonic/data/services/opensubsonic/models/item_date_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'date.g.dart';

@JsonSerializable()
class Date implements Comparable<Date> {
  final int year;
  final int? month;
  final int? day;

  Date({required this.year, this.month, this.day});

  bool operator >(Date other) {
    if (year != other.year) return year > other.year;
    if ((month ?? 1) != (other.month ?? 1)) {
      return (month ?? 1) > (other.month ?? 1);
    }
    return (day ?? 1) > (other.day ?? 1);
  }

  bool operator <(Date other) {
    if (year != other.year) return year < other.year;
    if ((month ?? 1) != (other.month ?? 1)) {
      return (month ?? 1) < (other.month ?? 1);
    }
    return (day ?? 1) < (other.day ?? 1);
  }

  @override
  bool operator ==(Object other) {
    if (other is! Date) return false;
    return year == other.year &&
        (month ?? 1) == (other.month ?? 1) &&
        (day ?? 1) == (other.day ?? 1);
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  bool operator >=(Date other) {
    return this > other || this == other;
  }

  bool operator <=(Date other) {
    return this < other || this == other;
  }

  @override
  int compareTo(Date other) {
    if (this == other) return 0;
    return this < other ? -1 : 1;
  }

  factory Date.fromItemDateModel(ItemDateModel itemDate) {
    return Date(
      year: itemDate.year ?? 0,
      month: itemDate.month,
      day: itemDate.day,
    );
  }

  factory Date.fromJson(Map<String, dynamic> json) => _$DateFromJson(json);

  Map<String, dynamic> toJson() => _$DateToJson(this);

  @override
  String toString() {
    String result = year.toString().padLeft(4, "0");
    if (month != null) {
      result += "-${month.toString().padLeft(2, "0")}";
    }
    if (day != null) {
      result += "-${day.toString().padLeft(2, "0")}";
    }
    return result;
  }
}
