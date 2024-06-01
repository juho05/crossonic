// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'structured_lyrics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StructuredLyrics _$StructuredLyricsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'StructuredLyrics',
      json,
      ($checkedConvert) {
        final val = StructuredLyrics(
          lang: $checkedConvert('lang', (v) => v as String),
          synced: $checkedConvert('synced', (v) => v as bool),
          displayArtist: $checkedConvert('displayArtist', (v) => v as String?),
          displayTitle: $checkedConvert('displayTitle', (v) => v as String?),
          offset: $checkedConvert('offset', (v) => (v as num?)?.toInt()),
          line: $checkedConvert(
              'line',
              (v) => (v as List<dynamic>)
                  .map((e) => Line.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$StructuredLyricsToJson(StructuredLyrics instance) {
  final val = <String, dynamic>{
    'lang': instance.lang,
    'synced': instance.synced,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('displayArtist', instance.displayArtist);
  writeNotNull('displayTitle', instance.displayTitle);
  writeNotNull('offset', instance.offset);
  val['line'] = instance.line;
  return val;
}

Line _$LineFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Line',
      json,
      ($checkedConvert) {
        final val = Line(
          start: $checkedConvert('start', (v) => (v as num?)?.toInt()),
          value: $checkedConvert('value', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$LineToJson(Line instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('start', instance.start);
  val['value'] = instance.value;
  return val;
}
