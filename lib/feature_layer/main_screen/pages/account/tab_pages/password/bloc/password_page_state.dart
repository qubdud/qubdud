part of 'password_page_bloc.dart';

abstract class PasswordPageAccountPageState {}

class PasswordAccountPageInitialState extends PasswordPageAccountPageState {
  PasswordAccountPageInitialState() : super();
}

class PasswordAccountPageMainState extends PasswordPageAccountPageState {
  PasswordAccountPageMainState() : super();
}

class PasswordAccountPageErrorState extends PasswordPageAccountPageState {
  final ChangePassError changePassError;

  PasswordAccountPageErrorState({required this.changePassError});
}

class PasswordAccountPageLoadingState extends PasswordPageAccountPageState {}

class PasswordAccountPageNextState extends PasswordPageAccountPageState {}
