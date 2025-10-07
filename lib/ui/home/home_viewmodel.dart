import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeLayoutSettings _settings;
  final SubsonicRepository _subsonic;

  final StreamController<bool> _refreshStream = StreamController.broadcast();
  Stream<bool> get refreshStream => _refreshStream.stream;

  List<HomeContentOption> _content = [];
  List<HomeContentOption> get content => _content;

  String? _seed;
  String? get seed => _seed;

  HomeViewModel(
      {required HomeLayoutSettings settings,
      required SubsonicRepository subsonicRepository})
      : _settings = settings,
        _subsonic = subsonicRepository {
    if (_subsonic.supports.randomSeed) {
      _seed = Random().nextDouble().toString();
    }
    _settings.addListener(_onChanged);
    _onChanged();
  }

  void refresh(bool refreshRandom) async {
    if (refreshRandom && _subsonic.supports.randomSeed) {
      _seed = Random().nextDouble().toString();
      notifyListeners();
    }
    _refreshStream.add(refreshRandom);
  }

  void _onChanged() {
    _content = _settings.selectedOptions.toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _settings.removeListener(_onChanged);
    _refreshStream.close();
    super.dispose();
  }
}
