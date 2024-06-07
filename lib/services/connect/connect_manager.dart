import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/services/connect/models/device.dart';
import 'package:crossonic/services/connect/models/message.dart';
import 'package:crossonic/services/connect/models/speaker_state.dart';
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
  final BehaviorSubject<SpeakerState?> speakerState =
      BehaviorSubject.seeded(null);

  bool _shouldBeConnected = false;

  ConnectManager({required APIRepository apiRepository})
      : _apiRepository = apiRepository {
    _apiRepository.authStatus.listen((value) async {
      if (value == AuthStatus.authenticated) {
        await connect();
      } else {
        await disconnect();
      }
      controllingDevice.listen((device) async {
        await _sendListen(device?.id);
        speakerState.add(null);
      });
    });
  }

  Future<void> connect() async {
    if (_channel != null) await disconnect();
    _shouldBeConnected = false;
    final queryStr = Uri(
        queryParameters: _apiRepository.generateQuery({
      "name": [_name],
      "platform": [_platform],
    })).query;
    int retryDelaySeconds = 10;
    while (true) {
      final url = Uri.parse(
          '${_apiRepository.serverURL.replaceFirst("http", "ws")}/rest/crossonic/connect?$queryStr');
      _channel = WebSocketChannel.connect(url);
      _streamSubscription = _channel!.stream.listen(
        (event) => _handleMessage(jsonDecode(event)),
        onDone: () async {
          if (!_shouldBeConnected) return;
          await disconnect();
          await Future.delayed(const Duration(seconds: 1));
          await connect();
        },
      );
      try {
        await _channel!.ready;
        _shouldBeConnected = true;
        break;
      } catch (e) {
        print(e);
        _channel = null;
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        retryDelaySeconds = min(retryDelaySeconds * 2, 180);
      }
    }
  }

  Future<void> _sendListen(String? id) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "listen",
      target: "server",
      type: "command",
      payload: {
        "id": id,
      },
    )));
  }

  Future<void> sendPlay(String target) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "play",
      target: target,
      type: "command",
    )));
  }

  Future<void> sendPause(String target) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "pause",
      target: target,
      type: "command",
    )));
  }

  Future<void> sendStop(String target) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "stop",
      target: target,
      type: "command",
    )));
  }

  Future<void> sendSpeakerSetCurrent(String target, String songID,
      [String? nextID, Duration? timeOffset]) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "speaker-set-current",
      target: target,
      type: "command",
      payload: {
        "songId": songID,
        "nextId": nextID,
        if (timeOffset != null) "timeOffset": timeOffset.inSeconds,
      },
    )));
  }

  Future<void> sendSpeakerSetNext(String target, String? songID) async {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(Message(
      op: "speaker-set-next",
      target: target,
      type: "command",
      payload: {
        "songId": songID,
      },
    )));
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
        case "speaker-state":
          _handleSpeakerState(msg);
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

  void _handleSpeakerState(Map<String, dynamic> msg) {
    final state = SpeakerState.fromJson(msg["payload"]);
    speakerState.add(state);
  }

  Future<void> disconnect([bool unexpected = false]) async {
    _shouldBeConnected = unexpected;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    connectedDevices.add([]);
    controllingDevice.add(null);
  }

  String get _name {
    if (kIsWeb) return "Crossonic Web";
    if (Platform.localHostname != "localhost") return Platform.localHostname;
    if (Platform.isAndroid) return "Android Phone";
    if (Platform.isIOS) return "iPhone";
    if (Platform.isLinux) return "Linux PC";
    if (Platform.isLinux) return "Windows PC";
    if (Platform.isMacOS) return "Mac Computer";
    return "Unnamed Device";
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
