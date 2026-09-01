part of 'chat_page_bloc.dart';

abstract class ChatPageEvent {}

class SendPushChatPageEvent extends ChatPageEvent {
  final String token;
  SendPushChatPageEvent(this.token);
}

class GoToMainChatPageEvent extends ChatPageEvent {}

class GetChatUsersChatPageEvent extends ChatPageEvent {}

class StartUserChatChatPageEvent extends ChatPageEvent {
  final String uid;
  final bool isMobile;

  StartUserChatChatPageEvent(this.uid, this.isMobile);
}

class StartTeamChatChatPageEvent extends ChatPageEvent {
  final String uid;
  final bool isMobile;

  StartTeamChatChatPageEvent(this.uid, this.isMobile);
}