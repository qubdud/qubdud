import 'package:qb/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/client_notes.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/effective_role.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../bloc/main_bloc.dart';
import '../../profil_my/view/tab_klienci.dart';
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
  late List<Tab> _tabs;
  late List<Widget> _views;

  @override
  void initState() {
    super.initState();
    // Rezerwacje i Firmy to perspektywa klienta — w trybie firmowym
    // zostają Rozmowy + Ludzie (klienci).
    final privateMode =
        !isCompanyMode(context.read<MainScreenBloc>().state.user);
    _tabs = [
      const Tab(icon: Icon(Icons.chat_outlined, size: 20), text: 'Rozmowy'),
      if (!privateMode)
        const Tab(
            icon: Icon(Icons.groups_outlined, size: 20), text: 'Klienci'),
      if (privateMode)
        const Tab(
            icon: Icon(Icons.handshake_outlined, size: 20),
            text: 'Moje firmy'),
      if (privateMode)
        const Tab(
            icon: Icon(Icons.business_outlined, size: 20), text: 'Firmy'),
      const Tab(icon: Icon(Icons.person_outline, size: 20), text: 'Ludzie'),
    ];
    _views = [
      const _ConversationsList(key: ValueKey('rozmowy')),
      if (!privateMode) _MyClientsTab(key: const ValueKey('klienci')),
      if (privateMode) _MyCompaniesTab(key: const ValueKey('mojefirmy')),
      if (privateMode)
        const _ContactsList(isCompany: true, key: ValueKey('firmy')),
      const _ContactsList(isCompany: false, key: ValueKey('ludzie')),
    ];
    _tab = TabController(length: _tabs.length, vsync: this);
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
                showBack: true,
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
                showBack: true,
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
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1C1B21)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: TabBar(
                controller: _tab,
                labelStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                dividerColor: Colors.transparent,
                tabs: _tabs,
              ),
            ),
            Expanded(
              child: _views[_tab.index],
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

            return Dismissible(
              key: ValueKey('chat_${chat['from']}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Do kosza',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.delete_outline, color: Colors.white),
                  ],
                ),
              ),
              onDismissed: (_) {
                chatService.hideChat(chat['from'] as String);
                showToast(text: 'Rozmowa przeniesiona do kosza');
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => context
                      .read<ChatPageBloc>()
                      .add(StartUserChatChatPageEvent(chat['from'] as String)),
                  // avatar → profil rozmówcy (firma lub osoba)
                  leading: GestureDetector(
                    onTap: () => context.read<MainScreenBloc>().add(isCompany
                        ? GoToProfilPublicznyFirmyEvent(chat['from'] as String)
                        : GoToProfilPublicznyUseraEvent(chat['from'] as String)),
                    child: CircleAvatar(
                      backgroundColor:
                          isCompany ? Colors.blue.shade700 : Colors.grey.shade600,
                      child: Text(name[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  title: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight:
                              unread > 0 ? FontWeight.bold : FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClientNoteBadge(
                          userId: chat['from'] as String, personName: name),
                      Text(
                        (chat['lastMessage'] as String?)?.isNotEmpty == true
                            ? chat['lastMessage'] as String
                            : 'Brak wiadomości',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal),
                      ),
                    ],
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
              ),
            );
          },
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
    final isCompany = user.firma == true;
    final name = isCompany
        ? (user.companyName ?? 'Firma')
        : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    final subtitle = isCompany
        ? [user.companyCategory, user.companyCity]
            .whereType<String>()
            .where((e) => e.isNotEmpty)
            .join(' · ')
        : (user.phone ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.read<MainScreenBloc>().add(isCompany
            ? GoToProfilPublicznyFirmyEvent(user.id)
            : GoToProfilPublicznyUseraEvent(user.id)),
        onLongPress: onRemove == null
            ? null
            : () async {
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
                          child: const Text('Usuń',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (ok == true) onRemove!();
              },
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor:
                  isCompany ? Colors.blue.shade700 : Colors.grey.shade600,
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
          ],
        ),
        title: Text(name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 15,
                fontWeight:
                    unreadCount > 0 ? FontWeight.w800 : FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(fontSize: 12)),
            ClientNoteBadge(userId: user.id, personName: name),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$unreadCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              tooltip: 'Napisz',
              onPressed: () => context
                  .read<MainScreenBloc>()
                  .add(GoToChatEvent(user.id, chatName: name)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesList extends StatefulWidget {
  const _NotesList({super.key});

  @override
  State<_NotesList> createState() => _NotesListState();
}

class _NotesListState extends State<_NotesList> {
  Map<String, AppUser?> _people = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebase = context.read<FirebaseService>();
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    await ClientNotes.load(firebase, myId);
    final ids = ClientNotes.all.keys.toList();
    final map = <String, AppUser?>{};
    for (final id in ids) {
      map[id] = await firebase.fetchUser(id);
    }
    if (mounted) setState(() { _people = map; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final entries = ClientNotes.all.entries.toList();
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Brak notatek',
        subtitle:
            'Dotknij imienia klienta na zgłoszeniu lub w rozmowie, aby dodać prywatną notatkę.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final userId = entries[i].key;
        final note = entries[i].value;
        final u = _people[userId];
        final name = u == null
            ? 'Użytkownik'
            : (u.firma == true
                ? (u.companyName ?? 'Firma')
                : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim());

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            onTap: () async {
              final changed =
                  await showClientNoteDialog(context, userId, name);
              if (changed) _load();
            },
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF6C7),
              child: Icon(Icons.sticky_note_2, color: Color(0xFF8A6D1B)),
            ),
            title: Text(name.isEmpty ? 'Użytkownik' : name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(note, style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  tooltip: 'Napisz',
                  onPressed: () => context
                      .read<MainScreenBloc>()
                      .add(GoToChatEvent(userId, chatName: name)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edytuj',
                  onPressed: () async {
                    final changed =
                        await showClientNoteDialog(context, userId, name);
                    if (changed) _load();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Klienci firmy / moje firmy — relacje po domkniętych zleceniach
// ─────────────────────────────────────────────────────────────────────────────
class _MyClientsTab extends StatelessWidget {
  const _MyClientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    return TabKlienci(companyId: myId);
  }
}

class _MyCompaniesTab extends StatelessWidget {
  const _MyCompaniesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    return TabMojeFirmy(userId: myId);
  }
}
