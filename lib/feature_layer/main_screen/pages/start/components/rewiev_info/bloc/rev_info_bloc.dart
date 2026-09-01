import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';

import '../../../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../../../shared/globals.dart';

part 'rev_info_event.dart';
part 'rev_info_state.dart';


class RevInfoComponentBloc extends Bloc<RevInfoComponentEvent, RevInfoComponentState> {
  RevInfoComponentBloc({
    required FirebaseService firebase,
    required AppUser user,

  }) : super(RevInfoComponentLoadingState()) {
    on<GoToMainRevInfoComponentEvent>((event, emit) async {
    });

    on<GetDataRevInfoComponentEvent>((event, emit) async {

      try {

        var reviews = await firebase.getReviewsMetadataByReviewedUser(Globals.instance.selectedPromo!.userId);
        print('\na\na\na\na\na\na\n');
        print(Globals.instance.selectedPromo!.userId);
        print(reviews);
        print('\nb\nb\nb\nb\nb\nb\n');



        emit(RevInfoComponentMainState(reviews));
      } catch (e) {


        emit(RevInfoComponentMainState([]));
      }

    });




    add(GetDataRevInfoComponentEvent());
  }

}
