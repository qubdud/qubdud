part of 'chat_page_bloc.dart';

abstract class ChatPageState {

  static AppUser? chatUserStatic;
  AppUser? get chatUser => chatUserStatic;
  set chatUser(AppUser? value) {
    chatUserStatic = value;
  }


}

class ChatPageInitialState extends ChatPageState {}

class ChatPageMainState extends ChatPageState {
  final String? userChat;
  final String? teamChat;

  ChatPageMainState({this.userChat=null,  this.teamChat=null});
}

class MessagingPageMainState extends ChatPageState {
  final String? userChat;
  final String? teamChat;

  MessagingPageMainState({this.userChat=null,  this.teamChat=null});
}

class MessagingLoadingPageState extends ChatPageState {
  final String? userChat;
  final String? teamChat;

  MessagingLoadingPageState({this.userChat=null,  this.teamChat=null});
}


class ChatPageErrorState extends ChatPageState {
  final CreateTeamError editTeamError;

  ChatPageErrorState(this.editTeamError);
}

class ChatPageLoadingState extends ChatPageState {}

class ChatPageNextState extends ChatPageState {}
