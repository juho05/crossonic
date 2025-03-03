import 'dart:async';
import 'dart:io';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/widgets.dart';

class CoverArtViewModel extends ChangeNotifier {
  final CoverRepository _repo;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  File? _image;
  File? get image => _image;

  StreamSubscription? _fileSubscription;

  CoverArtViewModel({required CoverRepository coverRepository})
      : _repo = coverRepository;

  String? _oldId;
  Future<void> updateId(String? id) async {
    if (_oldId == id) return;
    _oldId = id;
    await _fileSubscription?.cancel();
    _fileSubscription = null;
    if (id == null) {
      _image = null;
      _status = FetchStatus.success;
      notifyListeners();
      return;
    }
    _status = FetchStatus.initial;
    notifyListeners();
    _status = FetchStatus.loading;
    _fileSubscription = _repo.getFileStream(id).listen((file) {
      _image = file;
      _status = FetchStatus.success;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _fileSubscription?.cancel();
    super.dispose();
  }
}
