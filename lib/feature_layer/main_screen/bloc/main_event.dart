part of 'main_bloc.dart';

abstract class MainScreenEvent {}

class ShowToastEvent extends MainScreenEvent {
  final String message;

  ShowToastEvent({required this.message});
}

class UpdateMenuVisibilityEvent extends MainScreenEvent {
  final bool isVisible;

  UpdateMenuVisibilityEvent({required this.isVisible});
}

class InitEvent extends MainScreenEvent {}

class GoToHomeEvent extends MainScreenEvent {}

class GoToProfilFirmaEvent extends MainScreenEvent {}

class GoToDodajEvent extends MainScreenEvent {}

class GoToWyszukajFirmyEvent extends MainScreenEvent {
  final String? autoCategory;
  final String? autoSector;
  final double? autoLat;
  final double? autoLng;
  GoToWyszukajFirmyEvent({this.autoCategory, this.autoSector, this.autoLat, this.autoLng});
}

class GoToProfilPublicznyFirmyEvent extends MainScreenEvent {
  final String id;
  GoToProfilPublicznyFirmyEvent(this.id);
}

class GoToPromoFirmyEvent extends MainScreenEvent {
  final Promo promo;
  final List<Promo>? playlist;
  final int initialIndex;
  GoToPromoFirmyEvent(this.promo, {this.playlist, this.initialIndex = 0});
}

class GoToShowRequestEvent extends MainScreenEvent {}

class GoToDodajReviewEvent extends MainScreenEvent {}

class GoToRulesEvent extends MainScreenEvent {}

class GoToChatEvent extends MainScreenEvent {
  final String id;
  GoToChatEvent(this.id);
}

class LogoutEvent extends MainScreenEvent {}

class HandleDeepLinkEvent extends MainScreenEvent {
  final Uri uri;
  HandleDeepLinkEvent(this.uri);
}

class GoToProfilPublicznyUseraEvent extends MainScreenEvent {
  final String userId;
  GoToProfilPublicznyUseraEvent(this.userId);
}
