import 'package:bloc/bloc.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';


part 'show_request_page_event.dart';

part 'show_request_page_state.dart';

class ShowRequestPageBloc extends Bloc<ShowRequestPageEvent, ShowRequestPageState> {
  ShowRequestPageBloc({
    required FirebaseService firebase,
  }) : super(ShowRequestPageLoadingState()) {


    on<TryShowRequestPageEvent>((event, emit) async {
      emit(ShowRequestPageLoadingState());
      try {
        // null = autor usunął konto
        state.appUser = await firebase
            .fetchUser(Globals.instance.selectedRequest!.userId, withContact: true);
        emit(ShowRequestPageMainState());
      } catch (_) {
        emit(ShowRequestPageErrorState());
      }
    });

    add(TryShowRequestPageEvent());

  }
}
