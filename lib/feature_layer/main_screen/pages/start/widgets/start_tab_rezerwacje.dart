import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/widgets/empty_state.dart';

import '../../../bloc/main_bloc.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Moje rezerwacje (firma + godzina + status)
// ─────────────────────────────────────────────────────────────────────────────
class StartTabRezerwacje extends StatefulWidget {
  const StartTabRezerwacje({super.key});

  @override
  State<StartTabRezerwacje> createState() => StartTabRezerwacjeState();
}

class StartTabRezerwacjeState extends State<StartTabRezerwacje> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    try {
      final bookings =
          await context.read<FirebaseService>().getMyBookings(myUid);
      if (mounted) setState(() { _bookings = bookings; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odwołać rezerwację?'),
        content: Text('${b['companyName']}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zostaw')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Odwołaj', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    await context.read<FirebaseService>().cancelSlotBooking(
          companyId: b['companyId'] as String,
          slotId: b['slotId'] as String,
          myUid: myUid,
        );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('Brak rezerwacji',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 6),
            Text('Kliknij kropkę-termin na profilu firmy,\naby umówić wizytę.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    const wd = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (context, i) {
          final b = _bookings[i];
          final start = b['start'] as DateTime;
          final status = b['status'] as String? ?? 'pending';
          final color = switch (status) {
            'accepted' => Colors.green,
            'rejected' => Colors.red,
            _ => Colors.amber,
          };
          final statusText = switch (status) {
            'accepted' => 'przyjęta',
            'rejected' => 'odrzucona',
            _ => 'czeka na akceptację',
          };
          final when =
              '${wd[start.weekday - 1]} ${start.day}.${start.month.toString().padLeft(2, '0')}, ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              onTap: () => context.read<MainScreenBloc>().add(
                  GoToProfilPublicznyFirmyEvent(b['companyId'] as String)),
              leading: Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.only(top: 6),
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              title: Text('${b['companyName']} — $when',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(statusText,
                  style: TextStyle(fontSize: 12, color: color)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    tooltip: 'Napisz',
                    onPressed: () => context.read<MainScreenBloc>().add(
                        GoToChatEvent(b['companyId'] as String,
                            chatName: b['companyName'] as String?)),
                  ),
                  if (status != 'rejected')
                    IconButton(
                      icon: Icon(Icons.close,
                          size: 18, color: Colors.red.shade300),
                      tooltip: 'Odwołaj',
                      onPressed: () => _cancel(b),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

