import 'package:bloc/bloc.dart';
import 'package:crossonic/fetch_status.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

part 'browse_event.dart';
part 'browse_state.dart';

enum BrowseType { song, album, artist }

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

class BrowseBloc extends Bloc<BrowseEvent, BrowseState> {
  final APIRepository _apiRepository;

  String _text = "";
  BrowseType _type = BrowseType.song;

  BrowseBloc(this._apiRepository)
      : super(const BrowseState(
          status: FetchStatus.initial,
          results: [],
          type: BrowseType.song,
          showGrid: true,
        )) {
    on<SearchTextChanged>((event, emit) async {
      _text = event.text;
      await _fetchResults(emit);
    }, transformer: debounce(const Duration(milliseconds: 500)));
    on<BrowseTypeChanged>((event, emit) async {
      _type = event.type;
      await _fetchResults(emit);
    }, transformer: debounce(const Duration(milliseconds: 100)));
  }

  Future<void> _fetchResults(Emitter<BrowseState> emit) async {
    if (_text.characters.length < 2) {
      emit(BrowseState(
        status: FetchStatus.success,
        results: [],
        type: _type,
        showGrid: true,
      ));
      return;
    }
    emit(BrowseState(
      status: FetchStatus.loading,
      results: [],
      type: _type,
      showGrid: false,
    ));
    try {
      List<SearchResult> results;
      switch (_type) {
        case BrowseType.song:
          results = await _fetchSongs();
        case BrowseType.album:
          results = await _fetchAlbums();
        case BrowseType.artist:
          results = await _fetchArtists();
      }
      emit(BrowseState(
          status: FetchStatus.success,
          results: results,
          type: _type,
          showGrid: false));
    } catch (e) {
      emit(BrowseState(
        status: FetchStatus.failure,
        results: [],
        type: _type,
        showGrid: false,
      ));
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
              artists: APIRepository.getArtistsOfSong(s),
              coverID: s.coverArt,
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
              artists: APIRepository.getArtistsOfAlbum(a),
              coverID: a.coverArt,
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
              coverID: a.coverArt,
              name: a.name,
              albumCount: a.albumCount ?? 0,
            ))
        .toList();
  }
}
