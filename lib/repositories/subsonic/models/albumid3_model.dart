import 'package:crossonic/repositories/subsonic/models/artistid3_model.dart';
import 'package:crossonic/repositories/subsonic/models/disc_title_model.dart';
import 'package:crossonic/repositories/subsonic/models/item_date_model.dart';
import 'package:crossonic/repositories/subsonic/models/item_genre_model.dart';
import 'package:crossonic/repositories/subsonic/models/record_label_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'albumid3_model.g.dart';

@JsonSerializable()
class AlbumID3 {
  final String id;
  final String name;
  final String? artist;
  final String? artistID;
  final String? coverArt;
  final int songCount;
  final int duration;
  final int? playCount;
  final DateTime created;
  final DateTime? starred;
  final int? year;
  final String? genre;
  final DateTime? played;
  final int? userRating;
  final List<RecordLabel>? recordLabels;
  final String? musicBrainzId;
  final List<ItemGenre>? genres;
  final List<ArtistID3>? artists;
  final String? displayArtist;
  final List<String>? releaseTypes;
  final List<String>? moods;
  final String? sortName;
  final ItemDate? originalReleaseDate;
  final ItemDate? releaseDate;
  final bool? isCompilation;
  final List<DiscTitle>? discTitles;

  factory AlbumID3.fromJson(Map<String, dynamic> json) =>
      _$AlbumID3FromJson(json);

  AlbumID3({
    required this.id,
    required this.name,
    this.artist,
    this.artistID,
    this.coverArt,
    required this.songCount,
    required this.duration,
    this.playCount,
    required this.created,
    this.starred,
    this.year,
    this.genre,
    this.played,
    required this.userRating,
    this.recordLabels,
    this.musicBrainzId,
    this.genres,
    this.artists,
    this.displayArtist,
    this.releaseTypes,
    this.moods,
    this.sortName,
    this.originalReleaseDate,
    this.releaseDate,
    this.isCompilation,
    this.discTitles,
  });
}
