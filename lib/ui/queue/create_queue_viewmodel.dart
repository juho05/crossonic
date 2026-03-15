import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:flutter/material.dart';

class CreateQueueViewModel extends ChangeNotifier {
  final AudioHandler _audioHandler;

  String _name = "";
  set name(String name) {
    _name = name;
    notifyListeners();
  }

  bool get isValid => _name.isNotEmpty;

  CreateQueueViewModel({required AudioHandler audioHandler})
    : _audioHandler = audioHandler;

  Future<void> create() async {
    await _audioHandler.queue.createNewQueue(_name);
  }
}
