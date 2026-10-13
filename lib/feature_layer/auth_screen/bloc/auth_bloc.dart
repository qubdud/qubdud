import 'package:bloc/bloc.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({bool startOnRegister = false})
      : super(startOnRegister ? AuthRegisterPageState() : AuthLoginPageState()) {
    on<AuthGoToLoginPageEvent>((event, emit) {
      emit(AuthLoginPageState());
    });

    on<AuthGoToRegisterPageEvent>((event, emit) {
      emit(AuthRegisterPageState());
    });

    on<AuthGoToRegistrationCompletePageEvent>((event, emit) {
      emit(AuthRegistrationCompletePageState());
    });

    on<AuthGoToForgotPasswordCompletePageEvent>((event, emit) {
      emit(AuthForgotPasswordCompletePageState());
    });

    on<AuthGoToForgotPasswordPageEvent>((event, emit) {
      emit(AuthForgotPasswordPageState());
    });
  }
}
