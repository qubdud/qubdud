part of 'invite_team_page_bloc.dart';

abstract class InviteTeamPageState {


  static List<UserInvite> invitableUsersStatic = [];
  List<UserInvite> get invitableUsers => invitableUsersStatic;
  set invitableUsers(List<UserInvite> value) {
    invitableUsersStatic = value;
  }

  static List<UserInviteRequest> usersRequestsStatic = [];
  List<UserInviteRequest> get usersRequests => usersRequestsStatic;
  set usersRequests(List<UserInviteRequest> value) {
    usersRequestsStatic = value;
  }


}

class InviteTeamPageInitialState extends InviteTeamPageState {}

class InviteTeamPageInviteState extends InviteTeamPageState {}

class InviteTeamPageOfferState extends InviteTeamPageState {}


class InviteTeamPageLoadingState extends InviteTeamPageState {}

class InviteTeamPageNextState extends InviteTeamPageState {}
