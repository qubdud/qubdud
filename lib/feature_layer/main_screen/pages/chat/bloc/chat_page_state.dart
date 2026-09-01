part of 'chat_page_bloc.dart';

abstract class ChatPageState {}

class ChatPageLoadingState extends ChatPageState {}

class ChatPageMainState extends ChatPageState {}

class MessagingLoadingPageState extends ChatPageState {
  final String userChat;

  MessagingLoadingPageState({required this.userChat});
}

class MessagingPageMainState extends ChatPageState {
  final String userChat;
  final AppUser? chatUser;

  MessagingPageMainState({required this.userChat, this.chatUser});
}
