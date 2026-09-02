import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/client_notes.dart';
import '../../../bloc/main_bloc.dart';

/// Kalendarz firmy: sloty 1h na najbliższe 7 dni.
/// Kolory: szary = wolny, żółty = ktoś kliknął (czeka), zielony = zaakceptowany,
/// czerwony = odrzucony. Rezerwacje do akceptacji na górze (Akceptuj/Odrzuć/Napisz).
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
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final _infoCtrl = TextEditingController();
  bool _infoDirty = false;

  Future<void> _loadInfo() async {
    final u = await context.read<FirebaseService>().fetchUser(widget.companyId);
    if (mounted && u?.slotsInfo != null) _infoCtrl.text = u!.slotsInfo!;
  }

  Future<void> _saveInfo() async {
    try {
      await context
          .read<FirebaseService>()
          .updateUserData(widget.companyId, {'slotsInfo': _infoCtrl.text.trim()});
      if (mounted) setState(() => _infoDirty = false);
      showToast(text: 'Zapisano opis terminów');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    final firebase = context.read<FirebaseService>();
    if (widget.showGenerator) _loadInfo();
    firebase.cleanupOldSlots(widget.companyId).catchError((_) {});
    // podgląd na żywo — rezerwacje klientów wpadają bez odświeżania
    _sub = firebase.slotsStream(widget.companyId).listen((slots) {
      if (mounted) setState(() { _slots = slots; _loading = false; });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _infoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {}

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
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  Future<void> _removeSlot(Map<String, dynamic> slot) async {
    if (slot['status'] == 'pending' || slot['status'] == 'accepted') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Usunąć zajęty termin?'),
          content: Text('Rezerwacja: ${slot['bookedByName']}'),
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
      if (ok != true) return;
    }
    try {
      await context
          .read<FirebaseService>()
          .removeSlot(widget.companyId, slot['id'] as String);
      setState(
          () => _slots = _slots.where((s) => s['id'] != slot['id']).toList());
    } catch (e) {
      showToastError(text: 'Błąd: $e');
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
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  Future<void> _setStatus(Map<String, dynamic> slot, String status) async {
    try {
      await context.read<FirebaseService>().setSlotStatus(
            companyId: widget.companyId,
            slotId: slot['id'] as String,
            status: status,
            bookedBy: slot['bookedBy'] as String?,
          );
      setState(() => slot['status'] = status);
      showToast(
          text: status == 'accepted'
              ? 'Zaakceptowano rezerwację'
              : 'Odrzucono rezerwację');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final today = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(today.year, today.month, today.day + i));
    final pending =
        _slots.where((s) => s['status'] == 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
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
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
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
                      Text(
                          '${const ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'][day.weekday - 1]} ${DateFormat('d.MM').format(day)}',
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
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
        const SizedBox(height: 12),

        // ── Rezerwacje do akceptacji ──────────────────────
        if (widget.showBookings && pending.isNotEmpty) ...[
          const Text('Rezerwacje do akceptacji',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...pending.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.amber, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
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
          const SizedBox(height: 12),
        ],

        Text(
          'Sloty na najbliższy tydzień. Klienci klikają kropkę na Twoim profilu — żółta czeka na Twoją decyzję (tap na żółtej = akceptuj, przytrzymaj slot = usuń).',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        if (widget.showGenerator) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.auto_awesome_outlined, size: 18),
            label: const Text('Generuj sloty (start, długość, ilość, dni)'),
            onPressed: _generateSlots,
          ),
          const SizedBox(height: 14),
          // czym są terminy — klient zobaczy to nad kropkami na Twoim profilu
          const Text('Czym są Twoje terminy?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
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
          const SizedBox(height: 8),
        ],
        _legend(),
        const SizedBox(height: 12),
        ...days.map((day) => _dayCard(day)),
        const SizedBox(height: 40),
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
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        );
    return Wrap(
      spacing: 12,
      children: [
        dot(Colors.grey.shade400, 'wolny'),
        dot(Colors.amber, 'czeka'),
        dot(Colors.green, 'przyjęty'),
        dot(Colors.red, 'odrzucony'),
      ],
    );
  }

  Widget _dayCard(DateTime day) {
    final daySlots = _slots.where((s) {
      final st = s['start'] as DateTime;
      return st.year == day.year && st.month == day.month && st.day == day.day;
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                spacing: 8,
                runSpacing: 8,
                children: daySlots.map((s) {
                  final st = s['start'] as DateTime;
                  final status = s['status'] as String;
                  final color = switch (status) {
                    'pending' => Colors.amber,
                    'accepted' => Colors.green,
                    'rejected' => Colors.red,
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
                          horizontal: 8, vertical: 5),
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
                              const SizedBox(width: 4),
                              Text(label,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          if (who.isNotEmpty)
                            Text(who,
                                style: TextStyle(
                                    fontSize: 9,
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
