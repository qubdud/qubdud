import 'package:bloc/bloc.dart';
import 'package:qb/data_layer/data_models/request/change_pass.dart';
import 'package:qb/data_layer/data_models/response_error/change_pass.dart';

import '../../../../../../../domain_layer/repository.dart';


part 'password_page_event.dart';
part 'password_page_state.dart';

class PasswordAccountPageBloc extends Bloc<PasswordAccountPageEvent, PasswordPageAccountPageState> {
  PasswordAccountPageBloc({
    required AppRepository repository,
  }) : super(PasswordAccountPageInitialState()) {
    on<GoToMainPasswordAccountPageEvent>((event, emit) async {
      emit(PasswordAccountPageMainState());
    });

    on<TryChangePasswordAccountPageEvent>((event, emit) async {
      emit(PasswordAccountPageLoadingState());
      var result = await repository.changePassword(event.changePassRequest);

      result.whenSuccess((response) {
        emit(PasswordAccountPageNextState());
      });

      result.whenError((response) {

        emit(PasswordAccountPageErrorState(changePassError: response));
      });
    });

    on<GetDataPasswordAccountPageEvent>((event, emit) async {
      emit(PasswordAccountPageLoadingState());
      emit(PasswordAccountPageMainState());
    });

    add(GetDataPasswordAccountPageEvent());
  }
}
