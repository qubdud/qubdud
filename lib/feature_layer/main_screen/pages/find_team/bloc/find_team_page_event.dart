part of 'find_team_page_bloc.dart';

abstract class FindTeamPageEvent {}

class GetDataFindTeamPageEvent extends FindTeamPageEvent {}

class GoToMainFindTeamPageEvent extends FindTeamPageEvent {}

class TryRequestToJoinFindTeamPageEvent extends FindTeamPageEvent {
  final String id;

  TryRequestToJoinFindTeamPageEvent(this.id);
}
