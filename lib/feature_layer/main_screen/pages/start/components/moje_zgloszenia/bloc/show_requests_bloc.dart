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
  ShowRequestsComponentBloc({
    required FirebaseService firebase,
    required AppUser user,

  }) : super(ShowRequestsComponentLoadingState()) {

    on<GetDataShowRequestsComponentEvent>((event, emit) async {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('Brak użytkownika');
        state.requests = await firebase.getRequestsMetadataByUser(userId);
        emit(ShowRequestsComponentMainState());
      } catch (_) {
        state.requests = [];
        emit(ShowRequestsComponentErrorState());
      }
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


}
