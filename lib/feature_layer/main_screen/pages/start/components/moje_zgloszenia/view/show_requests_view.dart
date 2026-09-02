import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/widgets/before_after.dart';
import 'package:qb/shared/realizations.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:video_player/video_player.dart';


import '../../../../../../../shared/functions/show_toast.dart';
import '../../../../../../../shared/globals.dart';
import '../../../../../../../shared/widgets/loading.dart';
import '../../../../../../../shared/widgets/request_take_status.dart';
import '../../../../../../../shared/widgets/w_button.dart';
import '../../../../../../../shared/widgets/w_input_field.dart';
import '../../../../../../../shared/widgets/w_small_label.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../bloc/show_requests_bloc.dart';


class ShowRequestsComponent extends StatelessWidget {
  const ShowRequestsComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShowRequestsComponentBloc(
        firebase: context.read<FirebaseService>(),
        user: context.read<MainScreenBloc>().state.user!,
      ),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {


  @override
  Widget build(BuildContext context) {


    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 26),
              label: const Text('Dodaj zgłoszenie',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: cDarkBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 3,
              ),
              onPressed: () =>
                  context.read<MainScreenBloc>().add(GoToDodajEvent()),
            ),
          ),
        ),

        Expanded(
          child: BlocConsumer<ShowRequestsComponentBloc, ShowRequestsComponentState>(
            listener: (context, state) {
              if (state is ShowRequestsComponentNextState) {
                context.read<MainScreenBloc>().add(InitEvent());
              }
            },


            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },




                child:











                _buildTabbedContent(state),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabbedContent(ShowRequestsComponentState state) {


    if (state is ShowRequestsComponentLoadingState) {
      return Loading(noText: true, key: UniqueKey());
    }

    int ocena = 0;

    if(state.reviews.isNotEmpty){
      ocena = state.reviews.first.score;
    }





 if (state.requests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Brak zgłoszeń',
        subtitle:
            'Dodaj zgłoszenie w zakładce „Dodaj" — firmy z okolicy je zobaczą.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.requests.length,
      itemBuilder: (context, index) =>
          _MyRequestTile(req: state.requests[index]),
    );












  }


}

// ──────────────────────────────────────────────────────────────────────────────
// Karta mojego zgłoszenia — wzór z dawnej zakładki w profilu:
// miniatura, kategoria/branża, edycja opisu, usuwanie, oferty firm.
// ──────────────────────────────────────────────────────────────────────────────
class _MyRequestTile extends StatefulWidget {
  final Request req;
  const _MyRequestTile({required this.req});

  @override
  State<_MyRequestTile> createState() => _MyRequestTileState();
}

class _MyRequestTileState extends State<_MyRequestTile> {
  bool _editing = false;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: widget.req.description);
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Globals.instance.selectedRequest = widget.req;
                    context.read<MainScreenBloc>().add(GoToShowRequestEvent());
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: widget.req.thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.req.thumbUrl,
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            height: 80,
                            color: Colors.grey.shade200,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(widget.req.category,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          if (widget.req.is24)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('24h',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      Text(widget.req.sector,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      if (widget.req.timestamp != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 12, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Text(_wystawione(widget.req.timestamp!),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      if (widget.req.city.isNotEmpty)
                        Text(widget.req.city,
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(_editing ? Icons.close : Icons.edit_outlined,
                          size: 20),
                      onPressed: () => setState(() => _editing = !_editing),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      onPressed: () => context
                          .read<ShowRequestsComponentBloc>()
                          .add(TryDeleteMyRequestShowRequestsComponentEvent(
                              id: widget.req.id)),
                    ),
                  ],
                ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              WInputField(
                controller: _desc,
                label: 'Opis zgłoszenia',
                isPassword: false,
                hintText: 'Wpisz opis',
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: WButton(
                  text: 'Zapisz',
                  onPressed: () async {
                    final newDesc = _desc.text.trim();
                    await context
                        .read<FirebaseService>()
                        .updateRequestDescription(widget.req.id, newDesc);
                    setState(() {
                      widget.req.description = newDesc;
                      _editing = false;
                    });
                    showToast(text: 'Zapisano');
                  },
                ),
              ),
            ] else if (widget.req.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.req.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (widget.req.status != 'closed')
              _RealizationRequest(request: widget.req),
            if (widget.req.status == 'closed')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                        widget.req.realizationStatus == 'rejected'
                            ? Icons.cancel_outlined
                            : Icons.task_alt,
                        size: 18,
                        color: widget.req.realizationStatus == 'rejected'
                            ? Colors.red.shade600
                            : Colors.green.shade700),
                    const SizedBox(width: 6),
                    Text(
                      widget.req.realizationStatus == 'rejected'
                          ? 'Zakończone — zdjęcia odrzucone'
                          : 'Zrealizowane i potwierdzone',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: widget.req.realizationStatus == 'rejected'
                              ? Colors.red.shade600
                              : Colors.green.shade700),
                    ),
                  ],
                ),
              )
            else ...[
              RequestOffersBar(request: widget.req),
            ],
          ],
        ),
      ),
    );
  }
}

String _wystawione(DateTime d) {
  final diff = DateTime.now().difference(d);
  final data =
      '${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  if (diff.inDays == 0) return 'wystawione dziś';
  if (diff.inDays == 1) return 'wystawione wczoraj';
  final left = 10 - diff.inDays;
  if (left <= 0) return 'wystawione $data · wygasa';
  return 'wystawione $data · wygasa za $left dni';
}

/// Zdjęcia realizacji na zgłoszeniu klienta: prośba firmy do potwierdzenia
/// oraz możliwość dodania własnych zdjęć.
class _RealizationRequest extends StatefulWidget {
  final Request request;
  const _RealizationRequest({required this.request});

  @override
  State<_RealizationRequest> createState() => _RealizationRequestState();
}

class _RealizationRequestState extends State<_RealizationRequest> {
  List<Map<String, dynamic>> _all = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context
          .read<FirebaseService>()
          .getRealizationsForRequest(widget.request.id);
      if (mounted) setState(() => _all = list);
    } catch (_) {}
  }

  Future<void> _decide(String id, String status) async {
    setState(() => _busy = true);
    try {
      await context
          .read<FirebaseService>()
          .setRealizationStatus(id, status, requestId: widget.request.id);
      showToast(
          text: status == 'approved'
              ? 'Potwierdzono — zgłoszenie zamknięte'
              : 'Odrzucono — zgłoszenie zamknięte');
      if (mounted) context.read<ShowRequestsComponentBloc>().add(GetDataShowRequestsComponentEvent());
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _all
        .where((r) =>
            r['addedByRole'] != 'user' && (r['status'] ?? 'pending') == 'pending')
        .toList();
    final mine = _all.where((r) => r['addedByRole'] == 'user').toList();
    final canAddOwn = widget.request.status == 'taken' && mine.isEmpty;

    if (pending.isEmpty && mine.isEmpty && !canAddOwn) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── firma prosi o potwierdzenie ──
          if (pending.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RealizationThumb(photo: pending.first, size: 54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${widget.request.takenByName.isNotEmpty ? widget.request.takenByName : 'Firma'} prosi o potwierdzenie realizacji. Potwierdzenie zamyka zgłoszenie.',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_busy)
                    const Center(child: CircularProgressIndicator())
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 15),
                          label: const Text('Odrzuć',
                              style: TextStyle(fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: () =>
                              _decide(pending.first['id'] as String, 'rejected'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          icon: const Icon(Icons.check, size: 15),
                          label: const Text('Potwierdź',
                              style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          onPressed: () =>
                              _decide(pending.first['id'] as String, 'approved'),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // ── moje zdjęcia z realizacji ──
          if (mine.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  RealizationThumb(photo: mine.first, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mine.first['publishedByCompany'] == true
                          ? 'Twoje zdjęcia są w portfolio firmy'
                          : 'Twoje zdjęcia wysłane — firma może je opublikować',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            )
          else if (canAddOwn)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label: const Text('Dodaj swoje zdjęcia z realizacji'),
                onPressed: () async {
                  final mode = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.add_a_photo_outlined),
                            title: const Text('Jedno zdjęcie'),
                            onTap: () => Navigator.pop(ctx, 'single'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.compare_outlined),
                            title: const Text('Para Przed / Po'),
                            onTap: () => Navigator.pop(ctx, 'pair'),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  );
                  if (mode == null || !context.mounted) return;
                  final ok = await pickAndAddRealization(context, widget.request,
                      mode: mode, addedByRole: 'user');
                  if (ok) _load();
                },
              ),
            ),
        ],
      ),
    );
  }
}
