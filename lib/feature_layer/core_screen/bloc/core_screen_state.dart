part of 'core_screen_bloc.dart';

abstract class CoreScreenState {}

class CoreScreenInitialState extends CoreScreenState {
  CoreScreenInitialState() : super();
}

class CoreScreenAuthenticatedState extends CoreScreenState {}

class CoreScreenUnauthenticatedState extends CoreScreenState {}


class CoreScreenLoadingState extends CoreScreenState {}
