part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthLoginPageState extends AuthState {}

class AuthRegisterPageState extends AuthState {}

class AuthRegistrationCompletePageState extends AuthState {}

class AuthForgotPasswordCompletePageState extends AuthState {}

class AuthForgotPasswordPageState extends AuthState {}

class AuthForgotPasswordVerificationPageState extends AuthState {
  final Uri uri;
  AuthForgotPasswordVerificationPageState(this.uri);
}

class AuthVerificationPageState extends AuthState {
  final Uri uri;
  AuthVerificationPageState(this.uri);
}


class AuthResetPasswordPageState extends AuthState {}

class AuthPasswordChangedPageState extends AuthState {}
