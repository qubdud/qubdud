import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/functions/show_toast_error.dart';

/// Szybki kalendarz firmy: sloty godzinowe na 7 dni do przodu.
class TabKalendarz extends StatefulWidget {
  final String companyId;
  const TabKalendarz({super.key, required this.companyId});

  @override
  State<TabKalendarz> createState() => _TabKalendarzState();
}

class _TabKalendarzState extends State<TabKalendarz> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final firebase = context.read<FirebaseService>();
    try {
      await firebase.cleanupOldSlots(widget.companyId);
      final slots = await firebase.getSlots(widget.companyId);
      if (mounted) setState(() { _slots = slots; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      showToastError(text: 'Błąd: $e');
    }
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
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  Future<void> _removeSlot(String slotId) async {
    try {
      await context
          .read<FirebaseService>()
          .removeSlot(widget.companyId, slotId);
      setState(() => _slots = _slots.where((s) => s['id'] != slotId).toList());
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Dodaj wolne terminy na najbliższy tydzień — klienci zobaczą je na Twoim profilu.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        ...days.map((day) => _dayCard(day)),
        const SizedBox(height: 40),
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
                  return Chip(
                    label: Text(DateFormat('HH:mm').format(st),
                        style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeSlot(s['id'] as String),
                    visualDensity: VisualDensity.compact,
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
