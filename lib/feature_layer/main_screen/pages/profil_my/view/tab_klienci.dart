import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../bloc/main_bloc.dart';

/// Klienci firmy: osoby po rezerwacji terminu, po domkniętym zleceniu
/// oraz każdy, kogo firma oznaczyła prywatną notatką.
class TabKlienci extends StatelessWidget {
  final String companyId;
  const TabKlienci({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return _PeopleList(
      loader: () async {
        final firebase = context.read<FirebaseService>();
        final clients = await firebase.getClients(companyId);
        await ClientNotes.load(firebase, companyId);
        final ids = clients.map((c) => c.id).toSet();
        for (final id in ClientNotes.all.keys) {
          if (ids.contains(id)) continue;
          final u = await firebase.fetchUser(id);
          if (u != null) clients.add(u);
        }
        return clients;
      },
      emptyIcon: Icons.people_outline,
      emptyTitle: 'Brak klientów',
      emptyText:
          'Klient pojawi się tu, gdy zarezerwuje termin w Twoim kalendarzu, '
          'gdy zrealizujesz jego zgłoszenie lub gdy dodasz mu notatkę.',
      isCompanyList: false,
      showNotes: true,
    );
  }
}

/// Firmy, z którymi użytkownik ma relację: rezerwacja lub zrealizowane zlecenie.
class TabMojeFirmy extends StatelessWidget {
  final String userId;
  const TabMojeFirmy({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _PeopleList(
      loader: () => context.read<FirebaseService>().getMyCompanies(userId),
      emptyIcon: Icons.business_outlined,
      emptyTitle: 'Brak firm',
      emptyText:
          'Firma pojawi się tu, gdy zarezerwujesz u niej termin '
          'lub gdy zrealizuje Twoje zgłoszenie.',
      isCompanyList: true,
    );
  }
}

class _PeopleList extends StatefulWidget {
  final Future<List<AppUser>> Function() loader;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyText;
  final bool isCompanyList;
  final bool showNotes;

  const _PeopleList({
    required this.loader,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyText,
    required this.isCompanyList,
    this.showNotes = false,
  });

  @override
  State<_PeopleList> createState() => _PeopleListState();
}

class _PeopleListState extends State<_PeopleList> {
  List<AppUser> _people = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.loader();
      if (mounted) setState(() { _people = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nameOf(AppUser p) => p.firma == true
      ? (p.companyName ?? 'Firma')
      : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_people.isEmpty) {
      return EmptyState(
        icon: widget.emptyIcon,
        title: widget.emptyTitle,
        subtitle: widget.emptyText,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _people.length,
      itemBuilder: (context, i) {
        final p = _people[i];
        final isCompany = p.firma == true;
        final name = _nameOf(p);
        final hasNote = widget.showNotes && ClientNotes.get(p.id).isNotEmpty;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () {
              if (isCompany) {
                context
                    .read<MainScreenBloc>()
                    .add(GoToProfilPublicznyFirmyEvent(p.id));
              } else {
                context
                    .read<MainScreenBloc>()
                    .add(GoToProfilPublicznyUseraEvent(p.id));
              }
            },
            leading: CircleAvatar(
              backgroundColor:
                  isCompany ? Colors.blue.shade700 : Colors.grey.shade600,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompany)
                  Text(
                      [p.companyCategory, p.companyCity]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: const TextStyle(fontSize: 12))
                else if (p.phone?.isNotEmpty == true)
                  Text(p.phone!, style: const TextStyle(fontSize: 12)),
                if (widget.showNotes)
                  ClientNoteBadge(
                    userId: p.id,
                    personName: name,
                    maxLines: 2,
                    onChanged: () => setState(() {}),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showNotes)
                  IconButton(
                    icon: Icon(
                        hasNote
                            ? Icons.sticky_note_2
                            : Icons.sticky_note_2_outlined,
                        size: 20,
                        color: hasNote ? const Color(0xFFB8901B) : null),
                    tooltip: 'Notatka',
                    onPressed: () async {
                      final changed =
                          await showClientNoteDialog(context, p.id, name);
                      if (changed) _load();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  tooltip: 'Napisz',
                  onPressed: () => context
                      .read<MainScreenBloc>()
                      .add(GoToChatEvent(p.id, chatName: name)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
