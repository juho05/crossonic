import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ArtistViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final FavoritesRepository _favorites;
  final AudioHandler _audioHandler;

  String? _artistId;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Artist? _artist;
  Artist? get artist => _artist;

  String? _description;
  String? get description => _description;

  bool _favorite = false;
  bool get favorite => _favorite;

  ArtistViewModel(
      {required SubsonicRepository subsonicRepository,
      required FavoritesRepository favoritesRepository,
      required AudioHandler audioHandler})
      : _subsonic = subsonicRepository,
        _favorites = favoritesRepository,
        _audioHandler = audioHandler {
    _favorites.addListener(_onFavoritesChanged);
    _onFavoritesChanged();
  }

  void _onFavoritesChanged() {
    if (_artistId == null) return;
    final favorite = _favorites.isFavorite(FavoriteType.artist, _artistId!);
    if (favorite != _favorite) {
      _favorite = favorite;
      notifyListeners();
    }
  }

  Future<void> load(String artistId) async {
    _artistId = artistId;
    _onFavoritesChanged();
    _status = FetchStatus.loading;
    _artist = null;
    notifyListeners();
    final result = await _subsonic.getArtist(artistId);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _artist = result.value;
        _status = FetchStatus.success;
    }
    notifyListeners();

    _loadDescription(artistId);
  }

  Future<Result<void>> playAlbum(Album album, {bool shuffle = false}) async {
    final result = await _loadAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffle) {
      result.value.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(result.value);
    return Result.ok(null);
  }

  Future<Result<void>> play(
      {bool shuffleAlbums = false, bool shuffleSongs = false}) async {
    final result = await _loadSongs();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffleAlbums) {
      result.value.shuffle();
    }
    final songs = result.value.expand((l) => l).toList();
    if (shuffleSongs) {
      songs.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs);
    return Result.ok(null);
  }

  Future<Result<void>> addToQueue(bool priority) async {
    final result = await _loadSongs();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value.expand((l) => l), priority);
    return Result.ok(null);
  }

  Future<Result<void>> addAlbumToQueue(Album album, bool priority) async {
    final result = await _loadAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return Result.ok(null);
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !_favorite;
    notifyListeners();
    final result =
        await _favorites.setFavorite(FavoriteType.artist, artist!.id, favorite);
    if (result is Err) {
      _favorite = !_favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> _loadDescription(String albumId) async {
    _description = null;
    notifyListeners();
    final result = await _subsonic.getArtistInfo(albumId);
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

  Future<Result<List<List<Song>>>> _loadSongs() async {
    final results = await Future.wait(
        (_artist?.albums ?? []).map((a) => _loadAlbumSongs(a)));
    final result = <List<Song>>[];
    for (var r in results) {
      switch (r) {
        case Err():
          return Result.error(r.error);
        case Ok():
          result.add(r.value);
      }
    }
    return Result.ok(result);
  }

  Future<Result<List<Song>>> _loadAlbumSongs(Album album) async {
    if (album.songs != null) return Result.ok(album.songs!);
    final result = await _subsonic.getAlbum(album.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.songs ?? []);
  }
}
