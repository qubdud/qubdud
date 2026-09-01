import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';

class MoiKlienciTab extends StatelessWidget {
  final StartPageState state;
  const MoiKlienciTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return _RequestList(requests: state.requests, isTrash: false);
  }
}

class _RequestList extends StatelessWidget {
  final List<Request> requests;
  final bool isTrash;

  const _RequestList({required this.requests, required this.isTrash});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: isTrash ? Icons.delete_outline : Icons.inbox_outlined,
        title: isTrash ? 'Kosz jest pusty' : 'Brak zgłoszeń',
        subtitle: isTrash
            ? null
            : 'Tu pojawią się zgłoszenia z Twojej kategorii i okolicy.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, index) => _RequestCard(
        request: requests[index],
        isTrash: isTrash,
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Request request;
  final bool isTrash;

  const _RequestCard({required this.request, required this.isTrash});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Globals.instance.selectedRequest = request;
          context.read<MainScreenBloc>().add(GoToShowRequestEvent());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _takeStatusBadge(context),
              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Miniatura ───────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: request.thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: request.thumbUrl,
                      width: 80,
                      height: 130,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 80,
                      height: 130,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  if (request.is24)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('24h',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Treść ───────────────────────────────────────
              Expanded(
                child: SizedBox(
                  height: 136,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imię zgłaszającego + dystans
                      Row(
                        children: [
                          Expanded(
                            child: _RequesterName(userId: request.userId),
                          ),
                          if (request.distance != null)
                            Text(
                              '${(request.distance! / 1000).toStringAsFixed(1)} km',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                      if (request.city.isNotEmpty)
                        Text(request.city,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (request.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.description,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const Spacer(),

                      // ── Pasek akcji ─────────────────────────
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: isTrash
                              ? [
                            // Kosz: tylko przywróć
                            _IconAction(
                              icon: Icons.restore_from_trash_outlined,
                              tooltip: 'Przywróć',
                              color: Colors.green,
                              onTap: () => context.read<StartPageBloc>().add(
                                TryRestoreRequestEvent(request.id),
                              ),
                            ),
                          ]
                              : [
                            // Napisz wiadomość
                            _IconAction(
                              icon: Icons.chat_bubble_outline,
                              tooltip: 'Napisz',
                              onTap: () => context.read<MainScreenBloc>().add(
                                GoToChatEvent(request.userId, chatName: _requesterNameCache[request.userId]),
                              ),
                            ),
                            // Dodaj do kontaktów
                            _IconAction(
                              icon: Icons.person_add_outlined,
                              tooltip: 'Dodaj do kontaktów',
                              onTap: () => context.read<StartPageBloc>().add(
                                TryAddContactStartPageEvent(request.userId),
                              ),
                            ),
                            // Profil usera
                            _IconAction(
                              icon: Icons.account_circle_outlined,
                              tooltip: 'Profil',
                              onTap: () => context.read<MainScreenBloc>().add(
                                GoToProfilPublicznyUseraEvent(request.userId),
                              ),
                            ),
                            // Ukryj → kosz
                            _IconAction(
                              icon: Icons.visibility_off_outlined,
                              tooltip: 'Ukryj',
                              color: Colors.red.shade300,
                              onTap: () => context.read<StartPageBloc>().add(
                                TryHideRequestEvent(request.id),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _takeStatusBadge(BuildContext context) {
    if (request.takenBy.isEmpty) return const SizedBox.shrink();
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    final mine = request.takenBy == myId;

    late final Color color;
    late final String text;
    if (mine && request.status == 'taken') {
      color = Colors.green;
      text = 'W realizacji przez Ciebie';
    } else if (mine) {
      color = Colors.orange;
      text = 'Podjęte przez Ciebie — czeka na potwierdzenie klienta';
    } else {
      color = Colors.grey;
      text = 'Podjęte przez: ${request.takenByName}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

// Imię i nazwisko zgłaszającego (cache w pamięci — bez mielenia Firestore)
final Map<String, String> _requesterNameCache = {};

class _RequesterName extends StatelessWidget {
  final String userId;
  const _RequesterName({required this.userId});

  @override
  Widget build(BuildContext context) {
    final cached = _requesterNameCache[userId];
    if (cached != null) {
      return Text(cached,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
    }
    return FutureBuilder(
      future: context.read<FirebaseService>().fetchUser(userId),
      builder: (context, snap) {
        final u = snap.data;
        final name = u == null
            ? ''
            : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
        if (name.isNotEmpty) _requesterNameCache[userId] = name;
        return Text(name.isEmpty ? 'Zgłoszenie' : name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis);
      },
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
        ),
      ),
    );
  }
}