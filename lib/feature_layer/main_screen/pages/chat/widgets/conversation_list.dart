import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/chat_user.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../bloc/chat_page_bloc.dart';
import '../functions/format_timestamp.dart';

class ConversationList extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> chatOverview;
  final Stream<Map<String, bool>> onlineStatuses;
  final List<ChatUser> chatUsers;
  final bool isMobile;

  const ConversationList({super.key, required this.chatOverview, required this.chatUsers, required this.isMobile, required this.onlineStatuses,});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatOverview,
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        }

        if (!chatSnapshot.hasData || chatSnapshot.data!.isEmpty) {
          return const Center(child: SizedBox.shrink());
        }

        final chats = chatSnapshot.data!;

        final int totalUnread = chats.fold<int>(0, (sum, chat) {
          final int unread = (chat['unreadCount'] as int?) ?? 0;
          return sum + unread;
        });

        context.read<MainScreenBloc>().state.chatCounter=totalUnread;
        return StreamBuilder<Map<String, bool>>(
          stream: onlineStatuses,
          builder: (context, onlineSnapshot) {
            final onlineStatuses = onlineSnapshot.data ?? {};


            return Column(
              children: chats.map((chat) {
                final bool isOnline = onlineStatuses[chat['from']] ?? false;
                final dateOrTime = formatTimestamp(chat['timestamp']);


                final isUnreaded = chat['unreadCount'] > 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child:


                  WCard(
                    color: isUnreaded ? Color(0xFFFECEDA) : null,
                    borderColor: isUnreaded ? cMidPink : null,
                    padding: EdgeInsets.all(0),
                    child:
                    Material(

                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16), // Zaokrąglenie efektu hover
                        hoverColor: cDarkBlue.withOpacity(0.1),
                        onTap: () {

                          context.read<ChatPageBloc>().add(StartUserChatChatPageEvent(chat['from'],isMobile));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
/*                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 8,
                                          offset: Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      countryFlagImages[country] ?? "assets/images/flags/nexi.png",
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  ),*/
                                  if (isUnreaded)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: CircleAvatar(
                                        radius: 8,
                                        foregroundColor: Colors.white,
                                        backgroundColor: cMidPink,
                                        child: Text(
                                          chat['unreadCount'].toString(),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16), // Dodanie odstępu między flagą a tekstem
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(chat['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(dateOrTime, style: TextStyle(color: cMidBrown, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.green : Colors.grey,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
