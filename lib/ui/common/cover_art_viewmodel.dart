import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:flutter/widgets.dart';

class CoverArtViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonicRepository;

  Uri? _uri;
  Uri? get uri => _uri;

  CoverArtViewModel({required SubsonicRepository subsonicRepository})
      : _subsonicRepository = subsonicRepository;

  void load(String id) {
    _uri = _subsonicRepository.getCoverUri(id);
    notifyListeners();
  }
}
