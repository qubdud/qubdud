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

class ChatPageMob extends StatefulWidget {
  const ChatPageMob({super.key});

  @override
  State<ChatPageMob> createState() => _ChatPageMobState();
}

class _ChatPageMobState extends State<ChatPageMob>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
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
        if (state is MessagingPageMainState) {
          final u = state.chatUser;
          final name = u == null
              ? 'Rozmowa'
              : (u.firma == true
                  ? (u.companyName ?? 'Firma')
                  : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim());
          context.read<MainScreenControlCubit>().updateAppBar(
                onBackPressed: () =>
                    context.read<MainScreenBloc>().add(GoToChatEvent('')),
                backgroundColor: cLighterBrown,
                title: name.isEmpty ? 'Rozmowa' : name,
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
        if (state is MessagingPageMainState ||
            state is MessagingLoadingPageState) {
          return const MessagingPageMob();
        }

        return Column(
          children: [
            TabBar(
              controller: _tab,
              labelStyle: const TextStyle(fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.chat_outlined, size: 20), text: 'Rozmowy'),
                Tab(
                    icon: Icon(Icons.event_available_outlined, size: 20),
                    text: 'Rezerwacje'),
                Tab(icon: Icon(Icons.business_outlined, size: 20), text: 'Firmy'),
                Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Ludzie'),
              ],
            ),
            Expanded(
              child: switch (_tab.index) {
                0 => const _ConversationsList(key: ValueKey('rozmowy')),
                1 => const _MyBookingsList(key: ValueKey('rezerwacje')),
                2 => const _ContactsList(
                    isCompany: true, key: ValueKey('firmy')),
                _ => const _ContactsList(
                    isCompany: false, key: ValueKey('ludzie')),
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista wszystkich rozmów (z nazwami z dokumentu rozmowy)
// ─────────────────────────────────────────────────────────────────────────────
class _ConversationsList extends StatelessWidget {
  const _ConversationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getChatOverviews(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = snap.data!;
        if (chats.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_outlined, size: 56, color: Colors.black12),
                SizedBox(height: 12),
                Text('Brak rozmów', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 6),
                Text('Napisz do firmy lub użytkownika z zakładek obok',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: chats.length,
          itemBuilder: (context, i) {
            final chat = chats[i];
            final name = (chat['name'] as String?)?.isNotEmpty == true
                ? chat['name'] as String
                : 'Rozmowa';
            final isCompany = chat['isCompany'] == true;
            final unread = chat['unreadCount'] as int? ?? 0;
            final timestamp = chat['timestamp'] as int? ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () => context
                    .read<ChatPageBloc>()
                    .add(StartUserChatChatPageEvent(chat['from'] as String)),
                leading: CircleAvatar(
                  backgroundColor:
                      isCompany ? Colors.blue.shade700 : Colors.grey.shade600,
                  child: Text(name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight:
                            unread > 0 ? FontWeight.bold : FontWeight.w600)),
                subtitle: Text(
                  (chat['lastMessage'] as String?)?.isNotEmpty == true
                      ? chat['lastMessage'] as String
                      : 'Brak wiadomości',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight:
                          unread > 0 ? FontWeight.w600 : FontWeight.normal),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timestamp > 0)
                      Text(formatTimestamp(timestamp),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    if (unread > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$unread',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Moje rezerwacje (firma + godzina + status)
// ─────────────────────────────────────────────────────────────────────────────
class _MyBookingsList extends StatefulWidget {
  const _MyBookingsList({super.key});

  @override
  State<_MyBookingsList> createState() => _MyBookingsListState();
}

class _MyBookingsListState extends State<_MyBookingsList> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    try {
      final bookings =
          await context.read<FirebaseService>().getMyBookings(myUid);
      if (mounted) setState(() { _bookings = bookings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odwołać rezerwację?'),
        content: Text('${b['companyName']}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zostaw')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Odwołaj', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    await context.read<FirebaseService>().cancelSlotBooking(
          companyId: b['companyId'] as String,
          slotId: b['slotId'] as String,
          myUid: myUid,
        );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Brak rezerwacji',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Kliknij kropkę-termin na profilu firmy,\naby umówić wizytę.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    const wd = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (context, i) {
          final b = _bookings[i];
          final start = b['start'] as DateTime;
          final status = b['status'] as String? ?? 'pending';
          final color = switch (status) {
            'accepted' => Colors.green,
            'rejected' => Colors.red,
            _ => Colors.amber,
          };
          final statusText = switch (status) {
            'accepted' => 'przyjęta',
            'rejected' => 'odrzucona',
            _ => 'czeka na akceptację',
          };
          final when =
              '${wd[start.weekday - 1]} ${start.day}.${start.month.toString().padLeft(2, '0')}, ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () => context.read<MainScreenBloc>().add(
                  GoToProfilPublicznyFirmyEvent(b['companyId'] as String)),
              leading: Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 6),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              title: Text('${b['companyName']} — $when',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(statusText,
                  style: TextStyle(fontSize: 12, color: color)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    tooltip: 'Napisz',
                    onPressed: () => context.read<MainScreenBloc>().add(
                        GoToChatEvent(b['companyId'] as String,
                            chatName: b['companyName'] as String?)),
                  ),
                  if (status != 'rejected')
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: Colors.red.shade300),
                      tooltip: 'Odwołaj',
                      onPressed: () => _cancel(b),
                    ),
                ],
              ),
            ),
          );
        },
      ),
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

  Future<void> _removeContact(AppUser user) async {
    final name = user.firma == true
        ? (user.companyName ?? 'Firma')
        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć z kontaktów?'),
        content: Text(name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Usuń', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    await context
        .read<FirebaseService>()
        .removeContact(myUserId: myUid, contactUserId: user.id);
    if (mounted) {
      setState(() =>
          _contacts = _contacts.where((c) => c.id != user.id).toList());
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

    final chatService = context.read<ChatService>();

    return StreamBuilder<Map<String, bool>>(
      stream: chatService.getOnlineStatuses(),
      builder: (context, onlineSnap) {
        final online = onlineSnap.data ?? {};
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: chatService.getChatOverviews(),
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
                  onRemove: () => _removeContact(user),
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
  final VoidCallback? onRemove;

  const _ContactCard({
    required this.user,
    required this.isOnline,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.onRemove,
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
                  if (onRemove != null)
                    IconButton(
                      icon: Icon(Icons.person_remove_outlined,
                          size: 20, color: Colors.red.shade300),
                      tooltip: 'Usuń z kontaktów',
                      onPressed: onRemove,
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
                      StartUserChatChatPageEvent(user.id),
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
