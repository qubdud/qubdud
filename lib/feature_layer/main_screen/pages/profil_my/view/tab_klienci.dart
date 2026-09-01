import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../bloc/main_bloc.dart';

/// Lista klientów firmy (relacja powstaje po obustronnym potwierdzeniu zadania).
class TabKlienci extends StatelessWidget {
  final String companyId;
  const TabKlienci({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    return _PeopleList(
      loader: () => context.read<FirebaseService>().getClients(companyId),
      emptyIcon: Icons.people_outline,
      emptyText:
          'Brak klientów.\nKlient pojawi się tu po obustronnym potwierdzeniu zadania.',
      isCompanyList: false,
    );
  }
}

/// Lista firm, z których usług korzystał użytkownik.
class TabMojeFirmy extends StatelessWidget {
  final String userId;
  const TabMojeFirmy({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return _PeopleList(
      loader: () => context.read<FirebaseService>().getMyCompanies(userId),
      emptyIcon: Icons.business_outlined,
      emptyText:
          'Brak firm.\nFirma pojawi się tu po obustronnym potwierdzeniu zadania.',
      isCompanyList: true,
    );
  }
}

class _PeopleList extends StatefulWidget {
  final Future<List<AppUser>> Function() loader;
  final IconData emptyIcon;
  final String emptyText;
  final bool isCompanyList;

  const _PeopleList({
    required this.loader,
    required this.emptyIcon,
    required this.emptyText,
    required this.isCompanyList,
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
    widget.loader().then((list) {
      if (mounted) setState(() { _people = list; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.emptyIcon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(widget.emptyText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _people.length,
      itemBuilder: (context, i) {
        final p = _people[i];
        final isCompany = p.firma == true;
        final name = isCompany
            ? (p.companyName ?? 'Firma')
            : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: isCompany
                ? Text(
                    [p.companyCategory, p.companyCity]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: const TextStyle(fontSize: 12))
                : (p.phone?.isNotEmpty == true
                    ? Text(p.phone!, style: const TextStyle(fontSize: 12))
                    : null),
            trailing: IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              tooltip: 'Napisz',
              onPressed: () =>
                  context.read<MainScreenBloc>().add(GoToChatEvent(p.id, chatName: p.firma == true ? p.companyName : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim())),
            ),
          ),
        );
      },
    );
  }
}
