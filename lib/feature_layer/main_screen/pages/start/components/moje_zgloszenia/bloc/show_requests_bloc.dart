import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';

import '../../../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';

part 'show_requests_event.dart';
part 'show_requests_state.dart';


class ShowRequestsComponentBloc extends Bloc<ShowRequestsComponentEvent, ShowRequestsComponentState> {
  StreamSubscription<List<Request>>? _sub;

  ShowRequestsComponentBloc({
    required FirebaseService firebase,
    required AppUser user,

  }) : super(ShowRequestsComponentLoadingState()) {

    // nasłuch na żywo: decyzje firmy (np. „zlecenie wykonane”) widać bez przełączania zakładki
    on<GetDataShowRequestsComponentEvent>((event, emit) {
      _sub?.cancel();
      _sub = null;
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state.requests = [];
        emit(ShowRequestsComponentErrorState());
        return;
      }
      _sub = firebase.requestsByUserStream(userId).listen(
          (list) => add(_RequestsUpdatedShowRequestsComponentEvent(list)),
          onError: (_) => add(_RequestsUpdatedShowRequestsComponentEvent(null)));
    });

    on<_RequestsUpdatedShowRequestsComponentEvent>((event, emit) {
      state.requests = event.requests ?? [];
      emit(event.requests == null
          ? ShowRequestsComponentErrorState()
          : ShowRequestsComponentMainState());
    });

    on<TryDeleteMyRequestShowRequestsComponentEvent>((event, emit) async {
      try {
        await firebase.deleteRequestMetadata(event.id);
        showToast(text: 'Usunięto');
        add(GetDataShowRequestsComponentEvent());
      } catch (_) {
        showToastError(text: 'Nie udało się usunąć zgłoszenia');
      }
    });




    add(GetDataShowRequestsComponentEvent());
}

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
