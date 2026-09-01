part of 'main_bloc.dart';

abstract class MainScreenEvent {}

class UpdateUserDataMainScreenEvent extends MainScreenEvent {}

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

class GoToDuelsEvent extends MainScreenEvent {}

class GoToProfilFirmaEvent extends MainScreenEvent {}

class GoToDodajEvent extends MainScreenEvent {}

class GoToFindTeamEvent extends MainScreenEvent {}

class GoToPostEvent extends MainScreenEvent {
  final String id;
  GoToPostEvent(this.id);
}

class GoToAddPostEvent extends MainScreenEvent {
  final String id;
  GoToAddPostEvent(this.id);
}
class GoToChallengesEvent extends MainScreenEvent {}

class GoToWallEvent extends MainScreenEvent {}

class GoToCreateTeamEvent extends MainScreenEvent {}

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
  GoToPromoFirmyEvent(this.promo);
}


class GoToSalesEvent extends MainScreenEvent {}

class GoToRanksEvent extends MainScreenEvent {}

class GoToNewsEvent extends MainScreenEvent {}

class GoToNotificationEvent extends MainScreenEvent {}

class GoToMessagingEvent extends MainScreenEvent {}

class GoToShowRequestEvent extends MainScreenEvent {}

class GoToDodajReviewEvent extends MainScreenEvent {}

class GoToAccountEvent extends MainScreenEvent {}

class GoToStatsEvent extends MainScreenEvent {}

class GoToDuelsSummaryEvent extends MainScreenEvent {}

class GoToDuelStartEvent extends MainScreenEvent {}

class GoToRulesEvent extends MainScreenEvent {}

class GoToChatEvent extends MainScreenEvent {
  final String id;
  GoToChatEvent(this.id);


}

class GoToContactEvent extends MainScreenEvent {}

class GoToInviteTeamEvent extends MainScreenEvent {}

class LogoutEvent extends MainScreenEvent {}

class GoToProfilPublicznyUseraEvent extends MainScreenEvent {
  final String userId;
  GoToProfilPublicznyUseraEvent(this.userId);
}