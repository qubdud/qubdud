part of 'chat_page_bloc.dart';

abstract class ChatPageState {}

class ChatPageLoadingState extends ChatPageState {}

class ChatPageMainState extends ChatPageState {}

class MessagingPageMainState extends ChatPageState {
  final String userChat;

  /// null = nazwa rozmówcy jeszcze się wczytuje
  final String? name;

  /// false, gdy konto rozmówcy już nie istnieje
  final bool canWrite;

  /// null = pierwsza porcja wiadomości jeszcze się wczytuje
  final List<Map<String, dynamic>>? messages;
  final bool failed;
  final bool hasMore;

  MessagingPageMainState({
    required this.userChat,
    this.name,
    this.canWrite = true,
    this.messages,
    this.failed = false,
    this.hasMore = false,
  });

  MessagingPageMainState copyWith({
    String? name,
    bool? canWrite,
    List<Map<String, dynamic>>? messages,
    bool? failed,
    bool? hasMore,
  }) =>
      MessagingPageMainState(
        userChat: userChat,
        name: name ?? this.name,
        canWrite: canWrite ?? this.canWrite,
        messages: messages ?? this.messages,
        failed: failed ?? this.failed,
        hasMore: hasMore ?? this.hasMore,
      );
}
