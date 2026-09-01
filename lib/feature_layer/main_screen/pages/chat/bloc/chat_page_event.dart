part of 'chat_page_bloc.dart';

abstract class ChatPageEvent {}

class GoToMainChatPageEvent extends ChatPageEvent {}

class InitChatPageEvent extends ChatPageEvent {}

class StartUserChatChatPageEvent extends ChatPageEvent {
  final String uid;

  StartUserChatChatPageEvent(this.uid);
}
