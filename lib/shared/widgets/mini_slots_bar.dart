import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'anonim_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain_layer/firebase_service.dart';
import '../functions/show_toast.dart';
import '../functions/show_toast_error.dart';
import '../globals.dart';

/// Mini-mapka slotów firmy na panelu z filmem: najbliższe terminy jako
/// klikalne kropki (rezerwacja jednym tapnięciem). Na żywo.
/// Anonim nie ma dostępu do terminów — widzi zachętę do logowania.
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
  bool get _anonim => Globals.instance.anonim || _myUid.isEmpty;
  bool get _own => widget.companyId == _myUid;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = null;
    _slots = [];
    // anonim nie czyta slotów (reguły), własnych terminów firma nie rezerwuje
    if (_anonim || _own) return;
    _sub = context
        .read<FirebaseService>()
        .slotsStream(widget.companyId)
        .listen((slots) {
      if (mounted) setState(() => _slots = slots);
    }, onError: (_) {
      // pasek jest dodatkiem do filmu — przy błędzie po prostu go nie ma
      if (mounted) setState(() => _slots = []);
    });
  }

  @override
  void didUpdateWidget(covariant MiniSlotsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) _listen();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _tap(Map<String, dynamic> s) async {
    final firebase = context.read<FirebaseService>();
    final status = s['status'] as String;
    final mine = s['bookedBy'] == _myUid;

    if (status == 'free') {
      final st = s['start'] as DateTime;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Zarezerwować ${DateFormat('dd.MM, HH:mm').format(st)}?'),
          content: const Text(
              'Firma zobaczy Twój telefon i e-mail, potwierdzi albo odrzuci rezerwację — dostaniesz powiadomienie.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rezerwuj')),
          ],
        ),
      );
      if (go != true || !mounted) return;
      try {
        await firebase.bookSlot(
          companyId: widget.companyId,
          slotId: s['id'] as String,
          myUid: _myUid,
        );
        showToast(text: 'Zarezerwowano — czeka na akceptację firmy');
      } catch (e) {
        showToastError(text: slotErrorText(e));
      }
      return;
    }
    if (mine && status == 'pending') {
      try {
        await firebase.cancelSlotBooking(
            companyId: widget.companyId,
            slotId: s['id'] as String,
            myUid: _myUid);
        showToast(text: 'Odwołano rezerwację');
      } catch (e) {
        showToastError(text: slotErrorText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_anonim) {
      return GestureDetector(
        onTap: () => showLoginPrompt(context, 'zobaczyć terminy'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.black.withOpacity(0.45),
          child: const Row(
            children: [
              Icon(Icons.event_available_outlined,
                  color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text('Zaloguj się, aby zobaczyć terminy',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    // pokazujemy: wolne + moje rezerwacje, max 6 najbliższych
    final visible = _slots
        .where((s) => s['status'] == 'free' || s['bookedBy'] == _myUid)
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
                  final mine = s['bookedBy'] == _myUid;
                  final color = switch (status) {
                    'free' => Colors.greenAccent,
                    'accepted' => Colors.green,
                    _ => Colors.amber,
                  };
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
