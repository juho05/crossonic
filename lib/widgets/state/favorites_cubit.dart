import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api_repository.dart';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  late final StreamSubscription _favoriteUpdatesSubscription;
  final APIRepository _apiRepository;
  FavoritesCubit(APIRepository apiRepository)
      : _apiRepository = apiRepository,
        super(FavoritesState(HashSet(), "")) {
    _favoriteUpdatesSubscription =
        apiRepository.favoriteUpdates.listen(_onFavoritesUpdate);
  }

  Future<void> toggleFavorite(String id) async {
    if (state.favorites.contains(id)) {
      state.favorites.remove(id);
      try {
        await _apiRepository.unstar(id: id);
      } catch (_) {
        state.favorites.add(id);
      }
    } else {
      state.favorites.add(id);
      try {
        await _apiRepository.star(id: id);
      } catch (_) {
        state.favorites.remove(id);
      }
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
