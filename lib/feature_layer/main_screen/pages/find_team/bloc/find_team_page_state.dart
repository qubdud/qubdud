part of 'find_team_page_bloc.dart';

abstract class FindTeamPageState {
  static List<TeamInvite> invitableTeamsStatic = [];

  List<TeamInvite> get invitableTeams => invitableTeamsStatic;

  set invitableTeams(List<TeamInvite> value) {
    invitableTeamsStatic = value;
  }
}

class FindTeamPageInitialState extends FindTeamPageState {
  FindTeamPageInitialState() : super();
}

class FindTeamPageMainState extends FindTeamPageState {
  FindTeamPageMainState() : super();
}

class FindTeamPageLoadingState extends FindTeamPageState {}

class FindTeamPageNextState extends FindTeamPageState {}
