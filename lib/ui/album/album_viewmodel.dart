import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
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
  String get id => _albumId ?? "";

  String _name = "";
  String get name => _name;

  String _coverId = "";
  String get coverId => _coverId;

  List<({String id, String name})> _artists = [];
  List<({String id, String name})> get artists => _artists;

  String _displayArtist = "";
  String get displayArtist => _displayArtist;

  int? _year;
  int? get year => _year;

  List<Song> _songs = [];
  List<Song> get songs => _songs;

  // either disc nr or song
  List<(int?, (Song, int)?)> _listItems = [];
  // either disc nr or song and song index
  List<(int?, (Song, int)?)> get listItems => _listItems;

  Map<int, String> _discTitles = {};
  Map<int, String> get discTitles => _discTitles;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

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
    _onFavoritesChanged();
    _status = FetchStatus.loading;
    _description = null;
    notifyListeners();
    final result = await _subsonic.getAlbum(albumId);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        final album = result.value;
        _name = album.name;
        _coverId = album.coverId;
        _artists = album.artists.toList();
        _displayArtist = album.displayArtist;
        _year = album.year;
        _songs = album.songs ?? [];
        _discTitles = album.discTitles;

        final discCount = _songs.map((s) => s.discNr ?? 1).toSet().length;
        if (_discTitles.isNotEmpty || discCount > 1) {
          _listItems = List.filled(_songs.length + discCount, (null, null));
          int prevDisc = 0;
          int insertIndex = 0;
          for (int i = 0; i < _songs.length; i++) {
            final s = _songs[i];
            final disc = s.discNr ?? 1;
            if (disc > prevDisc) {
              prevDisc = disc;
              _listItems[insertIndex] = (disc, null);
              insertIndex++;
            }
            _listItems[insertIndex] = (null, (s, i));
            insertIndex++;
          }
          assert(insertIndex == _listItems.length);
        } else {
          _listItems = List.generate(
              _songs.length, (index) => (null, (_songs[index], index)));
        }

        _status = FetchStatus.success;
    }
    notifyListeners();

    _loadDescription(albumId);
  }

  void play([int index = 0, bool single = false]) {
    if (_songs.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([_songs[index]]);
    } else {
      _audioHandler.queue.replace(_songs, index);
    }
  }

  void playDisc(int disc, {bool shuffle = false}) {
    final songs = _songs.where((song) => song.discNr == disc).toList();
    if (shuffle) {
      songs.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs);
  }

  void addDiscToQueue(int disc, bool priority) {
    final songs = _songs.where((song) => song.discNr == disc).toList();
    if (songs.isEmpty) return;
    _audioHandler.queue.addAll(songs, priority);
  }

  void shuffle() {
    if (_songs.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(List.of(_songs)..shuffle());
  }

  void addToQueue(bool priority) {
    if (_songs.isEmpty) return;
    _audioHandler.queue.addAll(_songs, priority);
  }

  Future<Result<void>> toggleFavorite() async {
    _favorite = !_favorite;
    notifyListeners();
    final result =
        await _favorites.setFavorite(FavoriteType.album, _albumId!, favorite);
    if (result is Err) {
      _favorite = !_favorite;
      notifyListeners();
    }
    return result;
  }

  Future<void> _loadDescription(String albumId) async {
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
