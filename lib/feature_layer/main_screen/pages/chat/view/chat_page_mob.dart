import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/chat_page_bloc.dart';
import '../functions/format_timestamp.dart';
import '../pages/messaging_page_mob.dart';

class ChatPageMob extends StatelessWidget {
  final String id;
  const ChatPageMob({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatPageBloc(
        repository: context.read(),
        chatService: context.read<ChatService>(),
        id: id,
      ),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();
  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatPageBloc, ChatPageState>(
      listener: (context, state) {
        if (state is MessagingLoadingPageState) {
          context.read<MainScreenControlCubit>().setIsMenuVisible(true);
          context.read<MainScreenControlCubit>().updateAppBar(
            onBackPressed: () =>
                context.read<MainScreenBloc>().add(GoToChatEvent('')),
            backgroundColor: cLighterBrown,
            title: 'Rozmowa',
            key: UniqueKey().toString(),
            child: const SizedBox.shrink(),
            height: 56,
          );
        }
      },
      builder: (context, state) {
        if (state is ChatPageLoadingState) {
          return Loading(noText: true, key: UniqueKey());
        }
        if (state is MessagingPageMainState) {
          return MessagingPageMob();
        }

        return Column(
          children: [
            TabBar(
              controller: _tab,
              tabs: const [
                Tab(icon: Icon(Icons.business_outlined), text: 'Firmy'),
                Tab(icon: Icon(Icons.person_outline), text: 'Ludzie'),
              ],
            ),
            Expanded(
              child: _tab.index == 0
                  ? _ContactsList(isCompany: true, key: const ValueKey('firmy'))
                  : _ContactsList(isCompany: false, key: const ValueKey('ludzie')),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ContactsList extends StatefulWidget {
  final bool isCompany;
  const _ContactsList({super.key, required this.isCompany});

  @override
  State<_ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<_ContactsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ChatService _chatService = ChatService();
  List<AppUser> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebase = context.read<FirebaseService>();
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    try {
      final ids = await firebase.getContactIds(myUid);
      final users = <AppUser>[];
      for (final uid in ids) {
        final u = await firebase.fetchUser(uid);
        if (u != null && u.firma == widget.isCompany) users.add(u);
      }
      if (mounted) setState(() { _contacts = users; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.isCompany ? Icons.business_outlined : Icons.person_outline,
                size: 56, color: Colors.black12),
            const SizedBox(height: 12),
            Text(
              widget.isCompany ? 'Brak firm w kontaktach' : 'Brak użytkowników w kontaktach',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text('Dodaj kontakty przeglądając filmy lub zgłoszenia',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return StreamBuilder<Map<String, bool>>(
      stream: _chatService.getOnlineStatuses(),
      builder: (context, onlineSnap) {
        final online = onlineSnap.data ?? {};
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _chatService.getChatOverviews(),
          builder: (context, chatSnap) {
            final chats = chatSnap.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _contacts.length,
              itemBuilder: (context, i) {
                final user = _contacts[i];
                final isOnline = online[user.id] ?? false;
                final chat = chats.firstWhere(
                      (c) => c['from'] == user.id,
                  orElse: () => {},
                );
                return _ContactCard(
                  user: user,
                  isOnline: isOnline,
                  lastMessage: chat['lastMessage'] as String? ?? '',
                  timestamp: chat['timestamp'] as int? ?? 0,
                  unreadCount: chat['unreadCount'] as int? ?? 0,
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIZYTÓWKA kontaktu
// ─────────────────────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final AppUser user;
  final bool isOnline;
  final String lastMessage;
  final int timestamp;
  final int unreadCount;

  const _ContactCard({
    required this.user,
    required this.isOnline,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = unreadCount > 0;
    final isCompany = user.firma == true;

    final initials = isCompany
        ? (user.companyName?.isNotEmpty == true ? user.companyName![0].toUpperCase() : 'F')
        : ((user.firstName?.isNotEmpty == true ? user.firstName![0] : '') +
        (user.lastName?.isNotEmpty == true ? user.lastName![0] : ''))
        .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Kliknięcie w kartę → profil
          if (isCompany) {
            context.read<MainScreenBloc>().add(GoToProfilPublicznyFirmyEvent(user.id));
          } else {
            context.read<MainScreenBloc>().add(GoToProfilPublicznyUseraEvent(user.id));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Górna część: avatar + dane + online ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar z kropką online
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isCompany
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        child: Text(initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey.shade400,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Dane profilowe
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCompany
                              ? (user.companyName ?? 'Firma')
                              : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isCompany && user.companyCategory != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${user.companyCategory} · ${user.companyCity ?? ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (!isCompany && user.bio != null && user.bio!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(user.bio!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOnline ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              // ── Separator ─────────────────────────────────────
              const Divider(height: 20),

              // ── Dolna część: ostatnia wiadomość + przycisk ───
              Row(
                children: [
                  // Ikonka czatu + ostatnia wiadomość
                  const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lastMessage.isEmpty ? 'Brak wiadomości' : lastMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnread ? Colors.black87 : Colors.grey.shade500,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                        fontStyle: lastMessage.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Czas lub badge nieprzeczytanych
                  if (isUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.notifications_active,
                              size: 10, color: Colors.white),
                          const SizedBox(width: 3),
                          Text('$unreadCount',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  else if (timestamp > 0)
                    Text(formatTimestamp(timestamp),
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),

                  const SizedBox(width: 8),

                  // Przycisk "Napisz"
                  GestureDetector(
                    onTap: () => context.read<ChatPageBloc>().add(
                      StartUserChatChatPageEvent(user.id, true),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Napisz',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}