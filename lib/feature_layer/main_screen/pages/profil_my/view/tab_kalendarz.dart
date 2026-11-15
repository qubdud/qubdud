import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/client_notes.dart';
import '../../../bloc/main_bloc.dart';
import '../../../../../shared/widgets/load_error.dart';

/// Kalendarz firmy: sloty 1h na najbliższe 7 dni.
/// Kolory: szary = wolny, żółty = ktoś kliknął (czeka), zielony = zaakceptowany.
/// Odrzucenie zwalnia termin. Rezerwacje do akceptacji na górze
/// (Akceptuj/Odrzuć/Napisz).
class TabKalendarz extends StatefulWidget {
  final String companyId;

  /// true: pełne zarządzanie (generator slotów) — widok w Profilu.
  /// false: widok operacyjny na Starcie (rezerwacje + siatka).
  final bool showGenerator;

  /// false: bez sekcji „Rezerwacje do akceptacji" (Profil = konfiguracja).
  final bool showBookings;

  const TabKalendarz({
    super.key,
    required this.companyId,
    this.showGenerator = true,
    this.showBookings = true,
  });

  @override
  State<TabKalendarz> createState() => _TabKalendarzState();
}

class _TabKalendarzState extends State<TabKalendarz> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  bool _error = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final _infoCtrl = TextEditingController();
  bool _infoDirty = false;

  Future<void> _loadInfo() async {
    try {
      final u =
          await context.read<FirebaseService>().fetchUser(widget.companyId);
      if (mounted && u?.slotsInfo != null) _infoCtrl.text = u!.slotsInfo!;
    } catch (_) {
      // bez odczytu pole zostaje puste — opis można wpisać od nowa
    }
  }

  Future<void> _saveInfo() async {
    try {
      final synced = await context
          .read<FirebaseService>()
          .updateUserData(widget.companyId, {'slotsInfo': _infoCtrl.text.trim()});
      if (mounted) setState(() => _infoDirty = false);
      showToast(
          text: synced
              ? 'Zapisano opis terminów'
              : 'Brak sieci — opis zapisze się po połączeniu');
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać opisu');
    }
  }

  @override
  void initState() {
    super.initState();
    final firebase = context.read<FirebaseService>();
    if (widget.showGenerator) _loadInfo();
    firebase.cleanupOldSlots(widget.companyId).ignore();
    _listen();
  }

  /// Podgląd na żywo — rezerwacje klientów wpadają bez odświeżania.
  void _listen() {
    _sub?.cancel();
    _sub = context.read<FirebaseService>().slotsStream(widget.companyId).listen(
        (slots) {
      if (mounted) {
        setState(() {
          _slots = slots;
          _loading = false;
          _error = false;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSlot(DateTime day) async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null || !mounted) return;
    final start =
        DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (start.isBefore(DateTime.now())) {
      showToastError(text: 'Ten termin już minął');
      return;
    }
    try {
      await context.read<FirebaseService>().addSlot(widget.companyId, start);
    } catch (_) {
      showToastError(text: 'Nie udało się dodać terminu');
    }
  }

  Future<void> _removeSlot(Map<String, dynamic> slot) async {
    if (slot['status'] == 'pending' || slot['status'] == 'accepted') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usunąć zajęty termin?'),
          content: Text('Rezerwacja: ${slot['bookedByName']}.\n'
              'Klient dostanie powiadomienie o odwołaniu.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    const Text('Usuń', style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    try {
      await context
          .read<FirebaseService>()
          .removeSlot(widget.companyId, slot['id'] as String);
      if (mounted) {
        setState(
            () => _slots = _slots.where((s) => s['id'] != slot['id']).toList());
      }
    } catch (e) {
      showToastError(text: slotErrorText(e));
    }
  }

  /// Generator: start + długość slotu + ilość + dzień (lub cały tydzień).
  Future<void> _generateSlots() async {
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    int durationMin = 60;
    int count = 4;
    int dayOffset = 1;
    bool wholeWeek = false;

    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day + i));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Generuj sloty'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Start:')),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                            context: ctx, initialTime: start);
                        if (t != null) setDlg(() => start = t);
                      },
                      child: Text(
                          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Długość slotu:')),
                    DropdownButton<int>(
                      value: durationMin,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 60, child: Text('1 h')),
                        DropdownMenuItem(value: 90, child: Text('1,5 h')),
                        DropdownMenuItem(value: 120, child: Text('2 h')),
                      ],
                      onChanged: (v) => setDlg(() => durationMin = v ?? 60),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Ilość slotów:')),
                    DropdownButton<int>(
                      value: count,
                      items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                              value: i + 1, child: Text('${i + 1}'))),
                      onChanged: (v) => setDlg(() => count = v ?? 4),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Expanded(child: Text('Dzień:')),
                    DropdownButton<int>(
                      value: dayOffset,
                      items: List.generate(
                          7,
                          (i) => DropdownMenuItem(
                              value: i, child: Text(dayLabel(days[i])))),
                      onChanged: wholeWeek
                          ? null
                          : (v) => setDlg(() => dayOffset = v ?? 0),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cały tydzień (7 dni)'),
                  value: wholeWeek,
                  onChanged: (v) => setDlg(() => wholeWeek = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Generuj')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    final existing = _slots
        .map((s) => (s['start'] as DateTime))
        .map((d) => DateTime(d.year, d.month, d.day, d.hour, d.minute))
        .toSet();
    final now = DateTime.now();
    final starts = <DateTime>[];
    final targetDays = wholeWeek ? days : [days[dayOffset]];
    for (final day in targetDays) {
      for (int i = 0; i < count; i++) {
        final dt = DateTime(day.year, day.month, day.day, start.hour,
                start.minute)
            .add(Duration(minutes: durationMin * i));
        if (dt.isBefore(now)) continue;
        if (existing.contains(dt)) continue;
        starts.add(dt);
      }
    }
    if (starts.isEmpty) {
      showToastError(text: 'Nic do dodania (terminy minęły lub już istnieją)');
      return;
    }
    try {
      await context
          .read<FirebaseService>()
          .addSlotsBatch(widget.companyId, starts, durationMin);
      showToast(text: 'Dodano ${starts.length} slotów');
    } catch (_) {
      showToastError(text: 'Nie udało się dodać terminów');
    }
  }

  /// Akceptacja albo odrzucenie (odrzucenie zwalnia termin dla innych);
  /// widok odświeża strumień slotów.
  Future<void> _setStatus(Map<String, dynamic> slot, String status) async {
    try {
      await context.read<FirebaseService>().setSlotStatus(
            companyId: widget.companyId,
            slotId: slot['id'] as String,
            status: status,
            bookedBy: slot['bookedBy'] as String,
          );
      showToast(
          text: status == 'accepted'
              ? 'Zaakceptowano rezerwację'
              : 'Odrzucono — termin znów jest wolny');
    } catch (e) {
      showToastError(text: slotErrorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error) {
      return LoadError(
        message: 'Nie udało się wczytać kalendarza',
        onRetry: () {
          setState(() => _loading = true);
          _listen();
        },
      );
    }

    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day + i));
    final pending =
        _slots.where((s) => s['status'] == 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(kGapL),
      children: [
        // ── Mini panel tygodnia (zajętość na żywo) ───────
        SizedBox(
          height: 64,
          child: Row(
            children: days.map((day) {
              final daySlots = _slots.where((s) {
                final st = s['start'] as DateTime;
                return st.year == day.year &&
                    st.month == day.month &&
                    st.day == day.day;
              }).toList();
              final busy = daySlots
                  .where((s) =>
                      s['status'] == 'pending' || s['status'] == 'accepted')
                  .length;
              final hasPending =
                  daySlots.any((s) => s['status'] == 'pending');
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: kGapXs / 2),
                  padding: const EdgeInsets.symmetric(vertical: kGapS),
                  decoration: BoxDecoration(
                    color: hasPending
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: hasPending
                        ? Border.all(color: Colors.amber)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                            '${const ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'][day.weekday - 1]} ${DateFormat('d.MM').format(day)}',
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: kGapXs),
                      Text(
                          daySlots.isEmpty
                              ? '—'
                              : '$busy/${daySlots.length}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: kGapM),

        // ── Rezerwacje do akceptacji ──────────────────────
        if (widget.showBookings && pending.isNotEmpty) ...[
          const Text('Rezerwacje do akceptacji',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: kGapS),
          ...pending.map((s) => Card(
                margin: const EdgeInsets.only(bottom: kGapS),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadius)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: kGapM, vertical: kGapS),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: kGapS),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.read<MainScreenBloc>().add(
                              GoToProfilPublicznyUseraEvent(
                                  s['bookedBy'] as String)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['bookedByName'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline)),
                              Text(
                                '${dayLabel(s['start'] as DateTime)}, ${DateFormat('HH:mm').format(s['start'] as DateTime)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              ClientNoteBadge(
                                  userId: s['bookedBy'] as String,
                                  personName: s['bookedByName'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.green),
                        tooltip: 'Akceptuj',
                        onPressed: () => _setStatus(s, 'accepted'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        tooltip: 'Odrzuć',
                        onPressed: () => _setStatus(s, 'rejected'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        tooltip: 'Napisz',
                        onPressed: () => context.read<MainScreenBloc>().add(
                            GoToChatEvent(s['bookedBy'] as String,
                                chatName: s['bookedByName'] as String?)),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: kGapM),
        ],

        Text(
          'Sloty na najbliższy tydzień. Klienci klikają kropkę na Twoim profilu — żółta czeka na Twoją decyzję (tap na żółtej = akceptuj, przytrzymaj slot = usuń).',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: kGapS),
        if (widget.showGenerator) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('Generuj sloty (start, długość, ilość, dni)'),
            onPressed: _generateSlots,
          ),
          const SizedBox(height: kGapL),
          // czym są terminy — klient zobaczy to nad kropkami na Twoim profilu
          const Text('Czym są Twoje terminy?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: kGapS),
          TextField(
            controller: _infoCtrl,
            maxLength: 200,
            maxLines: 3,
            minLines: 2,
            onChanged: (_) {
              if (!_infoDirty) setState(() => _infoDirty = true);
            },
            decoration: const InputDecoration(
              hintText:
                  'np. Konsultacja telefoniczna 30 min / Strzyżenie męskie / Wizyta u klienta',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Zapisz opis'),
              onPressed: _infoDirty ? _saveInfo : null,
            ),
          ),
          const SizedBox(height: kGapS),
        ],
        _legend(),
        const SizedBox(height: kGapM),
        ...days.map((day) => _dayCard(day)),
        const SizedBox(height: kGapXl),
      ],
    );
  }

  Widget _legend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: kGapXs),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        );
    return Wrap(
      spacing: kGapM,
      children: [
        dot(Colors.grey.shade400, 'wolny'),
        dot(Colors.amber, 'czeka'),
        dot(Colors.green, 'przyjęty'),
      ],
    );
  }

  Widget _dayCard(DateTime day) {
    final daySlots = _slots.where((s) {
      final st = s['start'] as DateTime;
      return st.year == day.year && st.month == day.month && st.day == day.day;
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: kGapS),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kGapM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel(day),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                if (widget.showGenerator)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    tooltip: 'Dodaj termin',
                    onPressed: () => _addSlot(day),
                  ),
              ],
            ),
            if (daySlots.isEmpty)
              Text('Brak terminów',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
            else
              Wrap(
                spacing: kGapS,
                runSpacing: kGapS,
                children: daySlots.map((s) {
                  final st = s['start'] as DateTime;
                  final status = s['status'] as String;
                  final color = switch (status) {
                    'pending' => Colors.amber,
                    'accepted' => Colors.green,
                    _ => Colors.grey.shade400,
                  };
                  final label = DateFormat('HH:mm').format(st);
                  final who = (s['bookedByName'] as String?) ?? '';
                  return InkWell(
                    onLongPress: () => _removeSlot(s),
                    onTap: status == 'pending'
                        ? () => _setStatus(s, 'accepted')
                        : (who.isNotEmpty
                            ? () => context.read<MainScreenBloc>().add(
                                GoToProfilPublicznyUseraEvent(
                                    s['bookedBy'] as String))
                            : null),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: kGapS, vertical: kGapXs),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: kGapXs),
                              Text(label,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (who.isNotEmpty)
                            Text(who,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

String dayLabel(DateTime day) {
  final today = DateTime.now();
  final isToday = day.year == today.year &&
      day.month == today.month &&
      day.day == today.day;
  final tomorrow = today.add(const Duration(days: 1));
  final isTomorrow = day.year == tomorrow.year &&
      day.month == tomorrow.month &&
      day.day == tomorrow.day;

  const weekdays = [
    'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota', 'Niedziela'
  ];
  final name = isToday
      ? 'Dziś'
      : isTomorrow
          ? 'Jutro'
          : weekdays[day.weekday - 1];
  return '$name, ${DateFormat('d.MM').format(day)}';
}
