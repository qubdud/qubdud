import 'package:qb/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/globals.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/client_notes.dart';
import 'package:qb/shared/functions/show_toast.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../bloc/main_bloc.dart';
import 'tab_activity.dart';
import '../bloc/chat_page_bloc.dart';
import '../pages/messaging_page_mob.dart';
import '../../../../../shared/widgets/load_error.dart';

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
    // Aktywność = feed wszystkiego, co dzieje się z kontaktami (rozmowy,
    // rezerwacje, zgłoszenia, prośby o telefon). Zapisani = dodani na stałe.
    _tabs = const [
      Tab(icon: Icon(Icons.bolt_outlined, size: 20), text: 'Aktywność'),
      Tab(icon: Icon(Icons.bookmark_outline, size: 20), text: 'Zapisani'),
    ];
    _views = const [
      TabActivity(key: ValueKey('aktywnosc')),
      _ContactsList(key: ValueKey('zapisani')),
    ];
    final wantedTab = Globals.instance.contactsTab;
    Globals.instance.contactsTab = null;
    _tab = TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: (wantedTab ?? 0).clamp(0, _tabs.length - 1));
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
      listenWhen: (previous, current) =>
          current is MessagingPageMainState &&
          (previous is! MessagingPageMainState ||
              previous.name != current.name),
      listener: (context, state) {
        // tytuł: nazwa rozmówcy, a do czasu jej wczytania ten z GoToChatEvent
        context.read<MainScreenControlCubit>().updateAppBar(
              showBack: true,
              onBackPressed: () =>
                  context.read<MainScreenBloc>().add(GoBackEvent()),
              backgroundColor: cLighterBrown,
              title: (state as MessagingPageMainState).name,
              key: UniqueKey().toString(),
              child: const SizedBox.shrink(),
              height: 56,
            );
      },
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        if (state is ChatPageLoadingState) {
          return Loading(noText: true, key: UniqueKey());
        }
        if (state is MessagingPageMainState) {
          return MessagingPageMob(otherUid: state.userChat);
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
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                dividerColor: Colors.transparent,
                tabs: _tabs,
              ),
            ),
            Expanded(
              child: TabBarView(controller: _tab, children: _views),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ContactsList extends StatefulWidget {
  const _ContactsList({super.key});

  @override
  State<_ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<_ContactsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<AppUser> _contacts = [];
  bool _loading = true;
  bool _failed = false;
  bool? _filter; // null = wszyscy, true = firmy, false = ludzie
  late final Stream<List<Map<String, dynamic>>> _chats;

  @override
  void initState() {
    super.initState();
    _chats = context.read<ChatService>().getChatOverviews();
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
        if (u != null) users.add(u);
      }
      if (mounted) setState(() { _contacts = users; _loading = false; });
    } catch (e) {
      debugPrint('Kontakty: zapisani: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
    });
    _load();
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
    try {
      await context
          .read<FirebaseService>()
          .removeContact(myUserId: myUid, contactUserId: user.id);
    } catch (e) {
      debugPrint('Kontakty: usuwanie: $e');
      showToast(text: 'Nie udało się usunąć z kontaktów');
      return;
    }
    if (mounted) {
      setState(() =>
          _contacts = _contacts.where((c) => c.id != user.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return LoadError(message: 'Nie udało się wczytać zapisanych', onRetry: _retry);
    }

    final shown = _contacts
        .where((u) => _filter == null || (u.firma == true) == _filter)
        .toList();

    Widget chips() => Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
          child: Row(
            children: [
              for (final f in <(bool?, String)>[
                (null, 'Wszyscy'),
                (true, 'Firmy'),
                (false, 'Ludzie'),
              ]) ...[
                ChoiceChip(
                  label: Text(f.$2, style: const TextStyle(fontSize: 12)),
                  selected: _filter == f.$1,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _filter = f.$1),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        );

    if (shown.isEmpty) {
      return Column(
        children: [
          chips(),
          Expanded(
            child: EmptyState(
              icon: Icons.bookmark_outline,
              title: 'Nikogo nie zapisano',
              subtitle: 'Zapisuj firmy i osoby przyciskiem „Zapisz” w Aktywności '
                  'albo ikoną +osoba na filmie. Zapisani zostają tu na stałe.',
            ),
          ),
        ],
      );
    }
    // rozmowy tylko dopisują licznik nieprzeczytanych — ich błąd nie zasłania listy
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chats,
      builder: (context, chatSnap) {
        final chats = chatSnap.data ?? [];
        return Column(
          children: [
            chips(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: shown.length,
                itemBuilder: (context, i) {
                  final user = shown[i];
                  final chat = chats.firstWhere(
                    (c) => c['from'] == user.id,
                    orElse: () => {},
                  );
                  return _ContactCard(
                    user: user,
                    lastMessage: chat['lastMessage'] as String? ?? '',
                    timestamp: chat['timestamp'] as int? ?? 0,
                    unreadCount: chat['unreadCount'] as int? ?? 0,
                    onRemove: () => _removeContact(user),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Zielona kropka: online i ślad obecności młodszy niż 5 min (jak w Cloud Functions).
class _OnlineDot extends StatefulWidget {
  final String userId;
  const _OnlineDot(this.userId, {super.key});

  @override
  State<_OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<_OnlineDot> {
  late final Stream<Map<String, dynamic>?> _status;

  @override
  void initState() {
    super.initState();
    _status = context.read<ChatService>().getUserStatus(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _status,
      builder: (context, snap) {
        final seen = snap.data?['last_seen'];
        final online = snap.data?['online'] == true &&
            seen is num &&
            DateTime.now().millisecondsSinceEpoch - seen < 5 * 60 * 1000;
        if (!online) return const SizedBox.shrink();
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
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
  final String lastMessage;
  final int timestamp;
  final int unreadCount;
  final VoidCallback? onRemove;

  const _ContactCard({
    required this.user,
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
            Positioned(right: 0, bottom: 0, child: _OnlineDot(user.id, key: ValueKey(user.id))),
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

// ─────────────────────────────────────────────────────────────────────────────
// Klienci firmy / moje firmy — relacje po domkniętych zleceniach
// ─────────────────────────────────────────────────────────────────────────────
