part of 'login_bloc.dart';

abstract class LoginState {}

class LoginInitialState extends LoginState {
  LoginInitialState() : super();
}

class LoginMainState extends LoginState {
  LoginMainState() : super();
}

class LoginErrorState extends LoginState {
  final LoginError loginError;

  LoginErrorState({required this.loginError});
}

class LoginLoadingState extends LoginState {}

class LoginNextState extends LoginState {}
