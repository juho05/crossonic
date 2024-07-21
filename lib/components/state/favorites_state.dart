part of 'favorites_cubit.dart';

class FavoritesState {
  final HashSet<String> favorites;
  final String changedId;

  const FavoritesState(this.favorites, this.changedId);
}
