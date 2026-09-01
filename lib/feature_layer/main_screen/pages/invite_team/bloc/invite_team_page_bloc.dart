import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:qb/domain_layer/domain_models/team_invite.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_fail.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../domain_layer/domain_models/user_invite.dart';
import '../../../../../domain_layer/domain_models/user_invite_request.dart';

part 'invite_team_page_event.dart';

part 'invite_team_page_state.dart';

class InviteTeamPageBloc extends Bloc<InviteTeamPageEvent, InviteTeamPageState> {
  Timer? resetTimer;

  InviteTeamPageBloc({
    required AppRepository repository,
  }) : super(InviteTeamPageLoadingState()) {

    on<GetDataInviteTeamPageEvent>((event, emit) async {
      emit(InviteTeamPageLoadingState());
        var passangers = await repository.getInvitableUsers();
          passangers.whenSuccess((res) {
          state.invitableUsers = res;
       });
      var usersRequests = await repository.getPendingUserInvites();
      usersRequests.whenSuccess((res) {
        state.usersRequests = res;
      });

      emit(InviteTeamPageInviteState());
    });



    on<GoToOfferTeamPageEvent>((event, emit) async {
    emit(InviteTeamPageOfferState());

    });


    on<GoToMainInviteTeamPageEvent>((event, emit) async {

      emit(InviteTeamPageInviteState());

    });


on<SendInviteTeamPageEvent>((event,emit) async{

  var result = await repository.sendInviteToUser(event.id);

  result.when((res){showToast(text: res.message??'Inivite sent');},

          (res){
            showToastFail(text: 'Try again later');
            add(GetDataInviteTeamPageEvent());

          });






});



    on<AcceptOfferInviteTeamPageEvent>((event, emit) async {

      var result = await repository.acceptUserInvite(event.id);

      result.whenSuccess((a){
        add(GetDataInviteTeamPageEvent());
        add(GoToOfferTeamPageEvent());
      });

      result.whenError((a){
        showToastFail(text: 'Try again later.');
      });



    });

    add(GetDataInviteTeamPageEvent());
  }

}
