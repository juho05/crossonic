import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'nav_event.dart';
part 'nav_state.dart';

class NavBloc extends Bloc<NavEvent, NavState> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys;
  final List<bool> _canPop;
  int _tabIndex = 0;

  void _updateCanPop(Emitter<NavState> emit) {
    if (_navigatorKeys[_tabIndex].currentState != null) {
      _canPop[_tabIndex] = _navigatorKeys[_tabIndex].currentState!.canPop();
      emit(state.copyWith(canPop: _canPop[_tabIndex]));
    }
  }

  NavBloc(this._navigatorKeys)
      : _canPop = List.filled(_navigatorKeys.length, false),
        super(const NavState(false, 0)) {
    on<NavTabChanged>((event, emit) {
      _tabIndex = event.tabIndex;
      emit(state.copyWith(
        canPop: _canPop[_tabIndex],
        tabIndex: _tabIndex,
      ));
    });
    on<NavPushed>((event, emit) {
      _navigatorKeys[_tabIndex].currentState?.push(event.route);
      _updateCanPop(emit);
    });
    on<NavReplaced>((event, emit) {
      _navigatorKeys[_tabIndex].currentState?.pushReplacement(event.route);
      _updateCanPop(emit);
    });
    on<NavReset>((event, emit) {
      _navigatorKeys[_tabIndex]
          .currentState
          ?.pushAndRemoveUntil(event.route, (route) => false);
      _updateCanPop(emit);
    });
    on<NavPopped>((event, emit) {
      final state = _navigatorKeys[_tabIndex].currentState;
      if (state?.canPop() ?? false) {
        state!.pop();
        _updateCanPop(emit);
      }
    });
  }
}
