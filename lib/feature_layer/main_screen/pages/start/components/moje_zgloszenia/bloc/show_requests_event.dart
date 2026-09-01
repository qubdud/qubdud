part of 'show_requests_bloc.dart';

abstract class ShowRequestsComponentEvent {}

class GetDataShowRequestsComponentEvent extends ShowRequestsComponentEvent {}

class GoToMainShowRequestsComponentEvent extends ShowRequestsComponentEvent {}

class VideoListUpdated extends ShowRequestsComponentEvent {
  final List<String> videoUrls;
  VideoListUpdated(this.videoUrls);
}




class TryDeleteMyRequestShowRequestsComponentEvent extends ShowRequestsComponentEvent {
  final String id;
  TryDeleteMyRequestShowRequestsComponentEvent({required this.id });
}

