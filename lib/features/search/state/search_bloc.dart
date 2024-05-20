import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

part 'search_event.dart';
part 'search_state.dart';

enum SearchType { song, album, artist }

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final APIRepository _apiRepository;

  String _text = "";
  SearchType _type = SearchType.song;

  SearchBloc(this._apiRepository)
      : super(const SearchState(
            status: FetchStatus.initial, results: [], type: SearchType.song)) {
    on<SearchTextChanged>((event, emit) async {
      _text = event.text;
      await _fetchResults(emit);
    }, transformer: debounce(const Duration(milliseconds: 500)));
    on<SearchTypeChanged>((event, emit) async {
      _type = event.type;
      await _fetchResults(emit);
    }, transformer: debounce(const Duration(milliseconds: 100)));
  }

  Future<void> _fetchResults(Emitter<SearchState> emit) async {
    if (_text.characters.length < 2) {
      emit(SearchState(status: FetchStatus.success, results: [], type: _type));
      return;
    }
    emit(SearchState(status: FetchStatus.loading, results: [], type: _type));
    try {
      List<SearchResult> results;
      switch (_type) {
        case SearchType.song:
          results = await _fetchSongs();
        case SearchType.album:
          results = await _fetchAlbums();
        case SearchType.artist:
          results = await _fetchArtists();
      }
      emit(SearchState(
          status: FetchStatus.success, results: results, type: _type));
    } catch (e) {
      emit(SearchState(status: FetchStatus.failure, results: [], type: _type));
    }
  }

  Future<List<SearchResult>> _fetchSongs() async {
    final (_, _, songs) = await _apiRepository.search3(_text,
        albumCount: 0, artistCount: 0, songCount: 100);
    return songs
        .map((s) => SearchResult(
              id: s.id,
              album: s.album ?? "Unknown album",
              albumID: s.albumId ?? "",
              artist: s.artist ?? "Unknown artist",
              artistID: s.artistId ?? "",
              coverID: s.coverArt ?? "",
              name: s.title,
              year: s.year,
              media: s,
            ))
        .toList();
  }

  Future<List<SearchResult>> _fetchAlbums() async {
    final (_, albums, _) = await _apiRepository.search3(_text,
        albumCount: 100, artistCount: 0, songCount: 0);
    return albums
        .map((a) => SearchResult(
              id: a.id,
              artist: a.artist ?? "Unknown artist",
              artistID: a.artistId ?? "",
              coverID: a.coverArt ?? "",
              name: a.name,
              year: a.year,
            ))
        .toList();
  }

  Future<List<SearchResult>> _fetchArtists() async {
    final (artists, _, _) = await _apiRepository.search3(_text,
        albumCount: 0, artistCount: 100, songCount: 0);
    return artists
        .map((a) => SearchResult(
              id: a.id,
              coverID: a.coverArt ?? "",
              name: a.name,
              albumCount: a.albumCount ?? 0,
            ))
        .toList();
  }
}
