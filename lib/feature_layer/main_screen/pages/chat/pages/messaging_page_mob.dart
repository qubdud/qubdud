import 'dart:async';

import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/widgets/empty_state.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../bloc/chat_page_bloc.dart';
import '../widgets/bubbles.dart';
import '../../../../../shared/widgets/load_error.dart';
import '../../../../../shared/moderation.dart';

class MessagingPageMob extends StatefulWidget {
  final String otherUid;

  const MessagingPageMob({super.key, required this.otherUid});

  @override
  State<MessagingPageMob> createState() => _MessagingPageMobState();
}

class _MessagingPageMobState extends State<MessagingPageMob> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatService _chat;
  late final Stream<bool> _typing;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatService>();
    _typing = _chat.typingStream(widget.otherUid);
  }

  void _onTyping() {
    if (_typingTimer?.isActive != true) _chat.setTyping(widget.otherUid, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3),
        () => _chat.setTyping(widget.otherUid, false));
  }

  void _stopTyping() {
    if (_typingTimer?.isActive == true) _chat.setTyping(widget.otherUid, false);
    _typingTimer?.cancel();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatPageBloc>();
    _messageController.clear();
    _stopTyping();
    try {
      await _chat.sendMessage(widget.otherUid, text);
      // pierwsza wiadomość założyła rozmowę — odrzucony wcześniej nasłuch ruszy teraz
      final s = bloc.state;
      if (!bloc.isClosed && s is MessagingPageMainState && s.failed) {
        bloc.add(RetryMessagesChatPageEvent());
      }
    } catch (e) {
      debugPrint('Czat: wysyłka: $e');
      if (mounted && _messageController.text.isEmpty) {
        _messageController.text = text;
      }
      showToast(text: 'Nie udało się wysłać wiadomości');
    }
  }

  @override
  void dispose() {
    _stopTyping();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: BlockedUsers.ids,
      builder: (context, _, __) => BlocBuilder<ChatPageBloc, ChatPageState>(
      buildWhen: (_, current) => current is MessagingPageMainState,
      builder: (context, state) {
        if (state is! MessagingPageMainState) {
          return const SizedBox.shrink();
        }

        final otherName = state.name ?? '';
        final avatarLetter =
            otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';

        return SizedBox(
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom -
              40,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (v) => v == 'report'
                      ? showReportDialog(context,
                          targetType: 'chat',
                          targetId: _chat.chatIdWith(widget.otherUid),
                          targetUserId: widget.otherUid)
                      : toggleBlockUser(context,
                          otherUid: widget.otherUid,
                          name: otherName.isEmpty ? 'Użytkownik' : otherName),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'report', child: Text('Zgłoś rozmowę')),
                    PopupMenuItem(
                        value: 'block',
                        child: Text(BlockedUsers.contains(widget.otherUid)
                            ? 'Odblokuj'
                            : 'Zablokuj')),
                  ],
                ),
              ),
              Expanded(child: _messages(state, otherName, avatarLetter)),
              StreamBuilder<bool>(
                stream: _typing,
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
              if (BlockedUsers.contains(widget.otherUid))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Ten użytkownik jest zablokowany — odblokuj go w menu ⋯, aby pisać.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              else if (state.canWrite)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: WInputField(
                          hintText: 'Twoja wiadomość',
                          isSend: true,
                          onChanged: (_) => _onTyping(),
                          onSend: _send,
                          controller: _messageController,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('To konto zostało usunięte — nie można odpisać.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    ),
    );
  }

  Widget _messages(
      MessagingPageMainState state, String otherName, String avatarLetter) {
    final bloc = context.read<ChatPageBloc>();
    final messages = state.messages;
    if (state.failed) {
      return LoadError(
        message: 'Nie udało się wczytać wiadomości',
        onRetry: () => bloc.add(RetryMessagesChatPageEvent()),
      );
    }
    if (messages == null) return const Center(child: Loading());
    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: state.canWrite ? 'Napisz pierwszą wiadomość' : 'Brak wiadomości',
      );
    }

    final myUid = _chat.myUid;
    return ListView.builder(
      controller: _scrollController,
      reverse: true, // najnowsze na dole
      itemCount: messages.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          // przewinięto do najstarszej wczytanej — dociągamy kolejną porcję
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!bloc.isClosed) bloc.add(LoadOlderMessagesChatPageEvent());
          });
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        final msg = messages[index];
        return msg["from"] == myUid
            ? MyMessageBubble(
                content: msg["content"],
                timestamp: msg["timestamp"],
                pending: msg["pending"] == true)
            : UserMessageBubble(
                content: msg["content"],
                timestamp: msg["timestamp"],
                userName: otherName,
                country: avatarLetter,
              );
      },
    );
  }
}
