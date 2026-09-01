import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/domain_models/team_info.dart';
import 'package:collection/collection.dart';
import '../../../../../domain_layer/domain_models/chat_user.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/chat_page_bloc.dart';
import '../functions/format_timestamp.dart';

class GroupConversationList extends StatelessWidget {
  final Stream<Map<String, dynamic>> groupChatOverview;
  final Stream<int> unreadCountStream;  // Nowy stream dla liczby nieprzeczytanych wiadomości
  final TeamInfo teamInfo;
  final bool isMobile;
  final List<ChatUser> chatUsers;

  const GroupConversationList({
    super.key,
    required this.groupChatOverview,
    required this.unreadCountStream,
    required this.isMobile,
    required this.teamInfo,
    required this.chatUsers,
  });

  @override
  Widget build(BuildContext context) {



    return StreamBuilder<int>(
      stream: unreadCountStream, // Najpierw nasłuchujemy liczby nieprzeczytanych wiadomości
      builder: (context, unreadSnapshot) {
        if (unreadSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Loading());
        }

        if (!unreadSnapshot.hasData) {
          return const Center(child: SizedBox.shrink());
        }



        int unreadCount = unreadSnapshot.data ?? 0; // Domyślnie 0, jeśli brak danych

        context.read<MainScreenBloc>().state.groupChatCounter = unreadCount;

        return StreamBuilder<Map<String, dynamic>>( // Potem nasłuchujemy treści czatu
          stream: groupChatOverview,
          builder: (context, chatSnapshot) {
            if (chatSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Loading());
            }

            if (!chatSnapshot.hasData || chatSnapshot.data!.isEmpty) {
              return const Center(child: SizedBox.shrink());
            }

            final chat = chatSnapshot.data!;
            final dateOrTime = formatTimestamp(chat['timestamp']);
            final detail = chatUsers.firstWhereOrNull((a) => a.uid == chat['lastMessageAuthor']);
            final String country = (detail)?.countryCode ?? '';
            final String name = (detail)?.name ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: WCard(
                color: unreadCount > 0 ? Color(0xFFFECEDA) : null,
                borderColor: unreadCount > 0 ? cMidPink : null,
                padding: EdgeInsets.all(0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    hoverColor: cDarkBlue.withOpacity(0.1),
                    onTap: () {
                      context.read<ChatPageBloc>().add(StartTeamChatChatPageEvent(teamInfo.chatToken, isMobile));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 3,
                                        blurRadius: 8,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topLeft,
                                    child: teamInfo.name.length > 3
                                        ? Image.asset("assets/images/bus/${teamInfo.camperType}-${teamInfo.camperColor}.png")
                                        : Image.asset("assets/images/flags/nexi.png"),
                                  ),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: CircleAvatar(
                                    radius: 8,
                                    foregroundColor: Colors.white,
                                    backgroundColor: cMidPink,
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(teamInfo.name.length < 3 ? 'No Team Chat' : teamInfo.name,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cMidBrown)),
                                Text(chat['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(dateOrTime, style: TextStyle(color: cMidBrown, fontSize: 14)),
                              SizedBox(height: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

  }
}