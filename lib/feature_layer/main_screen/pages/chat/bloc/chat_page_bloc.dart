import 'package:bloc/bloc.dart';
import 'package:qb/data_layer/data_models/response_error/create_team.dart';
import 'package:qb/domain_layer/chat_service.dart';
import 'package:qb/domain_layer/domain_models/chat_user.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../data_layer/data_models/request/create_team.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/team_info.dart';

part 'chat_page_event.dart';

part 'chat_page_state.dart';

class ChatPageBloc extends Bloc<ChatPageEvent, ChatPageState> {
  ChatPageBloc({
    required AppRepository repository,
    required ChatService chatService,
    required String id,
  }) : super(ChatPageLoadingState()) {


    on<GoToMainChatPageEvent>((event, emit) async {
      emit(ChatPageMainState(userChat: null,teamChat: null));
    });

    on<GetChatUsersChatPageEvent>((event, emit) async {
      emit(ChatPageLoadingState());
      if (id.isNotEmpty) {
        emit(MessagingLoadingPageState(userChat: id));
        emit(MessagingPageMainState(userChat: id));
      } else {
        emit(ChatPageMainState());
      }
    });


    on<SendPushChatPageEvent>((event, emit) async {

      //var res = await repository.sendChatPush(event.token);
      //res.when((s){print("asdfasdf");}, (e){print('error');});

    });



    on<StartUserChatChatPageEvent>((event, emit) async {
        await chatService.markAllMessagesFromUserAsRead(event.uid);
        if (event.isMobile){
          emit(MessagingLoadingPageState(userChat: event.uid));


          emit(MessagingPageMainState(userChat: event.uid));
        }else{
          emit(ChatPageMainState(userChat: event.uid));
        }
      });






    add(GetChatUsersChatPageEvent());
  }
}
