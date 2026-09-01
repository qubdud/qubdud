part of 'rev_info_bloc.dart';

abstract class RevInfoComponentEvent {}

class GetDataRevInfoComponentEvent extends RevInfoComponentEvent {}

class GoToMainRevInfoComponentEvent extends RevInfoComponentEvent {}

class VideoListUpdated extends RevInfoComponentEvent {
  final List<String> videoUrls;
  VideoListUpdated(this.videoUrls);
}




class TryUserAcceptOfferRevInfoComponentEvent extends RevInfoComponentEvent {
  final String id;
  TryUserAcceptOfferRevInfoComponentEvent(this.id);


}
