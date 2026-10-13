part of 'profil_my_page_bloc.dart';

abstract class ProfilPubliczyPageEvent {}

class GetDataProfilPubliczyPageEvent extends ProfilPubliczyPageEvent {}

class GoToMainProfilPubliczyPageEvent extends ProfilPubliczyPageEvent {}

class TryDeleteMyPromoProfilPageEvent extends ProfilPubliczyPageEvent {
  final String id;
  TryDeleteMyPromoProfilPageEvent({required this.id });
}


class TryDeleteMyRequestProfilPageEvent extends ProfilPubliczyPageEvent {
  final String id;
  TryDeleteMyRequestProfilPageEvent({required this.id });
}


class TryDeleteMyReviewProfilPageEvent extends ProfilPubliczyPageEvent {
  final String id;
  TryDeleteMyReviewProfilPageEvent({required this.id});
}