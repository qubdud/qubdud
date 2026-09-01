import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';

import '../../../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../../../shared/globals.dart';

part 'user_info_event.dart';
part 'user_info_state.dart';


class UserInfoComponentBloc extends Bloc<UserInfoComponentEvent, UserInfoComponentState> {
  UserInfoComponentBloc({
    required FirebaseService firebase,
    required String userId,

  }) : super(UserInfoComponentLoadingState()) {
    on<GoToMainUserInfoComponentEvent>((event, emit) async {
    });

    on<GetDataUserInfoComponentEvent>((event, emit) async {

      try {

        var use = await firebase.fetchUser(userId);




        emit(UserInfoComponentMainState(use!));

      } catch (e) {


        emit(UserInfoComponentNextState());
      }

    });




    add(GetDataUserInfoComponentEvent());
  }

}
