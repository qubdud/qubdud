import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/widgets/empty_state.dart';

import '../../../bloc/main_bloc.dart';
import '../../../../../shared/widgets/load_error.dart';

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
  final Map<String, String> _phones = {};
  bool _loading = true;
  bool _error = false;

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));
    await launchUrl(uri);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    try {
      final firebase = context.read<FirebaseService>();
      final bookings = await firebase.getMyBookings(myUid);
      for (final id in bookings.map((b) => b['companyId'] as String).toSet()) {
        if (_phones.containsKey(id)) continue;
        final u = await firebase.fetchUser(id);
        if (u?.phone?.isNotEmpty == true) _phones[id] = u!.phone!;
      }
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _loading = false;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  /// Oczekująca/przyjęta: odwołanie (z potwierdzeniem, firma dostaje
  /// powiadomienie). Odrzucona/odwołana przez firmę: tylko zniknięcie z listy.
  Future<void> _remove(Map<String, dynamic> b) async {
    final active = b['status'] == 'pending' || b['status'] == 'accepted';
    if (active) {
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
                child: const Text('Odwołaj',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final myUid = context.read<MainScreenBloc>().state.user?.id ?? '';
    try {
      await context.read<FirebaseService>().cancelSlotBooking(
            companyId: b['companyId'] as String,
            slotId: b['slotId'] as String,
            myUid: myUid,
          );
      if (active) showToast(text: 'Odwołano rezerwację');
    } catch (e) {
      showToastError(text: slotErrorText(e));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error) {
      return LoadError(
        message: 'Nie udało się wczytać rezerwacji',
        onRetry: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }

    if (_bookings.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Brak rezerwacji',
        subtitle: 'Kliknij kropkę-termin na profilu firmy,\naby umówić wizytę.',
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
          final active = status == 'pending' || status == 'accepted';
          final color = switch (status) {
            'accepted' => Colors.green,
            'rejected' || 'cancelled' => Colors.red,
            _ => Colors.amber,
          };
          final statusText = switch (status) {
            'accepted' => 'przyjęta',
            'rejected' => 'odrzucona przez firmę',
            'cancelled' => 'odwołana przez firmę',
            _ => 'czeka na akceptację',
          };
          final today = DateTime.now();
          final isToday = start.year == today.year &&
              start.month == today.month &&
              start.day == today.day;
          final tomorrow = today.add(const Duration(days: 1));
          final isTomorrow = start.year == tomorrow.year &&
              start.month == tomorrow.month &&
              start.day == tomorrow.day;
          final dayPart = isToday
              ? 'Dziś'
              : isTomorrow
                  ? 'Jutro'
                  : '${wd[start.weekday - 1]} ${start.day}.${start.month.toString().padLeft(2, '0')}';
          final timePart =
              '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
          final dark = switch (status) {
            'accepted' => Colors.green.shade800,
            'rejected' || 'cancelled' => Colors.red.shade700,
            _ => Colors.amber.shade900,
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.read<MainScreenBloc>().add(
                  GoToProfilPublicznyFirmyEvent(b['companyId'] as String)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // nazwa + X (odwołaj / usuń z listy) w rogu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text('${b['companyName']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.close,
                              size: 20, color: Colors.red.shade400),
                          tooltip: active ? 'Odwołaj' : 'Usuń z listy',
                          onPressed: () => _remove(b),
                        ),
                      ],
                    ),
                    // balonik z terminem + ikona statusu, po prawej telefon i czat
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 7),
                              Text(dayPart,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: dark)),
                              const SizedBox(width: 6),
                              Text(timePart,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: dark)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: statusText,
                          triggerMode: TooltipTriggerMode.tap,
                          child: Icon(
                            switch (status) {
                              'accepted' => Icons.check_circle,
                              'rejected' || 'cancelled' => Icons.cancel,
                              _ => Icons.schedule,
                            },
                            color: color,
                            size: 24,
                          ),
                        ),
                        // odrzucenie/odwołanie przez firmę musi być widać od razu
                        if (!active) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(statusText,
                                maxLines: 2,
                                style: TextStyle(fontSize: 12, color: dark)),
                          ),
                        ],
                        const Spacer(),
                        if (_phones[b['companyId']] != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.phone_outlined, size: 22),
                            tooltip: 'Zadzwoń',
                            onPressed: () => _call(_phones[b['companyId']]!),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.chat_bubble_outline, size: 22),
                          tooltip: 'Napisz',
                          onPressed: () => context.read<MainScreenBloc>().add(
                              GoToChatEvent(b['companyId'] as String,
                                  chatName: b['companyName'] as String?)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

