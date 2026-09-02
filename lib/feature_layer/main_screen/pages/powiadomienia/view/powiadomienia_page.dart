import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../bloc/main_bloc.dart';

/// Dzwonek: wszystko, co się wydarzyło — oferty, decyzje, rezerwacje,
/// wiadomości, prośby o potwierdzenie realizacji. Klik prowadzi w miejsce akcji.
class PowiadomieniaPage extends StatelessWidget {
  const PowiadomieniaPage({super.key});

  static ({IconData icon, Color color}) _look(String type) => switch (type) {
        'urgent_request' => (icon: Icons.priority_high, color: Colors.red),
        'offer' => (icon: Icons.local_offer_outlined, color: Colors.blue),
        'offer_decision' => (icon: Icons.how_to_reg_outlined, color: Colors.green),
        'booking' => (icon: Icons.event_available_outlined, color: Colors.indigo),
        'booking_decision' => (icon: Icons.event_note_outlined, color: Colors.teal),
        'chat' => (icon: Icons.chat_bubble_outline, color: Colors.blueGrey),
        'realization' => (icon: Icons.photo_camera_back_outlined, color: Colors.amber),
        'realization_from_user' => (icon: Icons.add_photo_alternate_outlined, color: Colors.amber),
        'realization_decision' => (icon: Icons.verified_outlined, color: Colors.green),
        'review' => (icon: Icons.star_outline, color: Colors.amber),
        'request_expired' => (icon: Icons.timer_off_outlined, color: Colors.grey),
        _ => (icon: Icons.notifications_none, color: Colors.grey),
      };

  static String _when(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'przed chwilą';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
    if (diff.inHours < 24) return '${diff.inHours} godz. temu';
    if (diff.inDays == 1) return 'wczoraj';
    if (diff.inDays < 7) return '${diff.inDays} dni temu';
    return '${d.day}.${d.month.toString().padLeft(2, '0')}';
  }

  void _open(BuildContext context, Map<String, dynamic> n) {
    final firebase = context.read<FirebaseService>();
    final bloc = context.read<MainScreenBloc>();
    if (n['read'] != true) firebase.markNotificationRead(n['id'] as String);

    final type = n['type'] as String? ?? '';
    final requestId = n['requestId'] as String? ?? '';
    final companyId = n['companyId'] as String? ?? '';
    final from = n['from'] as String? ?? '';

    switch (type) {
      case 'chat':
        if (from.isNotEmpty) bloc.add(GoToChatEvent(from));
        return;
      case 'review':
        if (companyId.isNotEmpty) bloc.add(GoToProfilPublicznyFirmyEvent(companyId));
        return;
      case 'booking':
      case 'booking_decision':
        Globals.instance.startTab = 1;
        bloc.add(GoToHomeEvent());
        return;
      default:
        if (requestId.isNotEmpty) {
          firebase.getRequestById(requestId).then((r) {
            if (r != null) {
              Globals.instance.selectedRequest = r;
              bloc.add(GoToShowRequestEvent());
            } else {
              bloc.add(GoToHomeEvent());
            }
          });
        } else {
          bloc.add(GoToHomeEvent());
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebase = context.read<FirebaseService>();
    final uid = context.read<MainScreenBloc>().state.user?.id ?? '';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firebase.notificationsStream(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.notifications_none,
            title: 'Brak powiadomień',
            subtitle:
                'Tu pojawią się oferty, decyzje klientów, rezerwacje i wiadomości.',
          );
        }
        final unread = items.where((n) => n['read'] != true).length;

        return Column(
          children: [
            if (unread > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: Row(
                  children: [
                    Text('$unread ${unread == 1 ? 'nowe' : 'nowych'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Oznacz wszystkie'),
                      onPressed: () => firebase.markAllNotificationsRead(uid),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final n = items[i];
                  final isNew = n['read'] != true;
                  final look = _look(n['type'] as String? ?? '');

                  return Dismissible(
                    key: ValueKey(n['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) =>
                        firebase.deleteNotification(n['id'] as String),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isNew ? Colors.blue.shade50 : null,
                      child: ListTile(
                        onTap: () => _open(context, n),
                        leading: CircleAvatar(
                          backgroundColor: look.color.withOpacity(0.15),
                          child: Icon(look.icon, color: look.color, size: 20),
                        ),
                        title: Text(n['title'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    isNew ? FontWeight.bold : FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(n['body'] as String? ?? '',
                                style: const TextStyle(fontSize: 12.5)),
                            const SizedBox(height: 2),
                            Text(_when(n['createdAt']),
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                          ],
                        ),
                        trailing: isNew
                            ? Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    shape: BoxShape.circle))
                            : const Icon(Icons.chevron_right,
                                size: 18, color: Colors.grey),
                      ),
                    ),
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
