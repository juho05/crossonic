import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/connect/models/device.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class ConnectManager {
  final APIRepository _apiRepository;
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;

  final BehaviorSubject<List<Device>> connectedDevices =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<Device?> controllingDevice =
      BehaviorSubject.seeded(null);

  ConnectManager({required APIRepository apiRepository})
      : _apiRepository = apiRepository {
    _apiRepository.authStatus.listen((value) async {
      if (value == AuthStatus.authenticated) {
        await connect();
      } else {
        await disconnect();
      }
    });
  }

  Future<void> connect() async {
    if (_channel != null) await disconnect();
    final queryStr = Uri(
        queryParameters: _apiRepository.generateQuery({
      "name": [_name],
      "platform": [_platform],
    })).query;
    final url = Uri.parse(
        '${_apiRepository.serverURL.replaceFirst("http", "ws")}/rest/crossonic/connect?$queryStr');
    _channel = WebSocketChannel.connect(url);
    _streamSubscription = _channel!.stream.listen(
        (event) => _handleMessage(jsonDecode(event)),
        onDone: disconnect);
    try {
      await _channel!.ready;
    } catch (e) {
      print(e);
      _channel = null;
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    try {
      switch (msg["op"]) {
        case "new-device":
          _handleNewDevice(msg);
        case "device-disconnected":
          _handleDeviceDisconnected(msg);
        case "update-listener":
          _handleUpdateListener(msg);
        default:
          print("Received unknown websocket op: ${msg["op"]}");
      }
    } catch (e) {
      print("Failed to handle websocket message: $e");
    }
  }

  void _handleNewDevice(Map<String, dynamic> msg) {
    final device = Device.fromJson(msg["payload"]);
    final devices = List<Device>.from(connectedDevices.value);
    devices.add(device);
    connectedDevices.add(devices);
  }

  void _handleDeviceDisconnected(Map<String, dynamic> msg) {
    final deviceID = msg["payload"]["id"];
    final devices = List<Device>.from(connectedDevices.value);
    devices.removeWhere((d) => d.id == deviceID);
    connectedDevices.add(devices);
  }

  void _handleUpdateListener(Map<String, dynamic> msg) {
    print("update-listener request received");
  }

  Future<void> disconnect() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    connectedDevices.add([]);
    controllingDevice.add(null);
  }

  String get _name {
    if (kIsWeb) return "Crossonic Web";
    return Platform.localHostname;
  }

  String get _platform {
    if (kIsWeb) return "web";
    if (Platform.isAndroid || Platform.isIOS) return "phone";
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return "desktop";
    }
    return "unknown";
  }
}
