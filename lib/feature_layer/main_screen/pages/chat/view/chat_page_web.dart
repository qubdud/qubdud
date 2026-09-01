import 'package:firebase_auth/firebase_auth.dart';
import 'package:qb/feature_layer/main_screen/pages/chat/widgets/conversation_list.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:collection/collection.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/chat_user.dart';
import '../../../../../domain_layer/domain_models/team_info.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../bloc/chat_page_bloc.dart';
import '../widgets/bubbles.dart';
import '../widgets/group_conversiation_list.dart';
import '../widgets/user_list.dart';

class ChatPageWeb extends StatelessWidget {
  const ChatPageWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatPageBloc(repository: context.read<AppRepository>(), chatService: context.read<ChatService>(), id: ''),
      child: const View(),
    );
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

  late  Stream<List<Map<String, dynamic>>> chatOverview;
  late  Stream<Map<String, bool>> onlineStatuses;
  late  Stream<Map<String, dynamic>> groupChatOverview;

  final ChatService _chatService = ChatService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  TeamInfo? teamInfo;

  bool isWideScreen = true;

  @override
  void initState() {
    super.initState();
     onlineStatuses = _chatService.getOnlineStatuses();
    chatOverview = _chatService.getChatOverviews();
  }

  Widget build(BuildContext context) {
    isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    return BlocConsumer<ChatPageBloc, ChatPageState>(
      listener: (context, state) {
        if (state is ChatPageMainState) {

          if (state.userChat != null){
            onlineStatuses = _chatService.getOnlineStatuses();
            chatOverview = _chatService.getChatOverviews();
          }
        }
      },
      builder: (context, state) {
    //    teamInfo = state.teamInfo;
        return  Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 1, child: SizedBox.shrink()),
                  SizedBox(
                    width: 400,
                    child: AnimatedSwitcher(
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

                      child: _buildWidgetBasedOnState(state),
                      //   )
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
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
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: SizedBox(),
                  ),
                ],
              );

      },
    );
  }

  Widget _buildWidgetBasedOnState(ChatPageState state) {
    if (state is ChatPageLoadingState) {
      return Loading(noText: true, key: UniqueKey());
    } else if (state is! ChatPageInitialState) {

      onlineStatuses = _chatService.getOnlineStatuses();
      chatOverview = _chatService.getChatOverviews();

      return SingleChildScrollView(
        key: ValueKey('ChatPage'),
        child: Container(
          height: MediaQuery.of(context).size.height < 640 ? 640 : MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 96,
                    ),
                    Expanded(
                      child: WCard(
                        color: cLighterBrown,
                        child: Column(
                          children: [
                            SelectableText(
                              'Rozmowy',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: WInputField(
                                controller: controller,
                                onChanged: (val) {
                                  setState(() {
                           //         filter = state.chatUsers.where((a) {
                           //           return a.name.toLowerCase().contains(val.toLowerCase());
                           //         }).toList();
                           //         if (val.isEmpty) {
                           //           filter = [];
                           //         }
                                  });
                                },
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Type in a name',
                                focusColor: cDarkBlue,
                              ),
                            ),
                            AnimatedContainer(
                                height: (filter.length * 50) > 200 ? 200 : filter.length * 50, // Wysokość kontenera
                                duration: Duration(milliseconds: 300),
                                child: ChatUsersList(
                                  bloc: context.read<ChatPageBloc>(),
                                  isMobile: false,
                                  chatUsers: filter,
                                )),
                            SizedBox(height: 32),
                            WSmallLabel(text: 'Your conversations'),

                      //      if(teamInfo!=null)GroupConversationList(isMobile: false, groupChatOverview: _chatService.getGroupChatSummary(teamInfo!.chatToken), teamInfo: teamInfo!, unreadCountStream: _chatService.getUnreadCountStream(teamInfo!.chatToken), chatUsers: state.chatUsers, ),


                     // Expanded(
                      //          child: Container(
                      //              child: SingleChildScrollView(child: ConversationList(chatUsers: state.chatUsers, isMobile: false, chatOverview: chatOverview, onlineStatuses: onlineStatuses,)))
//
                       //     ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    } else {
      return SizedBox(); //Loading(key: UniqueKey());
    }
  }

  Widget _buildWidgetBasedOnState2(ChatPageState state) {
    if (state is ChatPageLoadingState) {
      return SizedBox.shrink();
    } else if (state is ChatPageMainState) {

      Stream<List<Map<String, dynamic>>>? messages;

      if(state.userChat!=null){
        messages = _chatService.getMessages(state.userChat!);
      }
      if(state.teamChat!=null){
        messages = _chatService.getGroupMessages(state.teamChat!);
      }

      if(messages==null) return SizedBox.shrink();



      return Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: isWideScreen ? MainAxisAlignment.spaceAround : MainAxisAlignment.start,
          children: [
            SizedBox(
              height: 96,
            ),
            Expanded(
              child: Column(
                children: [
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: messages,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(child: Loading()); // Ładowanie
                      }

                      final messages = snapshot.data!.reversed.toList();
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
                                    userName: 'name',
                                    country: 'country',
                                  );
                          },
                        ),
                      );
                    },
                  ),

                  // 📌 INPUT DO WPISYWANIA WIADOMOŚCI
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
                                  await _chatService.sendMessage(state.userChat!, _messageController.text.trim());
                                  _messageController.clear();
                                }
                              }
                              if(state.teamChat!=null){
                                if (_messageController.text.trim().isNotEmpty) {
                                  await _chatService.sendGroupMessage(state.teamChat!.isEmpty?'NN':state.teamChat!, _messageController.text.trim());
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
              height: 96,
            ),
          ],
        ),
      );
    } else {
      return SizedBox(); //Loading(key: UniqueKey());
    }
  }
}
