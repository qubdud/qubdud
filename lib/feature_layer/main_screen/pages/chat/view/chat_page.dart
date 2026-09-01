import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../bloc/chat_page_bloc.dart';
import 'chat_page_mob.dart';

class ChatPage extends StatelessWidget {
  final String id;
  const ChatPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatPageBloc(
        chatService: context.read<ChatService>(),
        firebaseService: context.read<FirebaseService>(),
        id: id,
      ),
      child: const ChatView(),
    );
  }
}

class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatPageMob(key: ValueKey('ChatPageMob'));
  }
}
