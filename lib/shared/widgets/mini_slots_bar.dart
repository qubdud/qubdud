import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain_layer/firebase_service.dart';
import '../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../functions/show_toast.dart';
import '../globals.dart';

/// Mini-mapka slotów firmy na panelu z filmem: najbliższe terminy jako
/// klikalne kropki (rezerwacja jednym tapnięciem). Na żywo.
class MiniSlotsBar extends StatefulWidget {
  final String companyId;

  const MiniSlotsBar({super.key, required this.companyId});

  @override
  State<MiniSlotsBar> createState() => _MiniSlotsBarState();
}

class _MiniSlotsBarState extends State<MiniSlotsBar> {
  List<Map<String, dynamic>> _slots = [];
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _sub = context
        .read<FirebaseService>()
        .slotsStream(widget.companyId)
        .listen((slots) {
      if (mounted) setState(() => _slots = slots);
    }, onError: (_) {});
  }

  @override
  void didUpdateWidget(covariant MiniSlotsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _sub?.cancel();
      _slots = [];
      _sub = context
          .read<FirebaseService>()
          .slotsStream(widget.companyId)
          .listen((slots) {
        if (mounted) setState(() => _slots = slots);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _tap(Map<String, dynamic> s) async {
    if (Globals.instance.anonim || _myUid.isEmpty) {
      showToast(text: 'Zaloguj się, aby zarezerwować termin');
      return;
    }
    final status = s['status'] as String;
    final mine = s['bookedBy'] == _myUid;

    if (status == 'free') {
      final me = context.read<MainScreenBloc>().state.user;
      final myName = me?.firma == true
          ? (me?.companyName ?? 'Firma')
          : '${me?.firstName ?? ''} ${me?.lastName ?? ''}'.trim();
      try {
        await context.read<FirebaseService>().bookSlot(
              companyId: widget.companyId,
              slotId: s['id'] as String,
              myUid: _myUid,
              myName: myName.isEmpty ? 'Użytkownik' : myName,
            );
        showToast(text: 'Zarezerwowano — czeka na akceptację firmy');
      } catch (_) {
        showToast(text: 'Ten termin jest już zajęty');
      }
      return;
    }
    if (mine && status == 'pending') {
      await context.read<FirebaseService>().cancelSlotBooking(
          companyId: widget.companyId,
          slotId: s['id'] as String,
          myUid: _myUid);
      showToast(text: 'Odwołano rezerwację');
    }
  }

  @override
  Widget build(BuildContext context) {
    // pokazujemy: wolne + moje rezerwacje, max 6 najbliższych
    final visible = _slots
        .where((s) =>
            s['status'] == 'free' ||
            (s['bookedBy'] == _myUid && _myUid.isNotEmpty))
        .take(6)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    const wd = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: Colors.black.withOpacity(0.45),
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined,
              color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: visible.map((s) {
                  final st = s['start'] as DateTime;
                  final status = s['status'] as String;
                  final mine =
                      s['bookedBy'] == _myUid && _myUid.isNotEmpty;
                  final color = status == 'free'
                      ? Colors.greenAccent
                      : (status == 'accepted'
                          ? Colors.green
                          : (status == 'rejected'
                              ? Colors.redAccent
                              : Colors.amber));
                  final isToday = st.day == today.day &&
                      st.month == today.month;
                  final label =
                      '${isToday ? 'Dziś' : wd[st.weekday - 1]} ${DateFormat('HH:mm').format(st)}';
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => _tap(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: mine
                              ? color.withOpacity(0.25)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(label,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
