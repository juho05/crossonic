part of 'search_bloc.dart';

class SearchResult {
  final String id;
  final String coverID;
  final String name;
  final String? albumID;
  final String? album;
  final Artists? artists;
  final int? year;
  final int? albumCount;
  final Media? media;

  SearchResult({
    required this.id,
    required this.coverID,
    required this.name,
    this.albumID,
    this.album,
    this.artists,
    this.year,
    this.albumCount,
    this.media,
  });
}

class SearchState {
  final FetchStatus status;
  final List<SearchResult> results;
  final SearchType type;

  const SearchState({
    required this.status,
    required this.results,
    required this.type,
  });
}
