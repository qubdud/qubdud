import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/domain_models/relation_link.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../bloc/main_bloc.dart';
import 'tab_kalendarz.dart' show dayLabel;

/// Klienci firmy: osoby po rezerwacji terminu, po zgłoszeniu z ofertą
/// oraz każdy, kogo firma oznaczyła prywatną notatką.
class TabKlienci extends StatelessWidget {
  final String companyId;
  const TabKlienci({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return _RelationList(
      loader: () async {
        final firebase = context.read<FirebaseService>();
        final links = await firebase.getClientLinks(companyId);
        await ClientNotes.load(firebase, companyId);
        final ids = links.map((l) => l.user.id).toSet();
        for (final id in ClientNotes.all.keys) {
          if (ids.contains(id)) continue;
          final u = await firebase.fetchUser(id);
          if (u != null) links.add(RelationLink(user: u));
        }
        return links;
      },
      emptyIcon: Icons.people_outline,
      emptyTitle: 'Brak klientów',
      emptyText:
          'Klient pojawi się tu, gdy zarezerwuje termin w Twoim kalendarzu, '
          'gdy odpowiesz na jego zgłoszenie lub gdy dodasz mu notatkę.',
      companyView: true,
    );
  }
}

/// Firmy, z którymi użytkownik ma relację: rezerwacja lub zgłoszenie.
class TabMojeFirmy extends StatelessWidget {
  final String userId;
  const TabMojeFirmy({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _RelationList(
      loader: () => context.read<FirebaseService>().getMyCompanyLinks(userId),
      emptyIcon: Icons.business_outlined,
      emptyTitle: 'Brak firm',
      emptyText:
          'Firma pojawi się tu, gdy zarezerwujesz u niej termin '
          'lub gdy odpowie na Twoje zgłoszenie.',
      companyView: false,
    );
  }
}

class _RelationList extends StatefulWidget {
  final Future<List<RelationLink>> Function() loader;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyText;

  /// true = lista klientów oglądana przez firmę (notatki, profil usera);
  /// false = lista firm oglądana przez użytkownika.
  final bool companyView;

  const _RelationList({
    required this.loader,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyText,
    required this.companyView,
  });

  @override
  State<_RelationList> createState() => _RelationListState();
}

class _RelationListState extends State<_RelationList> {
  List<RelationLink> _links = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.loader();
      if (mounted) setState(() { _links = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nameOf(RelationLink l) => l.user.firma == true
      ? (l.user.companyName ?? 'Firma')
      : '${l.user.firstName ?? ''} ${l.user.lastName ?? ''}'.trim();

  void _openRequest(Request r) {
    Globals.instance.selectedRequest = r;
    context.read<MainScreenBloc>().add(GoToShowRequestEvent());
  }

  void _openBookings() {
    // firma: Start → Kalendarz (index 1); użytkownik: Start → Rezerwacje (index 1)
    Globals.instance.startTab = 1;
    context.read<MainScreenBloc>().add(GoToHomeEvent());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_links.isEmpty) {
      return EmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyTitle,
        subtitle: widget.emptyText,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _links.length,
      itemBuilder: (context, i) {
        final l = _links[i];
        final u = l.user;
        final isCompany = u.firma == true;
        final name = _nameOf(l);
        final hasNote =
            widget.companyView && ClientNotes.get(u.id).isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── nagłówek: avatar, nazwa, akcje ──
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(u.id, isCompany),
                      child: CircleAvatar(
                        backgroundColor: isCompany
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openProfile(u.id, isCompany),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            if (isCompany)
                              Text(
                                  [u.companyCategory, u.companyCity]
                                      .whereType<String>()
                                      .where((s) => s.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey))
                            else if (u.phone?.isNotEmpty == true)
                              Text(u.phone!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    if (widget.companyView)
                      IconButton(
                        icon: Icon(
                            hasNote
                                ? Icons.sticky_note_2
                                : Icons.sticky_note_2_outlined,
                            size: 20,
                            color:
                                hasNote ? const Color(0xFFB8901B) : null),
                        tooltip: 'Notatka',
                        visualDensity: VisualDensity.compact,
                        onPressed: () async {
                          final changed =
                              await showClientNoteDialog(context, u.id, name);
                          if (changed) setState(() {});
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      tooltip: 'Napisz',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context
                          .read<MainScreenBloc>()
                          .add(GoToChatEvent(u.id, chatName: name)),
                    ),
                  ],
                ),

                if (widget.companyView)
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: ClientNoteBadge(
                      userId: u.id,
                      personName: name,
                      maxLines: 2,
                      onChanged: () => setState(() {}),
                    ),
                  ),

                // ── skąd ta relacja: chipy z odnośnikami ──
                Padding(
                  padding: const EdgeInsets.only(left: 52, top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final s in l.slots) _SourceChip(
                        icon: Icons.event_available_outlined,
                        color: _slotColor(s.status),
                        text: 'Rezerwacja · ${dayLabel(s.start)}, '
                            '${s.start.hour.toString().padLeft(2, '0')}:'
                            '${s.start.minute.toString().padLeft(2, '0')}'
                            '${_slotSuffix(s.status)}',
                        onTap: _openBookings,
                      ),
                      for (final r in l.requests) _SourceChip(
                        icon: Icons.build_outlined,
                        color: Colors.blue.shade700,
                        text: 'Zgłoszenie · ${_short(r.description.isNotEmpty ? r.description : r.sector)}',
                        onTap: () => _openRequest(r),
                      ),
                      if (l.contact != null)
                        _SourceChip(
                          icon: Icons.phone_callback_outlined,
                          color: l.contact!.status == 'done'
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                          text: 'Prośba o telefon · ${l.contact!.phone}'
                              '${l.contact!.status == 'done' ? ' · załatwione' : ' · czeka'}',
                          onTap: widget.companyView
                              ? () => _contactActions(l.contact!)
                              : null,
                        ),
                      if (l.isManual)
                        _SourceChip(
                          icon: Icons.sticky_note_2_outlined,
                          color: const Color(0xFFB8901B),
                          text: widget.companyView
                              ? 'Dodany przez notatkę'
                              : 'Kontakt ręczny',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Firma: zadzwoń pod numer z prośby albo oznacz, że już się odezwała.
  Future<void> _contactActions(ContactRef c) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.note.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: Text(c.note),
              ),
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
      await launchUrl(Uri(scheme: 'tel', path: c.phone.replaceAll(RegExp(r'[^0-9+]'), '')));
    } else {
      await context.read<FirebaseService>().setContactRequestDone(c.id);
      setState(() => c.status = 'done');
    }
  }

  void _openProfile(String id, bool isCompany) {
    context.read<MainScreenBloc>().add(isCompany
        ? GoToProfilPublicznyFirmyEvent(id)
        : GoToProfilPublicznyUseraEvent(id));
  }

  static String _short(String s) =>
      s.length > 32 ? '${s.substring(0, 32).trimRight()}…' : s;

  static Color _slotColor(String status) => switch (status) {
        'accepted' => Colors.green.shade700,
        'rejected' => Colors.red.shade600,
        _ => Colors.amber.shade800,
      };

  static String _slotSuffix(String status) => switch (status) {
        'accepted' => ' · przyjęta',
        'rejected' => ' · odrzucona',
        _ => ' · czeka',
      };
}

/// Mały chip „skąd ta osoba": ikona + tekst, opcjonalnie klikalny.
class _SourceChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  const _SourceChip({
    required this.icon,
    required this.color,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: color)),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 13, color: color),
            ],
          ],
        ),
      ),
    );
  }
}
