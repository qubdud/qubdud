import 'package:bloc/bloc.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../data_layer/data_models/request/contact.dart';
import '../../../../../data_layer/data_models/response_error/contact.dart';

part 'profil_user_page_event.dart';
part 'profil_user_page_state.dart';

class ProfilUserPageBloc extends Bloc<ProfilUserPageEvent, ProfilUserPageState> {
  ProfilUserPageBloc({
    required AppRepository repository,
  }) : super(ProfilUserPageInitialState()) {
    on<GoToMainProfilUserPageEvent>((event, emit) async {
      emit(ProfilUserPageMainState());
    });

    on<TrySendMessageEvent>((event, emit) async {
      emit(ProfilUserPageLoadingState());
      var result = await repository.sendContact(event.contactRequest);

      result.whenSuccess((response) {
        emit(ProfilUserPageNextState());
      });

      result.whenError((response) {

        emit(ProfilUserPageErrorState(contactError: response));
      });
    });

    on<GetDataProfilUserPageEvent>((event, emit) async {
      emit(ProfilUserPageLoadingState());
      emit(ProfilUserPageMainState());
    });

    add(GetDataProfilUserPageEvent());
  }
}
