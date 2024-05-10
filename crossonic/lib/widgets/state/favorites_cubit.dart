import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/subsonic/subsonic_repository.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  late final StreamSubscription _favoriteUpdatesSubscription;
  final SubsonicRepository _subsonicRepository;
  FavoritesCubit(SubsonicRepository subsonicRepository)
      : _subsonicRepository = subsonicRepository,
        super(FavoritesState(HashSet(), "")) {
    _favoriteUpdatesSubscription =
        subsonicRepository.favoriteUpdates.listen(_onFavoritesUpdate);
  }

  Future<void> toggleSongFavorite(String id) async {
    if (state.favorites.contains(id)) {
      await _subsonicRepository.unstar(id: id);
      state.favorites.remove(id);
    } else {
      await _subsonicRepository.star(id: id);
      state.favorites.add(id);
    }
    emit(FavoritesState(state.favorites, id));
  }

  void _onFavoritesUpdate((String, bool) status) {
    final id = status.$1;
    final isFavorite = status.$2;
    bool changed = false;
    if (isFavorite) {
      changed = state.favorites.add(id);
    } else {
      changed = state.favorites.remove(id);
    }
    if (changed) {
      emit(FavoritesState(state.favorites, id));
    }
  }

  @override
  Future<void> close() async {
    await _favoriteUpdatesSubscription.cancel();
    return super.close();
  }
}
