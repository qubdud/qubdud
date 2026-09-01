part of 'main_bloc.dart';

abstract class MainScreenState {
  static AppUser? userStatic;
  AppUser? get user => userStatic;
  set user(AppUser? value) {
    userStatic = value;
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
}

class InitialMainState extends MainScreenState {}

class LoadingMainScreenState extends MainScreenState {}

class StartMainScreenState extends MainScreenState {}

class LogoutMainScreenState extends MainScreenState {}

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
  final List<Promo>? playlist;
  final int initialIndex;
  VideoFirmyMainScreenState(this.promo, {this.playlist, this.initialIndex = 0});
}

class ShowRequestMainScreenState extends MainScreenState {}

class RulesMainScreenState extends MainScreenState {}

class ProfilFirmaMainScreenState extends MainScreenState {}

class DodajMainScreenState extends MainScreenState {}

class DodajReviewMainScreenState extends MainScreenState {}

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
