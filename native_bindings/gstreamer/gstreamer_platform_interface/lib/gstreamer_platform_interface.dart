import 'package:gstreamer_platform_interface/gstreamer_stub.dart';
import 'package:gstreamer_platform_interface/types.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GstreamerPlatform extends PlatformInterface {
  GstreamerPlatform() : super(token: _token);

  static final Object _token = Object();

  static GstreamerPlatform _instance = GstreamerStub();

  static GstreamerPlatform get instance => _instance;

  static set instance(GstreamerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void freeResources() =>
      throw UnimplementedError("freeResources() not implemented");

  void init({
    void Function()? onEOS,
    void Function(int code, String message, String debugInfo)? onError,
    void Function(int code, String message)? onWarning,
    void Function(int percent, BufferingMode mode, int avgIn, int avgOut)?
        onBuffering,
    void Function(State oldState, State newState)? onStateChanged,
    void Function()? onStreamStart,
    void Function()? onAboutToFinish,
  }) =>
      throw UnimplementedError("init() not implemented");

  void setState(State state) =>
      throw UnimplementedError("setState() not implemented");

  void setUrl(String url) =>
      throw UnimplementedError("setUrl() not implemented");

  void setVolume(double volume) =>
      throw UnimplementedError("setVolume() not implemented");

  void seek(Duration pos) => throw UnimplementedError("seek() not implemented");

  Duration getPosition() =>
      throw UnimplementedError("getPosition() not implemented");

  void waitUntilReady() =>
      throw UnimplementedError("waitUntilReady() not implemented");
}
