// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: implicit_dynamic_parameter

part of 'contributor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contributor _$ContributorFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Contributor',
      json,
      ($checkedConvert) {
        final val = Contributor(
          role: $checkedConvert('role', (v) => v as String),
          subRole: $checkedConvert('subRole', (v) => v as String?),
          artist: $checkedConvert(
              'artist', (v) => ArtistID3.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );
