part of 'chat_page_bloc.dart';

abstract class ChatPageEvent {}

class InitChatPageEvent extends ChatPageEvent {}

/// „Spróbuj ponownie” oraz po wysłaniu pierwszej wiadomości (rozmowa już istnieje).
class RetryMessagesChatPageEvent extends ChatPageEvent {}

class LoadOlderMessagesChatPageEvent extends ChatPageEvent {}

class _MessagesChatPageEvent extends ChatPageEvent {
  final List<Map<String, dynamic>> messages;

  _MessagesChatPageEvent(this.messages);
}

class _MessagesFailedChatPageEvent extends ChatPageEvent {}
