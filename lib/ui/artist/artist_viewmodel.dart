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
  static const Map<ReleaseType, int> _releaseTypeOrder = {
    ReleaseType.album: 0,
    ReleaseType.ep: 1,
    ReleaseType.live: 2,
    ReleaseType.compilation: 3,
    ReleaseType.single: 4,
    ReleaseType.remix: 5,
    ReleaseType.demo: 6,
  };

  static Map<ReleaseType, String> releaseTypeTitles = {
    ReleaseType.album: "Albums",
    ReleaseType.ep: "EPs",
    ReleaseType.live: "Live",
    ReleaseType.compilation: "Compilations",
    ReleaseType.single: "Singles",
    ReleaseType.remix: "Remixes",
    ReleaseType.demo: "Demos",
  };

  final SubsonicRepository _subsonic;
  final FavoritesRepository _favorites;
  final AudioHandler _audioHandler;

  String? _artistId;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Artist? _artist;
  Artist? get artist => _artist;

  List<Album> _appearsOn = const [];
  List<Album> get appearsOn => _appearsOn;

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
        notifyListeners();
        return;
      case Ok():
        _status = FetchStatus.success;
        _artist = result.value;
    }

    final albums = _artist!.albums;
    if (albums != null) {
      albums.sort((a, b) {
        if (a.releaseType != b.releaseType) {
          return (_releaseTypeOrder[a.releaseType] ?? 0)
              .compareTo(_releaseTypeOrder[b.releaseType] ?? 0);
        }
        return (b.year ?? 0).compareTo(a.year ?? 0);
      });
    }

    notifyListeners();

    _loadDescription(artistId);
    _loadAppearsOn(artistId);
  }

  Future<Result<void>> playReleases(ReleaseType releaseType,
      {bool shuffleReleases = false, bool shuffleSongs = false}) {
    return _queueAlbums(_getAlbumsByReleaseType(releaseType),
        play: true,
        shuffleReleases: shuffleReleases,
        shuffleSongs: shuffleSongs);
  }

  Future<Result<void>> addReleasesToQueue(
      ReleaseType releaseType, bool priority) {
    return _queueAlbums(_getAlbumsByReleaseType(releaseType),
        play: false, priorityQueue: priority);
  }

  Future<Result<void>> playAppearsOn(
      {bool shuffleReleases = false, bool shuffleSongs = false}) {
    return _queueAlbums(_appearsOn,
        play: true,
        shuffleReleases: shuffleReleases,
        shuffleSongs: shuffleSongs);
  }

  Future<Result<void>> addAppearsOnToQueue(bool priority) {
    return _queueAlbums(_appearsOn, play: false, priorityQueue: priority);
  }

  List<Album> _getAlbumsByReleaseType(ReleaseType releaseType) {
    final albums = <Album>[];
    for (Album a in _artist?.albums ?? []) {
      if (a.releaseType == releaseType) {
        albums.add(a);
        continue;
      }
      // albums is sorted so that albums of the same release type are grouped together,
      // so we can exit early
      if (albums.isNotEmpty) {
        break;
      }
    }
    return albums;
  }

  Future<Result<void>> play(
      {bool shuffleReleases = false, bool shuffleSongs = false}) {
    return _queueAlbums(artist!.albums ?? _appearsOn,
        play: true,
        shuffleReleases: shuffleReleases,
        shuffleSongs: shuffleSongs);
  }

  Future<Result<void>> addToQueue(bool priority) {
    return _queueAlbums(artist!.albums ?? _appearsOn,
        play: false, priorityQueue: priority);
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

  Future<Result<void>> _queueAlbums(Iterable<Album> albums,
      {required bool play,
      bool priorityQueue = false,
      bool shuffleReleases = false,
      bool shuffleSongs = false}) async {
    return _subsonic.incrementallyLoadSongs(
      albums,
      (songs, firstBatch) async {
        if (firstBatch && play) {
          _audioHandler.playOnNextMediaChange();
          _audioHandler.queue.replace(songs);
          return;
        }
        _audioHandler.queue.addAll(songs, priorityQueue);
      },
      shuffleAlbums: shuffleReleases,
      shuffleSongs: shuffleSongs,
    );
  }

  Future<void> _loadDescription(String artistId) async {
    _description = null;
    notifyListeners();
    final result = await _subsonic.getArtistInfo(artistId);
    if (result is Ok) {
      _description = result.tryValue?.description ?? "";
    } else {
      _description = "";
    }
    notifyListeners();
  }

  Future<void> _loadAppearsOn(String artistId) async {
    _appearsOn = const [];
    notifyListeners();
    final result = await _subsonic.getAppearsOn(artistId);
    if (result is Err) {
      return;
    }
    _appearsOn = result.tryValue?.toList() ?? [];
    if (_appearsOn.isNotEmpty) {
      notifyListeners();
    }
  }

  Future<Result<List<Song>>> getArtistSongs(Artist artist) async {
    final result = await _subsonic.getArtistSongs(artist);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        return Result.ok(result.value.expand((l) => l).toList());
    }
  }

  @override
  void dispose() {
    _favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }
}
