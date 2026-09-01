part of 'main_bloc.dart';

abstract class MainScreenState {


  static AppUser? userStatic;
  AppUser? get user => userStatic;
  set user(AppUser? value) {
    userStatic = value;
  }




  static NotificationCounters? notificationCountersStatic;
  NotificationCounters? get notificationCounters => notificationCountersStatic;
  set notificationCounters(NotificationCounters? value) {
    notificationCountersStatic = value;
  }

  static StageData? stageDataStatic;
  StageData? get stageData => stageDataStatic;
  set stageData(StageData? value) {
    stageDataStatic = value;
  }

  static bool menuIsVisibleStatic = true;
  bool get menuIsVisible => menuIsVisibleStatic;
  set menuIsVisible(bool value) {
    menuIsVisibleStatic = value;
  }

  static int chatCounterStatic = 0;
  int get chatCounter => chatCounterStatic;
  set chatCounter(int value) {
    chatCounterStatic = value;
  }

  static int groupChatCounterStatic = 0;
  int get groupChatCounter => groupChatCounterStatic;
  set groupChatCounter(int value) {
    groupChatCounterStatic = value;
  }

  static int newsCounterStatic = 0;
  int get newsCounter => newsCounterStatic;
  set newsCounter(int value) {
    newsCounterStatic = value;
  }

  static int notificationCounterStatic = 0;
  int get notificationCounter => notificationCounterStatic;
  set notificationCounter(int value) {
    notificationCounterStatic = value;
  }



}

class InitialMainState extends MainScreenState {}

class DuelsMainScreenState extends MainScreenState {}

class DuelsSummaryMainScreenState extends MainScreenState {}

class DuelsStartMainScreenState extends MainScreenState {}

class SalesMainScreenState extends MainScreenState {}

class RanksMainScreenState extends MainScreenState {}

class NewsMainScreenState extends MainScreenState {}

class FindTeamMainScreenState extends MainScreenState {}

class PostMainScreenState extends MainScreenState {
  final String id;
  PostMainScreenState(this.id);
}

class AddPostMainScreenState extends MainScreenState {
  final String id;
  AddPostMainScreenState(this.id);

}


class StatsMainScreenState extends MainScreenState {}

class NotificationMainScreenState extends MainScreenState {}

class CardsMainScreenState extends MainScreenState {}

class ChatMainScreenState extends MainScreenState {
  final String id;
  ChatMainScreenState(this.id);
}

class ProfilPublicznyFirmyMainScreenState extends MainScreenState {
  final String id;
  ProfilPublicznyFirmyMainScreenState(this.id);
}

class VideoFirmyMainScreenState extends MainScreenState {
  final Promo promo;
  VideoFirmyMainScreenState(this.promo);
}


class ShowRequestMainScreenState extends MainScreenState {}

class ShowPromoMainScreenState extends MainScreenState {}

class RulesMainScreenState extends MainScreenState {}

class InviteTeamMainScreenState extends MainScreenState {}

class LoadingMainScreenState extends MainScreenState {}

class ContactMainScreenState extends MainScreenState {}

class AccountMainScreenState extends MainScreenState {}

class MessagingMainScreenState extends MainScreenState {}

class CreateTeamMainScreenState extends MainScreenState {}

class ChallengesMainScreenState extends MainScreenState {}

class DodajReviewMainScreenState extends MainScreenState {}


class WallMainScreenState extends MainScreenState {}

class UserMainScreenState extends MainScreenState {}

class FirmaMainScreenState extends MainScreenState {}

class ProfilFirmaMainScreenState extends MainScreenState {}

class StartMainScreenState extends MainScreenState {}

class LogoutMainScreenState extends MainScreenState {}



class WyszukajFirmyMainScreenState extends MainScreenState {
  final String? autoCategory;
  final String? autoSector;
  final double? autoLat;
  final double? autoLng;
  WyszukajFirmyMainScreenState({this.autoCategory, this.autoSector, this.autoLat, this.autoLng});
}

class ProfilPublicznyUseraMainScreenState extends MainScreenState {
  final String userId;
  ProfilPublicznyUseraMainScreenState(this.userId);
}