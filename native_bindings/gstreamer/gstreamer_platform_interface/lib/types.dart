enum ErrorType {
  none,
  unknown,
  createElements,
  setPlaybinState,
  seekingNotSupported,
}

class GstreamerException implements Exception {
  late final ErrorType type;
  GstreamerException(this.type);

  GstreamerException.code(int code) {
    try {
      type = ErrorType.values[code];
    } catch (_) {
      type = ErrorType.unknown;
    }
  }
}

enum BufferingMode {
  stream,
  download,
  timeshift,
  live,
}

enum State {
  voidPending,
  initial,
  ready,
  paused,
  playing,
}
