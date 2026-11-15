import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/domain_models/relation_link.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../bloc/main_bloc.dart';
import '../../profil_my/view/tab_kalendarz.dart' show dayLabel;
import '../functions/format_timestamp.dart';
import '../../../../../shared/widgets/load_error.dart';

/// Kontakty → Aktywność: jeden feed wszystkiego, co dzieje się z ludźmi
/// i firmami — wiadomości, rezerwacje, zgłoszenia, prośby o telefon.
/// Na górze to, co czeka na Twoją reakcję, niżej historia od najnowszej.
enum ActivityKind { chat, contact, slot, request }

class ActivityItem {
  final String personId;
  final String name;
  final bool isCompany;
  final DateTime at;
  final ActivityKind kind;
  final String text;
  final IconData icon;
  final Color color;
  final bool needsAction;
  final int unread;
  final String? phone;
  final ContactRef? contact;
  final Request? request;

  const ActivityItem({
    required this.personId,
    required this.name,
    required this.isCompany,
    required this.at,
    required this.kind,
    required this.text,
    required this.icon,
    required this.color,
    this.needsAction = false,
    this.unread = 0,
    this.phone,
    this.contact,
    this.request,
  });
}

class TabActivity extends StatefulWidget {
  const TabActivity({super.key});

  @override
  State<TabActivity> createState() => _TabActivityState();
}

class _TabActivityState extends State<TabActivity> {
  List<ActivityItem> _relItems = [];
  Set<String> _saved = {};
  bool _loading = true;
  bool _failed = false;
  String _filter = 'all';
  late final bool _companyMode;
  late Stream<List<Map<String, dynamic>>> _chats;

  String get _myUid => context.read<MainScreenBloc>().state.user?.id ?? '';

  @override
  void initState() {
    super.initState();
    _companyMode = isCompanyMode(context.read<MainScreenBloc>().state.user);
    _chats = context.read<ChatService>().getChatOverviews();
    _load();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _failed = false;
      _chats = context.read<ChatService>().getChatOverviews();
    });
    _load();
  }

  static String _short(String s) =>
      s.characters.length > 40 ? '${s.characters.take(40).toString().trimRight()}…' : s;

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    final fb = context.read<FirebaseService>();
    try {
      final links = _companyMode
          ? await fb.getClientLinks(_myUid)
          : await fb.getMyCompanyLinks(_myUid);
      final ids = await fb.getContactIds(_myUid);
      final items = <ActivityItem>[];

      for (final l in links) {
        final u = l.user;
        final isCompany = u.firma == true;
        final name = isCompany
            ? (u.companyName ?? 'Firma')
            : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
        // firma widzi telefon klienta; klient — telefon firmy, o ile go pokazuje
        final phone = (!isCompany || u.showPhone != false) ? (u.phone ?? '') : '';

        for (final s in l.slots) {
          final (color, suffix) = s.status == 'accepted'
              ? (Colors.green.shade700, 'przyjęta')
              : (Colors.amber.shade800, 'czeka na akceptację');
          items.add(ActivityItem(
            personId: u.id,
            name: name,
            isCompany: isCompany,
            at: s.start,
            kind: ActivityKind.slot,
            text: 'Rezerwacja · ${dayLabel(s.start)}, ${_hhmm(s.start)} · $suffix',
            icon: Icons.event_available_outlined,
            color: color,
            needsAction: _companyMode && s.status == 'pending',
            phone: phone,
          ));
        }

        for (final r in l.requests) {
          final desc = _short(r.description.isNotEmpty ? r.description : r.sector);
          final stage = r.stage;
          final color = switch (stage) {
            RequestStage.realized => Colors.green.shade700,
            RequestStage.photosPending => Colors.amber.shade800,
            RequestStage.photosRejected => Colors.red.shade600,
            RequestStage.expired || RequestStage.closed => Colors.grey.shade600,
            _ => Colors.blue.shade700,
          };
          final suffix = stage.label(forCompany: _companyMode);
          final action = !_companyMode && stage == RequestStage.photosPending;
          items.add(ActivityItem(
            personId: u.id,
            name: name,
            isCompany: isCompany,
            at: r.timestamp ?? DateTime(2000),
            kind: ActivityKind.request,
            text: 'Zgłoszenie · $desc · $suffix',
            icon: Icons.build_outlined,
            color: color,
            needsAction: action,
            phone: phone,
            request: r,
          ));
        }

        final c = l.contact;
        if (c != null) {
          final done = c.status == 'done';
          items.add(ActivityItem(
            personId: u.id,
            name: name,
            isCompany: isCompany,
            at: c.createdAt ?? DateTime.now(),
            kind: ActivityKind.contact,
            text: 'Prośba o telefon · ${c.phone} · ${done ? 'załatwione' : 'czeka'}',
            icon: Icons.phone_callback_outlined,
            color: done ? Colors.green.shade700 : Colors.amber.shade800,
            needsAction: _companyMode && !done,
            phone: _companyMode ? c.phone : phone,
            contact: c,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _relItems = items;
          _saved = ids.toSet();
          _loading = false;
          _failed = false;
        });
      }
    } catch (e) {
      debugPrint('Aktywność: wczytywanie: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  // ── akcje ────────────────────────────────────────────────────────────────

  void _openProfile(ActivityItem it) {
    context.read<MainScreenBloc>().add(it.isCompany
        ? GoToProfilPublicznyFirmyEvent(it.personId)
        : GoToProfilPublicznyUseraEvent(it.personId));
  }

  void _openChat(ActivityItem it) {
    context.read<MainScreenBloc>().add(GoToChatEvent(it.personId, chatName: it.name));
  }

  Future<void> _call(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')));
  }

  Future<void> _toggleSave(ActivityItem it) async {
    final fb = context.read<FirebaseService>();
    final saved = _saved.contains(it.personId);
    try {
      if (saved) {
        await fb.removeContact(myUserId: _myUid, contactUserId: it.personId);
      } else {
        await fb.addContact(myUserId: _myUid, contactUserId: it.personId);
      }
    } catch (e) {
      debugPrint('Aktywność: zapisani: $e');
      showToast(text: 'Nie udało się zapisać zmiany');
      return;
    }
    if (!mounted) return;
    setState(() {
      if (saved) {
        _saved.remove(it.personId);
      } else {
        _saved.add(it.personId);
      }
    });
    showToast(
        text: saved
            ? 'Usunięto z Zapisanych'
            : '${it.name} — zapisano w Kontakty → Zapisani');
  }

  /// Firma: zadzwoń pod numer z prośby albo oznacz, że już się odezwała.
  Future<void> _contactActions(ActivityItem it) async {
    final c = it.contact!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.note.isNotEmpty)
              ListTile(leading: const Icon(Icons.notes_outlined), title: Text(c.note)),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text('Zadzwoń: ${c.phone}'),
              onTap: () => Navigator.pop(ctx, 'call'),
            ),
            if (c.status != 'done')
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Oznacz: skontaktowałem się'),
                onTap: () => Navigator.pop(ctx, 'done'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'call') {
      await _call(c.phone);
      return;
    }
    try {
      await context.read<FirebaseService>().setContactRequestDone(c.id);
    } catch (e) {
      debugPrint('Aktywność: prośba o telefon: $e');
      showToast(text: 'Nie udało się oznaczyć prośby');
      return;
    }
    _load();
  }

  void _open(ActivityItem it) {
    switch (it.kind) {
      case ActivityKind.chat:
        _openChat(it);
      case ActivityKind.slot:
        // firma: Start → Kalendarz; klient: Start → Rezerwacje
        Globals.instance.startTab = 1;
        context.read<MainScreenBloc>().add(GoToHomeEvent());
      case ActivityKind.request:
        Globals.instance.selectedRequest = it.request;
        context.read<MainScreenBloc>().add(GoToShowRequestEvent());
      case ActivityKind.contact:
        if (_companyMode) {
          _contactActions(it);
        } else {
          _openProfile(it);
        }
    }
  }

  // ── widok ────────────────────────────────────────────────────────────────

  bool _matches(ActivityItem it) => switch (_filter) {
        'todo' => it.needsAction,
        'chat' => it.kind == ActivityKind.chat,
        'slot' => it.kind == ActivityKind.slot,
        'request' => it.kind == ActivityKind.request,
        'contact' => it.kind == ActivityKind.contact,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return LoadError(message: 'Nie udało się wczytać aktywności', onRetry: _retry);
    }
    final chatService = context.read<ChatService>();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chats,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('Aktywność: rozmowy: ${snap.error}');
          return LoadError(message: 'Nie udało się wczytać rozmów', onRetry: _retry);
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final chats = snap.data!;
        final chatItems = chats.map((c) {
          final unread = c['unreadCount'] as int? ?? 0;
          final last = c['lastMessage'] as String? ?? '';
          return ActivityItem(
            personId: c['from'] as String,
            name: (c['name'] as String?)?.isNotEmpty == true
                ? c['name'] as String
                : 'Rozmowa',
            isCompany: c['isCompany'] == true,
            at: DateTime.fromMillisecondsSinceEpoch(c['timestamp'] as int? ?? 0),
            kind: ActivityKind.chat,
            text: last.isNotEmpty ? last : 'Rozmowa',
            icon: Icons.chat_bubble_outline,
            color: unread > 0 ? Colors.pink.shade600 : Colors.blueGrey.shade600,
            needsAction: unread > 0,
            unread: unread,
          );
        });

        final all = [...chatItems, ..._relItems].where(_matches).toList()
          ..sort((a, b) => b.at.compareTo(a.at));
        final todo = all.where((i) => i.needsAction).toList();
        final rest = all.where((i) => !i.needsAction).toList();
        final todoCount = [...chatItems, ..._relItems].where((i) => i.needsAction).length;

        final filters = <(String, String)>[
          ('all', 'Wszystko'),
          ('todo', todoCount > 0 ? 'Do zrobienia · $todoCount' : 'Do zrobienia'),
          ('chat', 'Rozmowy'),
          ('slot', 'Rezerwacje'),
          ('request', 'Zgłoszenia'),
          ('contact', 'Telefony'),
        ];

        return Column(
          children: [
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                children: [
                  for (final f in filters) ...[
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
            ),
            Expanded(
              child: all.isEmpty
                  ? EmptyState(
                      icon: Icons.bolt_outlined,
                      title: _filter == 'all'
                          ? 'Jeszcze nic się nie dzieje'
                          : 'Nic w tej kategorii',
                      subtitle: 'Tu zobaczysz wiadomości, rezerwacje, zgłoszenia '
                          'i prośby o telefon — wszystko w jednym miejscu.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                        children: [
                          if (todo.isNotEmpty) ...[
                            _SectionLabel('Do zrobienia', Colors.pink.shade600),
                            for (final it in todo) _card(it, chatService),
                            if (rest.isNotEmpty) _SectionLabel('Ostatnio', Colors.grey.shade600),
                          ],
                          for (final it in rest) _card(it, chatService),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(ActivityItem it, ChatService chatService) {
    final card = _ActivityCard(
      item: it,
      companyMode: _companyMode,
      saved: _saved.contains(it.personId),
      onOpen: () => _open(it),
      onProfile: () => _openProfile(it),
      onChat: () => _openChat(it),
      onCall: it.phone?.isNotEmpty == true ? () => _call(it.phone!) : null,
      onSave: () => _toggleSave(it),
      onNoteChanged: () => setState(() {}),
    );
    if (it.kind != ActivityKind.chat) return card;
    // rozmowę można schować do kosza: przytrzymaj kartę
    return GestureDetector(
      onLongPress: () => _confirmTrash(it, chatService),
      child: card,
    );
  }

  Future<void> _confirmTrash(ActivityItem it, ChatService chatService) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Przenieść rozmowę do kosza?'),
        content: Text(it.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zostaw')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Do kosza',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    // offline zapis czeka w kolejce, a lista chowa rozmowę od razu
    chatService.hideChat(it.personId).catchError((Object e) {
      debugPrint('Aktywność: kosz: $e');
      showToast(text: 'Nie udało się przenieść rozmowy do kosza');
    });
    showToast(text: 'Rozmowa przeniesiona do kosza');
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: color)),
      );
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final bool companyMode;
  final bool saved;
  final VoidCallback onOpen;
  final VoidCallback onProfile;
  final VoidCallback onChat;
  final VoidCallback? onCall;
  final VoidCallback onSave;
  final VoidCallback onNoteChanged;

  const _ActivityCard({
    required this.item,
    required this.companyMode,
    required this.saved,
    required this.onOpen,
    required this.onProfile,
    required this.onChat,
    required this.onCall,
    required this.onSave,
    required this.onNoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final it = item;
    final hasNote = companyMode && ClientNotes.get(it.personId).isNotEmpty;
    final ms = it.at.millisecondsSinceEpoch;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                  color: it.needsAction ? it.color : Colors.transparent,
                  width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onProfile,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: it.isCompany
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                      child: Text(
                        it.name.isNotEmpty ? it.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(it.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: it.needsAction
                                          ? FontWeight.w800
                                          : FontWeight.w600)),
                            ),
                            if (ms > 0)
                              Text(formatTimestamp(ms),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(it.icon, size: 14, color: it.color),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(it.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: it.color,
                                      fontWeight: it.needsAction
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
                            ),
                            if (it.unread > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.pinkAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('${it.unread}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        if (companyMode)
                          ClientNoteBadge(userId: it.personId, personName: it.name),
                      ],
                    ),
                  ),
                ],
              ),
              // pasek akcji: notatka (firma), napisz, zadzwoń, zapisz na stałe
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Row(
                  children: [
                    if (companyMode)
                      _MiniAction(
                        icon: hasNote
                            ? Icons.sticky_note_2
                            : Icons.sticky_note_2_outlined,
                        color: hasNote ? const Color(0xFFB8901B) : null,
                        tooltip: 'Notatka',
                        onTap: () async {
                          final changed = await showClientNoteDialog(
                              context, it.personId, it.name);
                          if (changed) onNoteChanged();
                        },
                      ),
                    _MiniAction(
                        icon: Icons.chat_bubble_outline,
                        tooltip: 'Napisz',
                        onTap: onChat),
                    if (onCall != null)
                      _MiniAction(
                          icon: Icons.phone_outlined,
                          tooltip: 'Zadzwoń',
                          onTap: onCall!),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onSave,
                      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                          size: 18),
                      label: Text(saved ? 'Zapisany' : 'Zapisz',
                          style: const TextStyle(fontSize: 12.5)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor:
                            saved ? Colors.blue.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;
  const _MiniAction(
      {required this.icon, required this.tooltip, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, size: 20, color: color),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
      );
}
