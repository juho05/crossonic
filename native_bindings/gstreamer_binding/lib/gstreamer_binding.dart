import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';

import 'gstreamer_binding_bindings_generated.dart';

const String _libName = 'gstreamer_binding';

/// The dynamic library in which the symbols for [GstreamerBindingBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final GstreamerBindingBindings _bindings = GstreamerBindingBindings(_dylib);

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

List<NativeCallable> _callables = [];

void freeResources() {
  _bindings.free_resources();
  for (var c in _callables) {
    c.close();
  }
  _callables.clear();
}

void init({
  void Function()? onEOS,
  void Function(int code, String message, String debugInfo)? onError,
  void Function(int code, String message)? onWarning,
  void Function(int percent, BufferingMode mode, int avgIn, int avgOut)?
      onBuffering,
  void Function(State oldState, State newState)? onStateChanged,
  void Function()? onStreamStart,
  void Function()? onAboutToFinish,
}) {
  var nOnEOS =
      onEOS != null ? NativeCallable<Void Function()>.listener(onEOS) : null;
  if (nOnEOS != null) _callables.add(nOnEOS);

  void onErrorWrapper(
      int code, Pointer<Char> message, Pointer<Char> debugInfo) {
    onError!(code, message.cast<Utf8>().toDartString(),
        debugInfo.cast<Utf8>().toDartString());
    malloc.free(message);
    malloc.free(debugInfo);
  }

  var nOnError = onError != null
      ? NativeCallable<
          Void Function(
              Int, Pointer<Char>, Pointer<Char>)>.listener(onErrorWrapper)
      : null;
  if (nOnError != null) _callables.add(nOnError);

  void onWarningWrapper(int code, Pointer<Char> message) {
    onWarning!(code, message.cast<Utf8>().toDartString());
    malloc.free(message);
  }

  var nOnWarning = onWarning != null
      ? NativeCallable<Void Function(Int, Pointer<Char>)>.listener(
          onWarningWrapper)
      : null;
  if (nOnWarning != null) _callables.add(nOnWarning);

  void onBufferingWrapper(int percent, int mode, int avgIn, int avgOut) {
    onBuffering!(percent, BufferingMode.values[mode], avgIn, avgOut);
  }

  var nOnBuffering = onBuffering != null
      ? NativeCallable<Void Function(Int, Int32, Int, Int)>.listener(
          onBufferingWrapper)
      : null;
  if (nOnBuffering != null) _callables.add(nOnBuffering);

  void onStateChangedWrapper(int oldState, int newState) {
    if (oldState == newState) return;
    onStateChanged!(State.values[oldState], State.values[newState]);
  }

  var nOnStateChanged = onStateChanged != null
      ? NativeCallable<Void Function(Int32, Int32)>.listener(
          onStateChangedWrapper)
      : null;
  if (nOnStateChanged != null) _callables.add(nOnStateChanged);

  var nOnStreamStart = onStreamStart != null
      ? NativeCallable<Void Function()>.listener(onStreamStart)
      : null;
  if (nOnStreamStart != null) _callables.add(nOnStreamStart);

  var nOnAboutToFinish = onAboutToFinish != null
      ? NativeCallable<Void Function()>.listener(onAboutToFinish)
      : null;
  if (nOnAboutToFinish != null) _callables.add(nOnAboutToFinish);

  _bindings.init(
    nOnEOS?.nativeFunction ?? Pointer.fromAddress(0),
    nOnError?.nativeFunction ?? Pointer.fromAddress(0),
    nOnWarning?.nativeFunction ?? Pointer.fromAddress(0),
    nOnBuffering?.nativeFunction ?? Pointer.fromAddress(0),
    nOnStateChanged?.nativeFunction ?? Pointer.fromAddress(0),
    nOnStreamStart?.nativeFunction ?? Pointer.fromAddress(0),
    nOnAboutToFinish?.nativeFunction ?? Pointer.fromAddress(0),
  );
}

void setState(State state) {
  var err = _bindings.set_state(state.index);
  if (err != 0) throw GstreamerException.code(err);
}

void setUrl(String url) {
  _bindings.set_url(url.toNativeUtf8().cast());
}

void setVolume(double volume) {
  _bindings.set_volume(volume.clamp(0, 1));
}

void seek(Duration pos) {
  var err = _bindings.seek(pos.inMilliseconds);
  if (err != 0) throw GstreamerException.code(err);
}

Duration getPosition() {
  return Duration(milliseconds: _bindings.get_position_ms());
}
