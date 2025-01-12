part of 'browse_bloc.dart';

class SearchResult {
  final String id;
  final String? coverID;
  final String name;
  final String? albumID;
  final String? album;
  final Artists? artists;
  final int? year;
  final int? albumCount;
  final Media? media;

  SearchResult({
    required this.id,
    required this.name,
    this.coverID,
    this.albumID,
    this.album,
    this.artists,
    this.year,
    this.albumCount,
    this.media,
  });
}

class BrowseState {
  final FetchStatus status;
  final List<SearchResult> results;
  final BrowseType type;
  final bool showGrid;

  const BrowseState({
    required this.status,
    required this.results,
    required this.type,
    required this.showGrid,
  });
}
