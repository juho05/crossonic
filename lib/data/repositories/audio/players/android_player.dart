import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

class AudioPlayerAndroid extends AudioPlayer {
  AudioPlayerAndroid({
    required super.downloader,
    required super.setVolumeHandler,
    required super.setQueueHandler,
    required super.setLoopHandler,
    required super.playNextHandler,
    required super.playPrevHandler,
  });

  @override
  Future<Duration> get position async => Duration.zero; // TODO

  @override
  Future<Duration> get bufferedPosition async => Duration.zero; // tODO

  @override
  double get volume => 1; // TODO

  @override
  Future<void> init({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
  }) async {
    super.init(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
    );
    // TODO
  }

  @override
  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    super.setCurrent(current, next: next, pos: pos);
    // TODO
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);
    // TODO
  }

  @override
  Future<void> pause() async {
    // TODO
  }

  @override
  Future<void> play() async {
    // TODO
  }

  @override
  Future<void> seek(Duration position) async {
    if (format == "raw" || !supportsTimeOffset) {
      // TODO player seek
      return;
    }
    // TODO url seek
  }

  @override
  Future<void> setVolume(double volume) async {
    // TODO
  }

  @override
  Future<void> stop() async {
    // TODO
  }

  @override
  Future<void> dispose() async {
    // TODO
    super.dispose();
  }
}
