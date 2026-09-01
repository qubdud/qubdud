part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordEvent {}

class TryForgotPasswordEvent extends ForgotPasswordEvent {
  final ForgotPasswordRequest forgotPasswordRequest;

  TryForgotPasswordEvent({required this.forgotPasswordRequest});
}

class GetDataForgotPasswordEvent extends ForgotPasswordEvent {}

class GoToLoginForgotPasswordEvent extends ForgotPasswordEvent {}
