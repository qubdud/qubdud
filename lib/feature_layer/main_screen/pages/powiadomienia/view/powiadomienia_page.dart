import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/functions/days_ago.dart';
import '../../../../../shared/functions/effective_role.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/widgets/empty_state.dart';
import '../../../../../shared/widgets/load_error.dart';
import '../../../bloc/main_bloc.dart';

/// Dzwonek: wszystko, co się wydarzyło — oferty, decyzje, rezerwacje,
/// wiadomości, prośby o potwierdzenie realizacji. Klik prowadzi w miejsce akcji.
class PowiadomieniaPage extends StatefulWidget {
  const PowiadomieniaPage({super.key});

  @override
  State<PowiadomieniaPage> createState() => _PowiadomieniaPageState();
}

class _PowiadomieniaPageState extends State<PowiadomieniaPage> {
  late final FirebaseService _firebase;
  late final String _uid;
  late final bool _companyMode;
  late Stream<List<Map<String, dynamic>>> _stream;

  static ({IconData icon, Color color}) _look(String type) => switch (type) {
        'urgent_request' => (icon: Icons.priority_high, color: Colors.red),
        'new_request' => (icon: Icons.fiber_new_outlined, color: Colors.blue),
        'offer' => (icon: Icons.local_offer_outlined, color: Colors.blue),
        'offer_decision' => (icon: Icons.how_to_reg_outlined, color: Colors.green),
        'booking' => (icon: Icons.event_available_outlined, color: Colors.indigo),
        'booking_decision' => (icon: Icons.event_note_outlined, color: Colors.teal),
        'booking_reminder' => (icon: Icons.alarm, color: Colors.indigo),
        _ when type.startsWith('booking') =>
          (icon: Icons.event_busy_outlined, color: Colors.teal),
        'chat' => (icon: Icons.chat_bubble_outline, color: Colors.blueGrey),
        'realization' => (icon: Icons.photo_camera_back_outlined, color: Colors.amber),
        'realization_from_user' => (icon: Icons.add_photo_alternate_outlined, color: Colors.amber),
        'realization_decision' => (icon: Icons.verified_outlined, color: Colors.green),
        'contact_request' => (icon: Icons.phone_callback_outlined, color: Colors.orange),
        'review' => (icon: Icons.star_outline, color: Colors.amber),
        'request_expired' => (icon: Icons.timer_off_outlined, color: Colors.grey),
        'request_reopened' => (icon: Icons.replay, color: Colors.blue),
        'request_deleted' => (icon: Icons.delete_outline, color: Colors.grey),
        _ => (icon: Icons.notifications_none, color: Colors.grey),
      };

  static String _when(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'przed chwilą';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min temu';
    if (diff.inHours < 24) return '${diff.inHours} godz. temu';
    final days = calendarDaysAgo(d);
    if (days <= 1) return 'wczoraj';
    if (days < 7) return '$days dni temu';
    return '${d.day}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _firebase = context.read<FirebaseService>();
    final user = context.read<MainScreenBloc>().state.user;
    _uid = user?.id ?? '';
    _companyMode = isCompanyMode(user);
    _stream = _firebase.notificationsStream(_uid, companyMode: _companyMode);
  }

  void _reload() => setState(() =>
      _stream = _firebase.notificationsStream(_uid, companyMode: _companyMode));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return LoadError(
              message: 'Nie udało się wczytać powiadomień', onRetry: _reload);
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.notifications_none,
            title: 'Brak powiadomień',
            subtitle: _companyMode
                ? 'Tu pojawią się zgłoszenia w pobliżu, decyzje klientów, rezerwacje i wiadomości.'
                : 'Tu pojawią się oferty firm, potwierdzenia terminów i wiadomości.',
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
                      onPressed: () => _firebase
                          .markAllNotificationsRead(_uid,
                              companyMode: _companyMode)
                          .catchError((Object _) => showToast(
                              text: 'Nie udało się oznaczyć powiadomień.')),
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
                    confirmDismiss: (_) async =>
                        await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Usunąć powiadomienie?'),
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
                        ) ==
                        true,
                    onDismissed: (_) => _firebase
                        .deleteNotification(n['id'] as String)
                        .catchError((Object _) => showToast(
                            text: 'Nie udało się usunąć powiadomienia.')),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isNew ? Colors.blue.shade50 : null,
                      child: ListTile(
                        onTap: () => context
                            .read<MainScreenBloc>()
                            .add(OpenNotificationEvent.fromNotification(n)),
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
