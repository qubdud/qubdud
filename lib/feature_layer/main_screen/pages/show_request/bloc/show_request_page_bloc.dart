import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
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
        final req = Globals.instance.selectedRequest!;
        // user null = autor usunął konto; exact null = firma bez przyjętej oferty
        final (user, exact) = await (
          firebase.fetchUser(req.userId, withContact: true),
          firebase.exactRequestLocation(req),
        ).wait;
        state.appUser = user;
        state.exactLocation = exact;
        emit(ShowRequestPageMainState());
      } catch (_) {
        emit(ShowRequestPageErrorState());
      }
    });

    add(TryShowRequestPageEvent());

  }
}
