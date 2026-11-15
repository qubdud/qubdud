part of 'show_requests_bloc.dart';

abstract class ShowRequestsComponentEvent {}

class GetDataShowRequestsComponentEvent extends ShowRequestsComponentEvent {}

class _RequestsUpdatedShowRequestsComponentEvent extends ShowRequestsComponentEvent {
  final List<Request>? requests;
  _RequestsUpdatedShowRequestsComponentEvent(this.requests);
}

class GoToMainShowRequestsComponentEvent extends ShowRequestsComponentEvent {}

class VideoListUpdated extends ShowRequestsComponentEvent {
  final List<String> videoUrls;
  VideoListUpdated(this.videoUrls);
}




class TryDeleteMyRequestShowRequestsComponentEvent extends ShowRequestsComponentEvent {
  final String id;
  TryDeleteMyRequestShowRequestsComponentEvent({required this.id });
}

