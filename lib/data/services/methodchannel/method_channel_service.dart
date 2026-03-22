/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef EventCallback =
    void Function(String event, Map<Object?, dynamic>? data);
typedef MethodCallback<R, A> = Future<R> Function(A? arguments);

class MethodChannelService {
  final _methodChannel = const MethodChannel(
    "org.crossonic.app.player.methods",
  );
  final _eventChannel = const EventChannel("org.crossonic.app.player.events");
  final Set<EventCallback> _eventCallbacks = {};
  final Map<String, MethodCallback<dynamic, dynamic>> _methodCallbacks = {};

  final Map<String, List<(MethodCall, Completer<dynamic>)>> _unhandledCalls =
      {};

  MethodChannelService() {
    if (kIsWeb || !Platform.isAndroid) return;
    _methodChannel.setMethodCallHandler((call) async {
      if (!_methodCallbacks.containsKey(call.method)) {
        _unhandledCalls.putIfAbsent(call.method, () => []);
        final completer = Completer();
        _unhandledCalls[call.method]!.add((call, completer));
        return await completer.future;
      }
      return await _methodCallbacks[call.method]!(call.arguments);
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

  Future<void> handleMethodCall<R, A>(
    String method,
    MethodCallback<R, A> callback,
  ) async {
    _methodCallbacks[method] = (a) => callback(a);
    if (_unhandledCalls.containsKey(method)) {
      final list = _unhandledCalls[method]!;
      _unhandledCalls.remove(method);
      for (final c in list) {
        try {
          final result = await callback(c.$1.arguments);
          c.$2.complete(result);
        } catch (e, st) {
          c.$2.completeError(e, st);
        }
      }
    }
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
