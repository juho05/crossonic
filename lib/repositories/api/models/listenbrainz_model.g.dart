// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'listenbrainz_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListenBrainzConfig _$ListenBrainzConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ListenBrainzConfig',
      json,
      ($checkedConvert) {
        final val = ListenBrainzConfig(
          listenBrainzUsername:
              $checkedConvert('listenBrainzUsername', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ListenBrainzConfigToJson(ListenBrainzConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('listenBrainzUsername', instance.listenBrainzUsername);
  return val;
}
