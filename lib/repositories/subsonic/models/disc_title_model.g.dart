// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'disc_title_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DiscTitle _$DiscTitleFromJson(Map<String, dynamic> json) => $checkedCreate(
      'DiscTitle',
      json,
      ($checkedConvert) {
        final val = DiscTitle(
          disc: $checkedConvert('disc', (v) => v as int),
          title: $checkedConvert('title', (v) => v as String),
        );
        return val;
      },
    );
