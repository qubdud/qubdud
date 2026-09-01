import 'package:bloc/bloc.dart';
import 'package:qb/domain_layer/chat_service.dart';
import 'package:qb/domain_layer/firebase_service.dart';

import '../../../../../domain_layer/domain_models/app_user.dart';

part 'chat_page_event.dart';

part 'chat_page_state.dart';

class ChatPageBloc extends Bloc<ChatPageEvent, ChatPageState> {
  ChatPageBloc({
    required ChatService chatService,
    required FirebaseService firebaseService,
    required String id,
  }) : super(ChatPageLoadingState()) {
    on<GoToMainChatPageEvent>((event, emit) async {
      emit(ChatPageMainState());
    });

    on<InitChatPageEvent>((event, emit) async {
      if (id.isNotEmpty) {
        add(StartUserChatChatPageEvent(id));
      } else {
        emit(ChatPageMainState());
      }
    });

    on<StartUserChatChatPageEvent>((event, emit) async {
      emit(MessagingLoadingPageState(userChat: event.uid));
      final chatUser = await firebaseService.fetchUser(event.uid);
      await chatService.markAllMessagesFromUserAsRead(event.uid);
      emit(MessagingPageMainState(userChat: event.uid, chatUser: chatUser));
    });

    add(InitChatPageEvent());
  }
}
