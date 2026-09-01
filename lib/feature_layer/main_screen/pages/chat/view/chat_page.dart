import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../bloc/chat_page_bloc.dart';
import 'chat_page_mob.dart';
import 'chat_page_web.dart';

class ChatPage extends StatelessWidget {
  final String id;
  const ChatPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatPageBloc(repository: context.read<AppRepository>(), chatService: context.read<ChatService>(), id:id),
      child: View(id),
    );
  }
}

class View extends StatefulWidget {
  final String id;
  const View(this.id, {super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {







  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {

        return ChatPageMob(key:ValueKey('ChatPageMob'),id: widget.id);


  }


}
