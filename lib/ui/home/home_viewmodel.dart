import 'dart:async';

import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:flutter/foundation.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeLayoutSettings _settings;

  final StreamController<bool> _refreshStream = StreamController.broadcast();
  Stream<bool> get refreshStream => _refreshStream.stream;

  List<HomeContentOption> _content = [];
  List<HomeContentOption> get content => _content;

  HomeViewModel({required HomeLayoutSettings settings}) : _settings = settings {
    _settings.addListener(_onChanged);
    _onChanged();
  }

  void refresh(bool refreshRandom) async {
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
