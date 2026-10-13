part of 'core_screen_bloc.dart';

abstract class CoreScreenState {}

class CoreScreenInitialState extends CoreScreenState {
  CoreScreenInitialState() : super();
}

class CoreScreenAuthenticatedState extends CoreScreenState {}

class CoreScreenUnauthenticatedState extends CoreScreenState {
  /// ekran logowania ma otworzyć się od razu na rejestracji
  final bool toRegister;
  CoreScreenUnauthenticatedState({this.toRegister = false});
}


class CoreScreenLoadingState extends CoreScreenState {}
