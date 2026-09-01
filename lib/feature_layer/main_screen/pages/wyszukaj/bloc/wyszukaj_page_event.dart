part of 'wyszukaj_page_bloc.dart';

abstract class WyszukajPageEvent {}

class TryWyszukajPageEvent extends WyszukajPageEvent {
  final LatLng location;
  final String sector;
  final String category;

  TryWyszukajPageEvent({required this.sector, required this.category, required this.location});
}



class TryAddFavWyszukajPageEvent extends WyszukajPageEvent {
  final String promoId;
  TryAddFavWyszukajPageEvent(this.promoId);
}

class GoToLastWyszukajPageEvent extends WyszukajPageEvent {}

class TryAddContactEvent extends WyszukajPageEvent {
  final String contactUserId;
  TryAddContactEvent(this.contactUserId);
}