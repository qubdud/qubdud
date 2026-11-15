import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/functions/plural.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/widgets/before_after.dart';
import 'package:qb/shared/realizations.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';


import '../../../../../../../shared/globals.dart';
import '../../../../../../../shared/widgets/loading.dart';
import '../../../../../../../shared/widgets/request_take_status.dart';
import '../../../../../../../shared/widgets/w_button.dart';
import '../../../../../../../shared/widgets/w_input_field.dart';
import '../../../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../../../shared/widgets/load_error.dart';
import '../bloc/show_requests_bloc.dart';
import '../../../../../../../shared/request_questions.dart';


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
            width: double.infinity,
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

    if (state is ShowRequestsComponentErrorState) {
      return LoadError(
        key: const ValueKey('error'),
        message: 'Nie udało się wczytać zgłoszeń.',
        onRetry: () => context
            .read<ShowRequestsComponentBloc>()
            .add(GetDataShowRequestsComponentEvent()),
      );
    }

    if (state.requests.isEmpty) {
      return const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Brak zgłoszeń',
        subtitle:
            'Użyj przycisku powyżej — firmy z okolicy zobaczą Twoje zgłoszenie i przyślą oferty.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: state.requests.length,
      itemBuilder: (context, index) => _MyRequestTile(
          key: ValueKey(state.requests[index].id),
          req: state.requests[index]),
    );












  }


}

// ──────────────────────────────────────────────────────────────────────────────
// Karta mojego zgłoszenia — wzór z dawnej zakładki w profilu:
// miniatura, kategoria/branża, edycja opisu, usuwanie, oferty firm.
// ──────────────────────────────────────────────────────────────────────────────
class _MyRequestTile extends StatefulWidget {
  final Request req;
  const _MyRequestTile({super.key, required this.req});

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
  void didUpdateWidget(covariant _MyRequestTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.req.id != widget.req.id) {
      _desc.text = widget.req.description;
      _editing = false;
    }
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  void _reload() => context
      .read<ShowRequestsComponentBloc>()
      .add(GetDataShowRequestsComponentEvent());

  Future<void> _close() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zamknąć zgłoszenie?'),
        content: const Text(
            'Zniknie z list firm i nikt nie wyśle już oferty. Zostanie u Ciebie jako zakończone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Zamknij')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<FirebaseService>().closeRequest(widget.req.id);
      showToast(text: 'Zgłoszenie zamknięte');
      if (mounted) _reload();
    } catch (_) {
      showToastError(text: 'Nie udało się zamknąć zgłoszenia');
    }
  }

  Future<void> _delete() async {
    final req = widget.req;
    final company = req.takenByName.isNotEmpty ? req.takenByName : 'Firma';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć zgłoszenie?'),
        content: Text(req.status == 'taken'
            ? '$company realizuje to zgłoszenie — zostanie powiadomiona o usunięciu. Tego nie można cofnąć.'
            : 'Zgłoszenie i oferty firm znikną. Tego nie można cofnąć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usuń', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    context
        .read<ShowRequestsComponentBloc>()
        .add(TryDeleteMyRequestShowRequestsComponentEvent(id: req.id));
  }

  Future<void> _saveDescription() async {
    final newDesc = _desc.text.trim();
    if (widget.req.fileUrl.isEmpty && newDesc.length < 10) {
      showToastError(text: 'Zgłoszenie bez zdjęcia potrzebuje opisu (min. 10 znaków)');
      return;
    }
    try {
      await context
          .read<FirebaseService>()
          .updateRequestDescription(widget.req.id, newDesc);
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać opisu');
      return;
    }
    if (!mounted) return;
    setState(() {
      widget.req.description = newDesc;
      _editing = false;
    });
    showToast(text: 'Zapisano');
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
                                const Icon(Icons.description_outlined),
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
                              Text(_wystawione(widget.req),
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
                    if (widget.req.status != 'closed')
                      IconButton(
                        icon: Icon(Icons.lock_outline,
                            size: 20, color: Colors.grey.shade600),
                        tooltip: 'Zamknij zgłoszenie',
                        onPressed: _close,
                      ),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        tooltip: 'Usuń zgłoszenie',
                        onPressed: _delete,
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
                  onPressed: _saveDescription,
                ),
              ),
            ] else if (widget.req.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.req.description,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (requestBriefLabel(timing: widget.req.timing, budget: widget.req.budget,
                    answers: widget.req.answers).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    requestBriefLabel(timing: widget.req.timing, budget: widget.req.budget,
                        answers: widget.req.answers),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            if (widget.req.status == 'closed')
              _ClosedLabel(stage: widget.req.stage)
            else ...[
              _RealizationRequest(request: widget.req),
              RequestOffersBar(
                  request: widget.req,
                  onChanged: _reload,
                  onEditDescription: () => setState(() => _editing = true)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wygasają tylko otwarte zgłoszenia (cron po 10 dniach).
String _wystawione(Request req) {
  final d = req.timestamp!;
  final diff = DateTime.now().difference(d);
  if (diff.inDays == 0) return 'wystawione dziś';
  if (diff.inDays == 1) return 'wystawione wczoraj';
  final data = 'wystawione ${d.day}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  if (req.status != 'open') return data;
  final left = 10 - diff.inDays;
  if (left <= 0) return '$data · wygasa';
  return '$data · wygasa za $left ${plural(left, 'dzień', 'dni', 'dni')}';
}

class _ClosedLabel extends StatelessWidget {
  final RequestStage stage;
  const _ClosedLabel({required this.stage});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (stage) {
      RequestStage.realized => (Icons.task_alt, Colors.green.shade700),
      RequestStage.expired => (Icons.timer_off_outlined, Colors.grey.shade600),
      _ => (Icons.lock_outline, Colors.grey.shade600),
    };
    final label = stage.label();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '${label[0].toUpperCase()}${label.substring(1)}',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
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

  @override
  void didUpdateWidget(covariant _RealizationRequest oldWidget) {
    super.didUpdateWidget(oldWidget);
    // świeży obiekt po przeładowaniu listy = mogły się zmienić zdjęcia
    if (oldWidget.request != widget.request) {
      if (oldWidget.request.id != widget.request.id) _all = const [];
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.request.id;
    try {
      final list =
          await context.read<FirebaseService>().getRealizationsForRequest(id);
      if (mounted && id == widget.request.id) setState(() => _all = list);
    } catch (_) {}
  }

  Future<void> _decide(String status) async {
    final approve = status == 'approved';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Potwierdzasz wykonanie?' : 'To nie Twoje zdjęcia?'),
        content: Text(approve
            ? 'Zdjęcia pojawią się na profilu firmy, a zgłoszenie zostanie zamknięte jako zrealizowane.'
            : 'Firma dostanie informację i będzie mogła dodać właściwe zdjęcia.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor:
                      approve ? Colors.green.shade600 : Colors.red.shade600),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(approve ? 'Potwierdzam' : 'Odrzuć')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context
          .read<FirebaseService>()
          .setRealizationStatus(widget.request.id, status);
      showToast(
          text: approve
              ? 'Potwierdzone — zdjęcia są już na profilu firmy'
              : 'Odrzucono — firma może dodać inne zdjęcia');
      if (mounted) {
        context
            .read<ShowRequestsComponentBloc>()
            .add(GetDataShowRequestsComponentEvent());
      }
    } on StateError catch (e) {
      showToastError(text: e.message);
      await _load();
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać decyzji');
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
                        TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              visualDensity: VisualDensity.compact),
                          onPressed: () => _decide('rejected'),
                          child: const Text('To nie moje',
                              style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 6),
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
                          onPressed: () => _decide('approved'),
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
