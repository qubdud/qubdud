import 'package:firebase_auth/firebase_auth.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/chat_user.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/chat_page_bloc.dart';
import '../widgets/bubbles.dart';
import '../widgets/conversation_list.dart';
import '../widgets/user_list.dart';

class MessagingPageMob extends StatelessWidget {
  const MessagingPageMob({super.key});

  @override
  Widget build(BuildContext context) {
    return const View();
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  List<ChatUser> filter = [];
  TextEditingController controller = TextEditingController();

  final ChatService _chatService = ChatService();
  late final Stream<List<Map<String, dynamic>>> chatOverview;
  late final Stream<Map<String, bool>> onlineStatuses;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();





  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {



    return BlocConsumer<ChatPageBloc, ChatPageState>(
      listener: (context, state) {
        if (state is MessagingPageMainState) {
        }
      },

      builder: (context, state) {


        return  AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },

                child: _buildWidgetBasedOnState2(state),
                //   )
              );
      },
    );
  }

  Widget _buildWidgetBasedOnState2(ChatPageState state) {
    if (state is ChatPageLoadingState) {



      return SizedBox.shrink();
    } else if (state is MessagingPageMainState) {

      Stream<List<Map<String, dynamic>>>? messages;

      if(state.userChat!=null){
        messages = _chatService.getMessages(state.userChat!);
      }



      if(messages==null) return SizedBox.shrink();



      return Container(
        height: MediaQuery.of(context).size.height-MediaQuery.of(context).padding.top-MediaQuery.of(context).padding.bottom-40,
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: messages,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: Loading()); // Ładowanie
                      }

                      final messages = snapshot.data!;
                      messages.sort((a, b) => (b["timestamp"] as int).compareTo(a["timestamp"] as int));
                      return Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Nowe wiadomości na dole
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = msg["from"] == FirebaseAuth.instance.currentUser?.uid;

                            return isMe
                                ? MyMessageBubble(content: msg["content"], timestamp: msg["timestamp"])
                                : UserMessageBubble(
                              content: msg["content"],
                              timestamp: msg["timestamp"],
                              userName: msg["name"]??'',
                              country: state.chatUser?.firma==true?'F':'O',
                            );
                          },
                        ),
                      );
                    },
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: WInputField(
                            hintText: 'Twoja wiadomość',
                            isSend: true,
                            onSend: () async {

                              if(state.userChat!=null){
                                if (_messageController.text.trim().isNotEmpty) {

                                  var isOnline = await _chatService.isUserOnline(state.userChat!);
                                  if(!isOnline){
                                    context.read<ChatPageBloc>().add(SendPushChatPageEvent(state.userChat!));
                                  }
                                  await _chatService.sendMessage(state.userChat!, _messageController.text.trim());
                                  _messageController.clear();
                                }
                              }

                              if(state.teamChat!=null){


                                if (_messageController.text.trim().isNotEmpty) {
                                  context.read<ChatPageBloc>().add(SendPushChatPageEvent(state.teamChat!));

                                  await _chatService.sendGroupMessage(state.teamChat!, _messageController.text.trim());
                                  _messageController.clear();
                                }
                              }

                            },
                            controller: _messageController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 32,
            ),
          ],
        ),
      );
    } else {
      return SizedBox(); //Loading(key: UniqueKey());
    }
  }




}
