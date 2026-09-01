part of 'account_page_bloc.dart';

abstract class AccountPageState {

  static TeamInfo? teamInfoStatic;
  TeamInfo? get teamInfo => teamInfoStatic;
  set teamInfo(TeamInfo? value) {
    teamInfoStatic = value;
  }

  static UserStatistics? userStatisticsStatic;
  UserStatistics? get userStatistics=> userStatisticsStatic;
  set userStatistics(UserStatistics? value) {
    userStatisticsStatic = value;
  }

  static List<BusinessTask> businessTasksStatic = [];
  List<BusinessTask> get businessTasks => businessTasksStatic;
  set businessTasks(List<BusinessTask> value) {
    businessTasksStatic = value;
  }


}




class AccountPageMainState extends AccountPageState {}

class AccountPageInitialState extends AccountPageState {}

class AccountPageLoadingState extends AccountPageState {}

class AccountPageNextState extends AccountPageState {}

class AccountPageDeletedState extends AccountPageState {}

class StatisticsAccountPageState extends AccountPageState {}

class PersonalAccountPageState extends AccountPageState {}

class PasswordAccountPageState extends AccountPageState {}
