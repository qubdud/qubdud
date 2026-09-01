part of 'core_screen_bloc.dart';

abstract class CoreScreenEvent {}

class CoreScreenCheckAuthenticationEvent extends CoreScreenEvent {}

class CoreScreenLogoutEvent extends CoreScreenEvent {}

class CoreScreenCheckAppVersionEvent extends CoreScreenEvent {}

class CoreScreenGoToMainScreenEvent extends CoreScreenEvent {}
