part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthLoginPageState extends AuthState {}

class AuthRegisterPageState extends AuthState {}

class AuthRegistrationCompletePageState extends AuthState {}

class AuthForgotPasswordPageState extends AuthState {}

class AuthForgotPasswordCompletePageState extends AuthState {}
