import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:qb/domain_layer/domain_models/team_invite.dart';

import '../../../../../../domain_layer/repository.dart';

part 'find_team_page_event.dart';

part 'find_team_page_state.dart';

class FindTeamPageBloc extends Bloc<FindTeamPageEvent, FindTeamPageState> {
  Timer? resetTimer;

  FindTeamPageBloc({
    required AppRepository repository,
  }) : super(FindTeamPageLoadingState()) {
    on<GetDataFindTeamPageEvent>((event, emit) async {
      emit(FindTeamPageLoadingState());
      var teamsResult = await repository.getInvitableTeams();
      teamsResult.whenSuccess((res) {
        state.invitableTeams = res;
        emit(FindTeamPageMainState());
      });

      // var newsResult = await repository.getNews();
      // newsResult.whenSuccess((res){state.newsList=res;
      //  startResetTimer();
      //  emit(FindTeamPageMainState());
      //  });
    });

    on<TryRequestToJoinFindTeamPageEvent>((event, emit) async {
      var result = await repository.sendRequestToJoinTeam(event.id);

      add(GetDataFindTeamPageEvent());
    });

    add(GetDataFindTeamPageEvent());
  }

}
