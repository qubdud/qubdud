import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../../../bloc/main_bloc.dart';
import '../../profil_publiczny/view/profil_publiczny_page.dart';

class ProfilPublicznyUseraPage extends StatefulWidget {
  final String userId;
  const ProfilPublicznyUseraPage({super.key, required this.userId});

  @override
  State<ProfilPublicznyUseraPage> createState() => _ProfilPublicznyUseraPageState();
}

class _ProfilPublicznyUseraPageState extends State<ProfilPublicznyUseraPage> {
  bool _loading = true;
  AppUser? _user;
  List<Review> _reviews = [];
  final Map<String, String> _companyNames = {};
  int _requestCount = 0;
  int _contactCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebase = context.read<FirebaseService>();
    try {
      final user = await firebase.fetchUser(widget.userId);
      final reviews = await firebase.getReviewByUser(widget.userId);
      final requests = await firebase.getRequestsMetadataByUser(widget.userId);
      // cudza lista kontaktów jest prywatna (reguły) — wtedy pokazujemy 0
      List<String> contacts = const [];
      try {
        contacts = await firebase.getContactIds(widget.userId);
      } catch (_) {}
      for (final id in reviews.map((r) => r.reviewedUserId).toSet()) {
        if (id.isEmpty) continue;
        final c = await firebase.fetchUser(id);
        if (c != null) _companyNames[id] = c.companyName ?? c.displayName;
      }

      if (mounted) {
        setState(() {
          _user = user;
          _reviews = reviews;
          _requestCount = requests.length;
          _contactCount = contacts.length;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final user = _user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Nie znaleziono użytkownika')));
    }

    final initials = ((user.firstName?.isNotEmpty == true ? user.firstName![0] : '') +
        (user.lastName?.isNotEmpty == true ? user.lastName![0] : ''))
        .toUpperCase();

    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Nagłówek ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black87,
                    child: Text(
                      initials.isEmpty ? '?' : initials,
                      style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
                              ? 'Brak'
                              : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Notatka o kliencie (tylko firma)
                      if (isCompanyMode(
                          context.read<MainScreenBloc>().state.user))
                        IconButton(
                          icon: Icon(
                              ClientNotes.get(widget.userId).isEmpty
                                  ? Icons.sticky_note_2_outlined
                                  : Icons.sticky_note_2,
                              size: 22,
                              color: ClientNotes.get(widget.userId).isEmpty
                                  ? Colors.grey
                                  : const Color(0xFFB8901B)),
                          tooltip: 'Notatka',
                          onPressed: () async {
                            final changed = await showClientNoteDialog(
                                context,
                                widget.userId,
                                '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                    .trim());
                            if (changed && mounted) setState(() {});
                          },
                        ),
                    ],
                  ),
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                    ),
                  ],
                  // Karteczka z notatką (widzi tylko firma)
                  ClientNoteBadge(
                    userId: widget.userId,
                    personName:
                        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                    maxLines: 3,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── Przyciski akcji ──────────────────────────
                  if (myUid != widget.userId)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Napisz wiadomość
                        _ActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Napisz',
                          onTap: () => context.read<MainScreenBloc>().add(
                              GoToChatEvent(widget.userId,
                                  chatName:
                                      '${user.firstName ?? ''} ${user.lastName ?? ''}'
                                          .trim())),
                        ),

                        const SizedBox(width: 12),
                        // Dodaj do kontaktów
                        _ActionButton(
                          icon: Icons.person_add_outlined,
                          label: 'Kontakt',
                          onTap: () async {
                            final firebase = context.read<FirebaseService>();
                            await firebase.addContact(
                              myUserId: myUid,
                              contactUserId: widget.userId,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Dodano do kontaktów')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ── Statystyki ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aktywność',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatTile(
                        icon: Icons.report_problem_outlined,
                        value: '$_requestCount',
                        label: 'Zgłoszenia',
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        icon: Icons.star_outline,
                        value: '${_reviews.length}',
                        label: 'Recenzje',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 12),
                      _StatTile(
                        icon: Icons.people_outline,
                        value: '$_contactCount',
                        label: 'Kontakty',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Wystawione recenzje ────────────────────────────
            if (_reviews.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wystawione recenzje',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._reviews.map((r) => ReviewCard(
                        review: r,
                        subjectName: _companyNames[r.reviewedUserId] ?? 'Firma')),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  const _ReviewItem({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                i < review.score ? Icons.star : Icons.star_border,
                color: Colors.amber, size: 16,
              )),
              const Spacer(),
              if (review.timestamp != null)
                Text(
                  '${review.timestamp!.day}.${review.timestamp!.month}.${review.timestamp!.year}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          if (review.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.description,
                style: const TextStyle(fontSize: 13), maxLines: 3, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}