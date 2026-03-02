import 'package:flutter/services.dart';

typedef EventCallback =
    void Function(String event, Map<Object?, dynamic>? data);
typedef MethodCallback =
    Future<dynamic> Function(Map<Object?, dynamic>? arguments);

class MethodChannelService {
  final _methodChannel = const MethodChannel(
    "org.crossonic.app.player.methods",
  );
  final _eventChannel = const EventChannel("org.crossonic.app.player.events");
  final Set<EventCallback> _eventCallbacks = {};
  final Map<String, MethodCallback> _methodCallbacks = {};

  MethodChannelService() {
    _methodChannel.setMethodCallHandler((call) async {
      print("Method call received from Android: ${call.method}");
      if (!_methodCallbacks.containsKey(call.method)) {
        throw MissingPluginException(
          "no method call handler for '${call.method}' on Flutter side",
        );
      }
      print("calling callback");
      final result = await _methodCallbacks[call.method]!(call.arguments);
      print("Returning method call result to Android: $result");
      return result;
    });
    _eventChannel.receiveBroadcastStream().listen((event) async {
      final eventObj = event as Map<Object?, dynamic>;
      final data = eventObj["data"] as Map<Object?, dynamic>?;
      for (var cb in _eventCallbacks) {
        cb(eventObj["event"], data);
      }
    });
  }

  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) {
    return _methodChannel.invokeMethod(method, arguments);
  }

  void handleMethodCall(String method, MethodCallback callback) {
    _methodCallbacks[method] = callback;
  }

  void removeMethodCallHandler(String method) {
    _methodCallbacks.remove(method);
  }

  void addEventListener(EventCallback cb) {
    _eventCallbacks.add(cb);
  }

  void removeEventListener(EventCallback cb) {
    _eventCallbacks.remove(cb);
  }
}
