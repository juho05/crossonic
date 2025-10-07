import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/datetime_converter.dart';
import 'package:crossonic/data/services/opensubsonic/models/item_date_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'albumid3_model.g.dart';

@JsonSerializable()
class AlbumID3Model {
  final String id;
  final String name;
  final String? version;
  final String? artist;
  final String? artistId;
  final String? coverArt;
  final int songCount;
  final int duration;
  final int? playCount;
  @DateTimeConverter()
  final DateTime created;
  @DateTimeConverter()
  final DateTime? starred;
  final int? year;
  final String? genre;
  @DateTimeConverter()
  final DateTime? played;
  final int? userRating;
  final double? averageRating;
  final List<({String name})>? recordLabels;
  final String? musicBrainzId;
  final String? releaseMbid;
  final List<({String name})>? genres;
  final List<({String id, String name})>? artists;
  final String? displayArtist;
  final List<String>? releaseTypes;
  final List<String>? moods;
  final String? sortName;
  final ItemDateModel? originalReleaseDate;
  final ItemDateModel? releaseDate;
  final bool? isCompilation;
  // "explicit" (>0 songs explicit), "clean" (0 songs explicit, > 0 songs 'clean') or "" (otherwise)
  final String? explicitStatus;
  final List<({int disc, String title})>? discTitles;
  final List<ChildModel>? song;

  AlbumID3Model({
    required this.id,
    required this.name,
    required this.version,
    required this.artist,
    required this.artistId,
    required this.coverArt,
    required this.songCount,
    required this.duration,
    required this.playCount,
    required this.created,
    required this.starred,
    required this.year,
    required this.genre,
    required this.played,
    required this.userRating,
    required this.averageRating,
    required this.recordLabels,
    required this.musicBrainzId,
    required this.releaseMbid,
    required this.genres,
    required this.artists,
    required this.displayArtist,
    required this.releaseTypes,
    required this.moods,
    required this.sortName,
    required this.originalReleaseDate,
    required this.releaseDate,
    required this.isCompilation,
    required this.explicitStatus,
    required this.discTitles,
    required this.song,
  });

  factory AlbumID3Model.fromJson(Map<String, dynamic> json) =>
      _$AlbumID3ModelFromJson(json);

  Map<String, dynamic> toJson() => _$AlbumID3ModelToJson(this);
}
