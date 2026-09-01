import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';

import '../../../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../../../shared/globals.dart';

part 'show_requests_event.dart';
part 'show_requests_state.dart';


class ShowRequestsComponentBloc extends Bloc<ShowRequestsComponentEvent, ShowRequestsComponentState> {
  ShowRequestsComponentBloc({
    required FirebaseService firebase,
    required AppUser user,

  }) : super(ShowRequestsComponentLoadingState()) {

    on<GetDataShowRequestsComponentEvent>((event, emit) async {

      try{
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('Brak użytkownika');

    final requests = await firebase.getRequestsMetadataByUser(userId);
    state.requests = requests;

    emit(ShowRequestsComponentMainState());
  } catch (e) {
  print(e);
  state.requests = [];
  showToastError(text: 'Błąd pobierania danych\n${e}');
  emit(ShowRequestsComponentMainState());
  }
});

    on<TryDeleteMyRequestShowRequestsComponentEvent>((event, emit) async {
      try {

        await firebase.deleteRequestMetadata( event.id );
        showToast(text: 'Usunięto');
        add(GetDataShowRequestsComponentEvent());
      } catch (e) {
         showToastError(text: 'Błąd\n${e}');
        emit(ShowRequestsComponentMainState());
      }

    });




    add(GetDataShowRequestsComponentEvent());
}


}
