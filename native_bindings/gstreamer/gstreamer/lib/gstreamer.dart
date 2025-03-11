import 'package:gstreamer_platform_interface/gstreamer_platform_interface.dart';
import 'package:gstreamer_platform_interface/types.dart';

export 'package:gstreamer_platform_interface/types.dart';

void freeResources() {
  GstreamerPlatform.instance.freeResources();
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
  GstreamerPlatform.instance.init(
    onEOS: onEOS,
    onError: onError,
    onWarning: onWarning,
    onBuffering: onBuffering,
    onStateChanged: onStateChanged,
    onStreamStart: onStreamStart,
    onAboutToFinish: onAboutToFinish,
  );
}

void setState(State state) {
  GstreamerPlatform.instance.setState(state);
}

void setUrl(String url) {
  GstreamerPlatform.instance.setUrl(url);
}

void setVolume(double volume) {
  GstreamerPlatform.instance.setVolume(volume);
}

void seek(Duration pos) {
  GstreamerPlatform.instance.seek(pos);
}

Duration getPosition() {
  return GstreamerPlatform.instance.getPosition();
}

void waitUntilReady() {
  GstreamerPlatform.instance.waitUntilReady();
}
