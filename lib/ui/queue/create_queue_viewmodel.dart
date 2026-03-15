import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:flutter/material.dart';

class CreateQueueViewModel extends ChangeNotifier {
  final AudioHandler _audioHandler;

  String _name = "";
  set name(String name) {
    _name = name;
    notifyListeners();
  }

  bool _copyCurrent = true;
  bool get copyCurrent => _copyCurrent;
  set copyCurrent(bool value) {
    _copyCurrent = value;
    notifyListeners();
  }

  bool get isValid => _name.isNotEmpty;

  CreateQueueViewModel({required AudioHandler audioHandler})
    : _audioHandler = audioHandler;

  Future<void> create() async {
    await _audioHandler.queue.createNewQueue(_name, copyCurrent: _copyCurrent);
  }
}
