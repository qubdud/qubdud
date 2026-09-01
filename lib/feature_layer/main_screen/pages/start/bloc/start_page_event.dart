part of 'start_page_bloc.dart';

abstract class StartPageEvent {}

class GetDataStartPageEvent extends StartPageEvent {}

class GoToMainStartPageEvent extends StartPageEvent {}

class VideoListUpdated extends StartPageEvent {
  final List<String> videoUrls;
  VideoListUpdated(this.videoUrls);
}




class TryAddFavStartPageEvent extends StartPageEvent {
  final String promoId;
  TryAddFavStartPageEvent(this.promoId);
}

class TryRemoveFavStartPageEvent extends StartPageEvent {
  final String promoId;
  TryRemoveFavStartPageEvent(this.promoId);
}


class SkipRequestEvent extends StartPageEvent {
  final String requestId;
  SkipRequestEvent({required this.requestId});
}

class TryAddContactStartPageEvent extends StartPageEvent {
  final String contactUserId;
  TryAddContactStartPageEvent(this.contactUserId);
}

class TryQuickOfferEvent extends StartPageEvent {
  final String requestId;
  TryQuickOfferEvent(this.requestId);
}

class TryHideRequestEvent extends StartPageEvent {
  final String requestId;
  TryHideRequestEvent(this.requestId);
}

class TryRestoreRequestEvent extends StartPageEvent {
  final String requestId;
  TryRestoreRequestEvent(this.requestId);
}