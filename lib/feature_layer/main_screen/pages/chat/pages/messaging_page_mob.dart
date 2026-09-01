import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../bloc/chat_page_bloc.dart';
import '../widgets/bubbles.dart';

class MessagingPageMob extends StatefulWidget {
  const MessagingPageMob({super.key});

  @override
  State<MessagingPageMob> createState() => _MessagingPageMobState();
}

class _MessagingPageMobState extends State<MessagingPageMob> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  String _typingTo = '';

  void _onTyping(String otherUid) {
    _typingTo = otherUid;
    context.read<ChatService>().setTyping(otherUid, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) context.read<ChatService>().setTyping(otherUid, false);
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_typingTo.isNotEmpty) {
      ChatService().setTyping(_typingTo, false);
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();

    return BlocBuilder<ChatPageBloc, ChatPageState>(
      builder: (context, state) {
        if (state is! MessagingPageMainState) {
          return const SizedBox.shrink();
        }

        final otherUid = state.userChat;
        final chatUser = state.chatUser;
        final otherName = chatUser?.firma == true
            ? (chatUser?.companyName ?? 'Firma')
            : '${chatUser?.firstName ?? ''} ${chatUser?.lastName ?? ''}'.trim();
        final avatarLetter =
            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';

        return SizedBox(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              40,
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: chatService.getMessages(otherUid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: Loading());
                    }
                    final messages = snapshot.data!;
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // najnowsze na dole
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg["from"] ==
                            FirebaseAuth.instance.currentUser?.uid;

                        return isMe
                            ? MyMessageBubble(
                                content: msg["content"],
                                timestamp: msg["timestamp"])
                            : UserMessageBubble(
                                content: msg["content"],
                                timestamp: msg["timestamp"],
                                userName: otherName,
                                country: avatarLetter,
                              );
                      },
                    );
                  },
                ),
              ),
              StreamBuilder<bool>(
                stream: chatService.typingStream(otherUid),
                builder: (context, snap) {
                  if (snap.data != true) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('$otherName pisze…',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade600)),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: WInputField(
                        hintText: 'Twoja wiadomość',
                        isSend: true,
                        onChanged: (_) => _onTyping(otherUid),
                        onSend: () async {
                          final text = _messageController.text.trim();
                          if (text.isEmpty) return;
                          _messageController.clear();
                          _typingTimer?.cancel();
                          chatService.setTyping(otherUid, false);
                          await chatService.sendMessage(otherUid, text);
                        },
                        controller: _messageController,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
