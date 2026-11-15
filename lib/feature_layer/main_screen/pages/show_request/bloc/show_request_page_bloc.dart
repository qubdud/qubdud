import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';


part 'show_request_page_event.dart';

part 'show_request_page_state.dart';

class ShowRequestPageBloc extends Bloc<ShowRequestPageEvent, ShowRequestPageState> {
  StreamSubscription<Request?>? _sub;

  ShowRequestPageBloc({
    required FirebaseService firebase,
  }) : super(ShowRequestPageLoadingState()) {

    Future<void> loadDetails(Request req) async {
      // user null = autor usunął konto; exact null = firma bez przyjętej oferty
      final (user, exact) = await (
        firebase.fetchUser(req.userId, withContact: true),
        firebase.exactRequestLocation(req),
      ).wait;
      state.appUser = user;
      state.exactLocation = exact;
    }

    on<TryShowRequestPageEvent>((event, emit) async {
      emit(ShowRequestPageLoadingState());
      try {
        final req = Globals.instance.selectedRequest!;
        await loadDetails(req);
        emit(ShowRequestPageMainState());
        // status, przejęcie i realizacja odświeżają się bez wychodzenia z ekranu
        if (isClosed) return;
        _sub ??= firebase.requestStream(req.id).listen((r) {
          if (r != null && !isClosed) add(RequestChangedShowRequestPageEvent(r));
        }, onError: (_) {});
      } catch (_) {
        emit(ShowRequestPageErrorState());
      }
    });

    on<RequestChangedShowRequestPageEvent>((event, emit) async {
      final old = Globals.instance.selectedRequest;
      if (old == null || old.id != event.request.id) return;
      final fresh = event.request..distance = old.distance;
      Globals.instance.selectedRequest = fresh;
      // przyjęcie albo odblokowanie zmienia dostęp do dokładnego miejsca i telefonu
      if (fresh.takenBy != old.takenBy) {
        try {
          await loadDetails(fresh);
        } catch (_) {}
      }
      emit(ShowRequestPageMainState());
    });

    add(TryShowRequestPageEvent());

  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
