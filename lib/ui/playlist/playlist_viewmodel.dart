import 'dart:async';
import 'dart:io';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageTooLargeException extends AppException {
  ImageTooLargeException() : super("Image too large");
}

class PlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;
  final AudioHandler _audioHandler;
  final SongDownloader _downloader;

  final String _playlistId;

  Playlist? _playlist;
  Playlist? get playlist => _playlist;

  List<(Song, DownloadStatus)> _tracks = [];
  List<(Song, DownloadStatus)> get tracks => _tracks;

  DownloadStatus _downloadStatus = DownloadStatus.none;
  DownloadStatus get downloadStatus => _downloadStatus;

  int _downloadedTracks = 0;
  int get downloadedTracks => _downloadedTracks;

  bool _reorderEnabled = false;
  bool get reorderEnabled => _reorderEnabled;
  set reorderEnabled(bool enable) {
    _reorderEnabled = enable;
    notifyListeners();
  }

  bool get changeCoverSupported => _repo.changeCoverSupported;

  bool _uploadingCover = false;
  bool get uploadingCover => _uploadingCover;

  PlaylistViewModel({
    required PlaylistRepository playlistRepository,
    required AudioHandler audioHandler,
    required SongDownloader songDownloader,
    required String playlistId,
  })  : _repo = playlistRepository,
        _audioHandler = audioHandler,
        _downloader = songDownloader,
        _playlistId = playlistId {
    _downloader.addListener(_onDownloadStatusChanged);
    _repo.addListener(_load);
    _load();
    _repo.refresh(forceRefresh: true, refreshIds: {_playlistId});
  }

  Throttle? _onDownloadStatusChangedThrottle;

  void _onDownloadStatusChanged() {
    void update() {
      if (_playlist == null || !_playlist!.download) return;
      bool changed = false;
      bool fullDownload = true;
      int downloadedCount = 0;
      for (var i = 0; i < tracks.length; i++) {
        final t = tracks[i];
        final status = _downloader.getStatus(t.$1.id);
        if (status != t.$2) {
          changed = true;
          _tracks[i] = (t.$1, status);
        }
        if (status != DownloadStatus.downloaded) {
          fullDownload = false;
        } else {
          downloadedCount++;
        }
      }
      _downloadedTracks = downloadedCount;
      _downloadStatus = !_playlist!.download
          ? DownloadStatus.none
          : (fullDownload
              ? DownloadStatus.downloaded
              : DownloadStatus.downloading);
      if (changed) {
        notifyListeners();
      }
    }

    _onDownloadStatusChangedThrottle ??= Throttle(
      action: update,
      delay: const Duration(milliseconds: 250),
      leading: false,
    );
    _onDownloadStatusChangedThrottle!.call();
  }

  Future<Result<void>> toggleDownload() async {
    final newState = !_playlist!.download;
    final result = await _repo.setDownload(_playlistId, newState);
    if (result is Ok) {
      _downloadStatus =
          newState ? DownloadStatus.downloading : DownloadStatus.none;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> changeCover() async {
    XFile? image;
    if (!kIsWeb && Platform.isLinux) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: false,
        withReadStream: false,
        allowedExtensions: ["jpg", "jpeg", "png", "gif", "bmp", "tif", "tiff"],
      );
      image = result?.xFiles.firstOrNull;
    } else {
      image = await ImagePicker().pickImage(source: ImageSource.gallery);
    }
    if (image == null) {
      return const Result.ok(null);
    }
    final size = await image.length();
    if (size > 15e6) {
      return Result.error(ImageTooLargeException());
    }
    _uploadingCover = true;
    notifyListeners();

    var mimeType = image.mimeType ??
        switch (path.extension(image.path).toLowerCase()) {
          ".avif" => "image/avif",
          ".jpg" => "image/jpeg",
          ".jpeg" => "image/jpeg",
          ".png" => "image/png",
          ".gif" => "image/gif",
          ".bmp" => "image/bmp",
          ".tif" => "image/tiff",
          ".tiff" => "image/tiff",
          ".heif" => "image/heif",
          ".heic" => "image/heic",
          _ => "application/octet-stream",
        };
    final r =
        await _repo.setCover(_playlistId, mimeType, await image.readAsBytes());
    _uploadingCover = false;
    notifyListeners();
    return r;
  }

  Future<Result<void>> removeCover() async {
    _uploadingCover = true;
    notifyListeners();
    final result = await _repo.setCover(_playlistId, "", Uint8List(0));
    _uploadingCover = false;
    notifyListeners();
    return result;
  }

  Future<void> _load() async {
    final result = await _repo.getPlaylist(_playlistId);
    switch (result) {
      case Err():
        _playlist = null;
        Log.error("Failed to get playlist '$_playlistId'", e: result.error);
      case Ok():
        if (result.value == null) {
          _playlist = null;
          Log.error("playlist '$_playlistId' does not exist");
        }
        _playlist = result.value!.playlist;
        _tracks = result.value!.tracks
            .map((t) => (t, _downloader.getStatus(t.id)))
            .toList();
        _downloadedTracks = 0;
        if (_playlist!.download) {
          _downloadStatus = DownloadStatus.downloaded;
          bool fullDownload = true;
          for (final t in _tracks) {
            if (t.$2 != DownloadStatus.downloaded) {
              fullDownload = false;
            } else {
              _downloadedTracks++;
            }
          }
          _downloadStatus = fullDownload
              ? DownloadStatus.downloaded
              : DownloadStatus.downloading;
        } else {
          _downloadStatus = DownloadStatus.none;
        }
    }
    notifyListeners();
  }

  void play([int index = 0, bool single = false]) {
    if (tracks.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([tracks[index].$1]);
    } else {
      _audioHandler.queue.replace(tracks.map((t) => t.$1), index);
    }
  }

  void shuffle() {
    if (tracks.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(List.of(tracks.map((t) => t.$1))..shuffle());
  }

  void addToQueue(bool priority) {
    if (tracks.isEmpty) return;
    _audioHandler.queue.addAll(tracks.map((t) => t.$1), priority);
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  Future<Result<void>> remove(int index) async {
    tracks.removeAt(index);
    notifyListeners();
    return await _repo.removeTrack(_playlistId, index);
  }

  Future<Result<void>> reorder(int oldIndex, int newIndex) async {
    final s = tracks.removeAt(oldIndex);
    if (oldIndex < newIndex) {
      tracks.insert(newIndex - 1, s);
    } else {
      tracks.insert(newIndex, s);
    }
    notifyListeners();
    return await _repo.reorder(_playlistId, oldIndex, newIndex);
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    _downloader.removeListener(_onDownloadStatusChanged);
    _onDownloadStatusChangedThrottle?.cancel();
    super.dispose();
  }
}
