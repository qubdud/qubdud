part of 'profil_user_page_bloc.dart';


abstract class ProfilUserPageEvent {}

class GetDataProfilUserPageEvent extends ProfilUserPageEvent {}

class GoToMainProfilUserPageEvent extends ProfilUserPageEvent {}

class TrySendMessageEvent extends ProfilUserPageEvent {
  final ContactRequest contactRequest;

  TrySendMessageEvent({required this.contactRequest});
}
