part of 'nav_bloc.dart';

final class NavState extends Equatable {
  final bool canPop;
  final int tabIndex;

  const NavState(this.canPop, this.tabIndex);

  NavState copyWith({
    bool? canPop,
    int? tabIndex,
  }) {
    return NavState(canPop ?? this.canPop, tabIndex ?? this.tabIndex);
  }

  @override
  List<Object> get props => [canPop, tabIndex];
}
