part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthGoToLoginPageEvent extends AuthEvent {}

class AuthGoToRegisterPageEvent extends AuthEvent {}

class AuthGoToRegistrationCompletePageEvent extends AuthEvent {}

class AuthGoToForgotPasswordPageEvent extends AuthEvent {}

class AuthGoToForgotPasswordCompletePageEvent extends AuthEvent {}
