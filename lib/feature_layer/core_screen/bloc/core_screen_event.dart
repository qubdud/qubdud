part of 'core_screen_bloc.dart';

abstract class CoreScreenEvent {}

class CoreScreenCheckAuthenticationEvent extends CoreScreenEvent {
  final bool toRegister;
  CoreScreenCheckAuthenticationEvent({this.toRegister = false});
}

class CoreScreenCheckAppVersionEvent extends CoreScreenEvent {}

class CoreScreenGoToMainScreenEvent extends CoreScreenEvent {}
