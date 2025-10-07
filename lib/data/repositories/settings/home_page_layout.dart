import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter/material.dart';

enum HomeContentOption {
  recentlyAddedReleases,
  randomReleases,
  favoriteReleases,
  recentlyPlayedReleases,
  frequentlyPlayedReleases,
  randomSongs,
  favoriteSongs,
  randomArtists,
  favoriteArtists,
}

class HomeLayoutSettings extends ChangeNotifier {
  final KeyValueRepository _repo;

  static const String _selectedOptionsKey = "home_page_layout.selected_options";
  static const Iterable<HomeContentOption> _selectedOptionsDefault = [
    HomeContentOption.recentlyAddedReleases,
    HomeContentOption.randomSongs,
  ];
  List<HomeContentOption> _selectedOptions = _selectedOptionsDefault.toList();
  Iterable<HomeContentOption> get selectedOptions => _selectedOptions;

  HomeLayoutSettings({required KeyValueRepository keyValueRepository})
      : _repo = keyValueRepository;

  Future<void> load() async {
    _selectedOptions = (await _repo.loadStringList(_selectedOptionsKey))
            ?.map((s) => HomeContentOption.values.byName(s))
            .toList() ??
        _selectedOptionsDefault.toList();
    notifyListeners();
  }

  void reset() {
    Log.debug("resetting home page layout");
    _selectedOptions = _selectedOptionsDefault.toList();
    notifyListeners();
    _repo.remove(_selectedOptionsKey);
  }

  set selectedOptions(Iterable<HomeContentOption> selectedOptions) {
    if (const IterableEquality()
        .equals(this.selectedOptions, selectedOptions)) {
      return;
    }
    Log.debug(
        "home page layout: ${selectedOptions.map((o) => o.name).join(", ")}");
    _selectedOptions = selectedOptions.toList();
    notifyListeners();
    _repo.store(
        _selectedOptionsKey, selectedOptions.map((o) => o.name).toList());
  }

  static String optionTitle(HomeContentOption option) {
    return switch (option) {
      HomeContentOption.recentlyAddedReleases => "Recently added releases",
      HomeContentOption.randomReleases => "Random releases",
      HomeContentOption.favoriteReleases => "Favorite releases",
      HomeContentOption.recentlyPlayedReleases => "Recently played releases",
      HomeContentOption.frequentlyPlayedReleases =>
        "Frequently played releases",
      HomeContentOption.randomSongs => "Random songs",
      HomeContentOption.favoriteSongs => "Favorite songs",
      HomeContentOption.randomArtists => "Random artists",
      HomeContentOption.favoriteArtists => "Favorite artists",
    };
  }
}
