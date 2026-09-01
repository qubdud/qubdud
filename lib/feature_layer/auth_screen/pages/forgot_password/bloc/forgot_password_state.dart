part of 'forgot_password_bloc.dart';

abstract class ForgotPasswordState {

}

class ForgotPasswordInitialState extends ForgotPasswordState {
  ForgotPasswordInitialState() : super();
}

class ForgotPasswordMainState extends ForgotPasswordState {
  ForgotPasswordMainState() : super();
}

class ForgotPasswordErrorState extends ForgotPasswordState {
  final ForgotPasswordError forgotPasswordError;
        ForgotPasswordErrorState({required this.forgotPasswordError});
}

class ForgotPasswordLoadingState extends ForgotPasswordState {}

class ForgotPasswordBackState extends ForgotPasswordState {}

class ForgotPasswordNextState extends ForgotPasswordState {}
