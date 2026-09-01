import 'dart:developer';

import 'package:bloc/bloc.dart';


import '../../../../../data_layer/data_models/request/register.dart';
import '../../../../../data_layer/data_models/response_error/register.dart';
import '../../../../../domain_layer/domain_models/register_data.dart';
import '../../../../../domain_layer/repository.dart';
import '../../../../../shared/functions/show_toast_error.dart';

part 'register_event.dart';

part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({
    required AppRepository repository,
  }) : super(RegisterLoadingState()) {
    on<TryRegisterEvent>((event, emit) async {
      emit(RegisterLoadingState());
      var result = await repository.register(event.registerRequest);

      result.whenSuccess((response) {
        emit(RegisterNextState());
      });

      result.whenError((response) {
        showToastError(text: response.message);
        emit(RegisterErrorState(registerError: response));
      });
    });


    on<GoToLoginRegisterEvent>((event, emit) async {
      emit(RegisterBackState());
    });

    on<GetNipDataEvent>((event, emit) async {
      var result = await repository.getRegisterNipData(event.nip);
      result.whenSuccess((response) {
        state.registerNipData = response;
        emit(RegisterNipLoadedState());
      });
      result.whenError((response) {
        showToastError(text: response);
       // emit(RegisterNipFailState(response));
      });
    });



    on<GetDataRegisterEvent>((event, emit) async {
      emit(RegisterLoadingState());

      emit(RegisterInitialState());
    });
    add(GetDataRegisterEvent());
  }
}
