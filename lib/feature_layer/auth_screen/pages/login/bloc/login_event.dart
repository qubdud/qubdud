part of 'login_bloc.dart';

abstract class LoginEvent {}

class TryLoginEvent extends LoginEvent {
  LoginRequest loginRequest;

  TryLoginEvent({required this.loginRequest});
}

class GoToMainLoginEvent extends LoginEvent {}
