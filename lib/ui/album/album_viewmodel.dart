import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AlbumViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final FavoritesRepository _favorites;
  final AudioHandler _audioHandler;

  String? _albumId;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Album? _album;
  Album? get album => _album;

  String? _description;
  String? get description => _description;

  bool _favorite = false;
  bool get favorite => _favorite;

  AlbumViewModel(
      {required FavoritesRepository favoritesRepository,
      required SubsonicRepository subsonicRepository,
      required AudioHandler audioHandler})
      : _favorites = favoritesRepository,
        _subsonic = subsonicRepository,
        _audioHandler = audioHandler {
    _favorites.addListener(_onFavoritesChanged);
    _onFavoritesChanged();
  }

  void _onFavoritesChanged() {
    if (_albumId == null) return;
    final favorite = _favorites.isFavorite(FavoriteType.album, _albumId!);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  Future<void> load(String albumId) async {
    _albumId = albumId;
    _status = FetchStatus.loading;
    _album = null;
    notifyListeners();
    final result = await _subsonic.getAlbum(albumId);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _album = result.value;
        _status = FetchStatus.success;
    }
    notifyListeners();

    _loadDescription(albumId);
  }

  void play([int index = 0]) {
    if ((album!.songs ?? []).isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(album!.songs!, index);
  }

  void playDisc(int disc) {
    final songs =
        (album!.songs ?? []).where((song) => song.discNr == disc).toList();
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs);
  }

  void shuffle() {
    if ((album!.songs ?? []).isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(List.of(album!.songs!)..shuffle());
  }

  void addToQueue(bool priority) {
    if ((album!.songs ?? []).isEmpty) return;
    _audioHandler.queue.addAll(album!.songs!, priority);
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !_favorite;
    notifyListeners();
    final result =
        await _favorites.setFavorite(FavoriteType.album, album!.id, !favorite);
    if (result is Err) {
      _favorite = !_favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> _loadDescription(String albumId) async {
    _description = null;
    notifyListeners();
    final result = await _subsonic.getAlbumInfo(albumId);
    if (result is Ok) {
      _description = result.tryValue?.description ?? "";
    } else {
      _description = "";
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }
}
