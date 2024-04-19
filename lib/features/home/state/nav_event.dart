part of 'nav_bloc.dart';

sealed class NavEvent extends Equatable {
  const NavEvent();
  @override
  List<Object> get props => [];
}

typedef RouteBuilder = Route Function(BuildContext context, Object? arguments);

final class NavPushed extends NavEvent {
  final RouteBuilder route;
  const NavPushed(this.route);
}

final class NavReplaced extends NavEvent {
  final RouteBuilder route;
  const NavReplaced(this.route);
}

final class NavPopped extends NavEvent {
  const NavPopped();
}

final class NavReset extends NavEvent {
  final RouteBuilder route;
  const NavReset(this.route);
}

final class NavTabChanged extends NavEvent {
  final int tabIndex;
  const NavTabChanged(this.tabIndex);
}
