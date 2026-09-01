import 'dart:developer';

import 'package:bloc/bloc.dart';



import '../../../../../data_layer/data_models/auth_models.dart';
import '../../../../../data_layer/data_models/request/register.dart';
import '../../../../../data_layer/data_models/response_error/forgot_pass.dart';
import '../../../../../domain_layer/repository.dart';
import '../../../../../shared/functions/show_toast_error.dart';

part 'forgot_password_event.dart';

part 'forgot_password_state.dart';

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc({
    required AppRepository repository,
  }) : super(ForgotPasswordInitialState()) {
    on<TryForgotPasswordEvent>((event, emit) async {
      emit(ForgotPasswordLoadingState());
      var result = await repository.forgotPassword(event.forgotPasswordRequest);

      result.whenSuccess((response) {
        emit(ForgotPasswordNextState());
      });

      result.whenError((response) {
        showToastError(text: response.message);
        emit(ForgotPasswordErrorState(forgotPasswordError: response));
      });
    });


    on<GoToLoginForgotPasswordEvent>((event, emit) async {
      emit(ForgotPasswordBackState());
    });

  }
}
