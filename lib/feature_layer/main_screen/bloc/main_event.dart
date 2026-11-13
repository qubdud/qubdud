part of 'main_bloc.dart';

abstract class MainScreenEvent {
  /// true, gdy event odtwarza poprzedni ekran po „wstecz”
  bool restoring = false;
}

class GoBackEvent extends MainScreenEvent {}

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

class GoToPowiadomieniaEvent extends MainScreenEvent {}

class RefreshBadgesEvent extends MainScreenEvent {}

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

class GoToShowRequestEvent extends MainScreenEvent {
  /// zgłoszenie z chwili otwarcia — „wstecz” odtwarza ten sam ekran, nie ostatnio wybrane
  final Request? request = Globals.instance.selectedRequest;
}

class GoToDodajReviewEvent extends MainScreenEvent {}

class GoToRulesEvent extends MainScreenEvent {}

class GoToChatEvent extends MainScreenEvent {
  final String id;
  final String? chatName;
  GoToChatEvent(this.id, {this.chatName});
}

class LogoutEvent extends MainScreenEvent {
  /// po wylogowaniu otwórz rejestrację zamiast logowania
  final bool toRegister;
  LogoutEvent({this.toRegister = false});
}

class DeleteAccountEvent extends MainScreenEvent {}

/// Przełączenie trybu konta firmowego (Firma / Użytkownik).
class SwitchModeEvent extends MainScreenEvent {
  final bool company;
  SwitchModeEvent(this.company);
}

/// Otwarcie powiadomienia — ten sam router dla pusha i wpisu w dzwonku.
class OpenNotificationEvent extends MainScreenEvent {
  final String type;
  final String senderId;
  final String? senderName;
  final String requestId;
  final String companyId;
  final String audience;
  final String notifId;
  final bool read;

  OpenNotificationEvent._(Map<String, dynamic> m,
      {required this.senderId, required this.notifId, this.read = false})
      : type = m['type'] as String? ?? '',
        senderName = m['fromName'] as String?,
        requestId = m['requestId'] as String? ?? '',
        companyId = m['companyId'] as String? ?? '',
        audience = m['audience'] as String? ?? 'both';

  /// Dane FCM (same stringi).
  factory OpenNotificationEvent.fromPush(Map<String, dynamic> data) =>
      OpenNotificationEvent._(data,
          senderId: data['senderId'] as String? ?? '',
          notifId: data['notifId'] as String? ?? '');

  /// Dokument z kolekcji notifications (z polem 'id').
  factory OpenNotificationEvent.fromNotification(Map<String, dynamic> n) =>
      OpenNotificationEvent._(n,
          senderId: n['from'] as String? ?? '',
          notifId: n['id'] as String? ?? '',
          read: n['read'] == true);
}

class HandleDeepLinkEvent extends MainScreenEvent {
  final Uri uri;
  HandleDeepLinkEvent(this.uri);
}

class GoToProfilPublicznyUseraEvent extends MainScreenEvent {
  final String userId;
  GoToProfilPublicznyUseraEvent(this.userId);
}
