part of 'invite_team_page_bloc.dart';

abstract class InviteTeamPageEvent {}

class GetDataInviteTeamPageEvent extends InviteTeamPageEvent {}

class GoToMainInviteTeamPageEvent extends InviteTeamPageEvent {}

class GoToOfferTeamPageEvent extends InviteTeamPageEvent {}

class SendInviteTeamPageEvent extends InviteTeamPageEvent {
  final String id;
  SendInviteTeamPageEvent(this.id);

}


class AcceptOfferInviteTeamPageEvent extends InviteTeamPageEvent {
  final String id;

  AcceptOfferInviteTeamPageEvent(this.id);
}
