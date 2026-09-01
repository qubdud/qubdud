part of 'user_info_bloc.dart';

abstract class UserInfoComponentEvent {}

class GetDataUserInfoComponentEvent extends UserInfoComponentEvent {}

class GoToMainUserInfoComponentEvent extends UserInfoComponentEvent {}

class VideoListUpdated extends UserInfoComponentEvent {
  final List<String> videoUrls;
  VideoListUpdated(this.videoUrls);
}




class TryUserAcceptOfferUserInfoComponentEvent extends UserInfoComponentEvent {
  final String id;
  TryUserAcceptOfferUserInfoComponentEvent(this.id);


}
