part of 'nav_bloc.dart';

sealed class NavEvent extends Equatable {
  const NavEvent();
  @override
  List<Object> get props => [];
}

final class NavPushed extends NavEvent {
  final Route route;
  const NavPushed(this.route);
}

final class NavReplaced extends NavEvent {
  final Route route;
  const NavReplaced(this.route);
}

final class NavPopped extends NavEvent {
  const NavPopped();
}

final class NavReset extends NavEvent {
  final Route route;
  const NavReset(this.route);
}

final class NavTabChanged extends NavEvent {
  final int tabIndex;
  const NavTabChanged(this.tabIndex);
}
