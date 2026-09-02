import 'package:qb/shared/widgets/empty_state.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/domain_layer/chat_service.dart';
import 'package:qb/shared/widgets/before_after.dart';
import 'package:qb/shared/realizations.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/client_notes.dart';
import '../../../../../shared/globals.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/start_page_bloc.dart';

class MoiKlienciTab extends StatefulWidget {
  final StartPageState state;
  const MoiKlienciTab({super.key, required this.state});

  @override
  State<MoiKlienciTab> createState() => _MoiKlienciTabState();
}

class _MoiKlienciTabState extends State<MoiKlienciTab> {
  String _filter = 'all'; // all | new | active | rejected (toggle)
  double _maxKm = 0; // 0 = bez limitu

  @override
  Widget build(BuildContext context) {
    final statuses = widget.state.myOfferStatuses;

    final filtered = widget.state.requests.where((r) {
      if (_maxKm > 0 &&
          r.distance != null &&
          r.distance! / 1000 > _maxKm) {
        return false;
      }
      final s = statuses[r.id] ?? 'none';
      return switch (_filter) {
        'new' => s == 'none',
        'active' => s == 'pending' || s == 'maybe' || s == 'accepted',
        'rejected' => s == 'rejected',
        _ => true,
      };
    }).toList();

    Widget chip(String value, String label) {
      final selected = _filter == value;
      return ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        visualDensity: VisualDensity.compact,
        // ponowny klik zdejmuje filtr → widać wszystkie
        onSelected: (_) =>
            setState(() => _filter = selected ? 'all' : value),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              chip('new', 'Nowe'),
              const SizedBox(width: 8),
              chip('active', 'W trakcie'),
              const SizedBox(width: 8),
              chip('rejected', 'Odrzucone'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
              Expanded(
                child: Slider(
                  value: _maxKm,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: _maxKm == 0 ? 'bez limitu' : '${_maxKm.round()} km',
                  onChanged: (v) => setState(() => _maxKm = v),
                ),
              ),
              SizedBox(
                width: 62,
                child: Text(
                  _maxKm == 0 ? 'bez limitu' : 'do ${_maxKm.round()} km',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _RequestList(
            requests: filtered,
            isTrash: false,
            offerStatuses: statuses,
            clientNotes: widget.state.clientNotes,
          ),
        ),
      ],
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<Request> requests;
  final bool isTrash;
  final Map<String, String> offerStatuses;
  final Map<String, String> clientNotes;

  const _RequestList({
    required this.requests,
    required this.isTrash,
    this.offerStatuses = const {},
    this.clientNotes = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return EmptyState(
        icon: isTrash ? Icons.delete_outline : Icons.inbox_outlined,
        title: isTrash ? 'Kosz jest pusty' : 'Brak zgłoszeń',
        subtitle: isTrash
            ? null
            : 'Tu pojawią się zgłoszenia z Twojej kategorii i okolicy.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, index) => _RequestCard(
        request: requests[index],
        isTrash: isTrash,
        offerStatus: offerStatuses[requests[index].id] ?? 'none',
        note: clientNotes[requests[index].userId] ?? '',
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Request request;
  final bool isTrash;
  final String offerStatus; // none|pending|maybe|accepted|rejected
  final String note; // prywatna notatka firmy o kliencie

  const _RequestCard({
    required this.request,
    required this.isTrash,
    this.offerStatus = 'none',
    this.note = '',
  });

  Color? get _frameColor => switch (offerStatus) {
        'pending' || 'maybe' => Colors.amber,
        'accepted' => Colors.green,
        'rejected' => Colors.red,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final frame = _frameColor;
    final canOffer = offerStatus == 'none' && !isTrash;

    // ← w lewo: szybka oferta · → w prawo: ukryj
    return Dismissible(
      key: ValueKey('req_${request.id}'),
      direction: isTrash
          ? DismissDirection.none
          : (canOffer
              ? DismissDirection.horizontal
              : DismissDirection.startToEnd),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_off, color: Colors.white),
            SizedBox(width: 8),
            Text('Ukryj',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade500,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wyślij ofertę',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.local_offer, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          // szybka oferta — karta zostaje (zmieni się na żółtą)
          context
              .read<StartPageBloc>()
              .add(TryQuickOfferEvent(request.id));
          return false;
        }
        return true; // w prawo → ukryj
      },
      onDismissed: (_) => context
          .read<StartPageBloc>()
          .add(TryHideRequestEvent(request.id)),
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: frame == null
            ? BorderSide.none
            : BorderSide(color: frame, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Globals.instance.selectedRequest = request;
          context.read<MainScreenBloc>().add(GoToShowRequestEvent());
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _offerStatusChip(),
              _takeStatusBadge(context),
              Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Miniatura ───────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: request.thumbUrl.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: request.thumbUrl,
                      width: 80,
                      height: 130,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 80,
                      height: 130,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                  if (request.is24)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('24h',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // ── Treść ───────────────────────────────────────
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imię zgłaszającego (klik = notatka) + dystans
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _editNote(context),
                              child: _RequesterName(userId: request.userId),
                            ),
                          ),
                          if (request.distance != null)
                            Text(
                              '${(request.distance! / 1000).toStringAsFixed(1)} km',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                      // Karteczka z notatką tuż pod imieniem
                      if (note.isNotEmpty)
                        GestureDetector(
                          onTap: () => _editNote(context),
                          child: Container(
                            margin: const EdgeInsets.only(top: 2, bottom: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF6C7),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: const Color(0xFFE8D67A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sticky_note_2,
                                    size: 12, color: Color(0xFF8A6D1B)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(note,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B540F)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (request.city.isNotEmpty)
                        Text(request.city,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      if (request.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          request.description,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

              // ── Pasek akcji (zawsze na dole ramki) ──────────
              const SizedBox(height: 8),
              Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isTrash
                            ? Center(
                                child: TextButton.icon(
                                  icon: const Icon(
                                      Icons.restore_from_trash_outlined,
                                      size: 18),
                                  label: const Text('Przywróć'),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.green.shade700),
                                  onPressed: () => context
                                      .read<StartPageBloc>()
                                      .add(TryRestoreRequestEvent(request.id)),
                                ),
                              )
                            : Row(
                                children: [
                                  // Napisz
                                  Expanded(
                                    flex: 4,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cDarkBlue,
                                        side: const BorderSide(
                                            color: cDarkBlue),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 6),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                      onPressed: () =>
                                          context.read<MainScreenBloc>().add(
                                                GoToChatEvent(request.userId,
                                                    chatName:
                                                        _requesterNameCache[
                                                            request.userId]),
                                              ),
                                      child: const _BtnLabel(
                                          Icons.chat_bubble_outline, 'Napisz'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Wyślij ofertę / status oferty
                                  Expanded(
                                    flex: 6,
                                    child: _OfferButton(
                                      status: offerStatus,
                                      onSend: () => _sendOffer(context),
                                    ),
                                  ),
                                  // Reszta pod „⋯"
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_horiz,
                                        color: Colors.grey.shade700),
                                    padding: EdgeInsets.zero,
                                    onSelected: (v) async {
                                      switch (v) {
                                        case 'real_single':
                                        case 'real_pair':
                                          await pickAndAddRealization(
                                              context, request,
                                              mode: v == 'real_pair'
                                                  ? 'pair'
                                                  : 'single');
                                          if (context.mounted) {
                                            context
                                                .read<StartPageBloc>()
                                                .add(GetDataStartPageEvent());
                                          }
                                          break;
                                        case 'contact':
                                          context.read<StartPageBloc>().add(
                                              TryAddContactStartPageEvent(
                                                  request.userId));
                                          break;
                                        case 'profile':
                                          context.read<MainScreenBloc>().add(
                                              GoToProfilPublicznyUseraEvent(
                                                  request.userId));
                                          break;
                                        case 'hide':
                                          context.read<StartPageBloc>().add(
                                              TryHideRequestEvent(request.id));
                                          break;
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      if (offerStatus == 'accepted') ...const [
                                        PopupMenuItem(
                                            value: 'real_single',
                                            child: ListTile(
                                                dense: true,
                                                leading: Icon(
                                                    Icons.add_a_photo_outlined),
                                                title: Text(
                                                    'Dodaj zdjęcie realizacji'))),
                                        PopupMenuItem(
                                            value: 'real_pair',
                                            child: ListTile(
                                                dense: true,
                                                leading:
                                                    Icon(Icons.compare_outlined),
                                                title: Text(
                                                    'Dodaj parę Przed / Po'))),
                                        PopupMenuDivider(),
                                      ],
                                      const PopupMenuItem(
                                          value: 'profile',
                                          child: ListTile(
                                              dense: true,
                                              leading: Icon(Icons
                                                  .account_circle_outlined),
                                              title: Text('Profil klienta'))),
                                      const PopupMenuItem(
                                          value: 'contact',
                                          child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                  Icons.person_add_outlined),
                                              title:
                                                  Text('Dodaj do kontaktów'))),
                                      const PopupMenuItem(
                                          value: 'hide',
                                          child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                  Icons.visibility_off_outlined,
                                                  color: Colors.red),
                                              title: Text('Ukryj zgłoszenie',
                                                  style: TextStyle(
                                                      color: Colors.red)))),
                                    ],
                                  ),
                                ],
                              ),
                      ),
              // stan realizacji (zdjęcia dodaje się z menu „⋯")
              if (offerStatus == 'accepted' && !isTrash)
                _RealizationStatus(request: request),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Prywatna notatka o kliencie — widzi ją tylko firma.
  Future<void> _sendOffer(BuildContext context) async {
    final msg = await showOfferDialog(
        context, _requesterNameCache[request.userId] ?? '');
    if (msg == null || !context.mounted) return;
    context.read<StartPageBloc>().add(TryQuickOfferEvent(request.id, message: msg));
  }

  Future<void> _editNote(BuildContext context) async {
    final changed = await showClientNoteDialog(
        context, request.userId, _requesterNameCache[request.userId] ?? '');
    if (changed && context.mounted) {
      context.read<StartPageBloc>().add(GetDataStartPageEvent());
    }
    return;
    // ignore: dead_code
    final ctrl = TextEditingController(text: note);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notatka o kliencie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              maxLength: 200,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'np. spoko klient / odwołuje / płaci gotówką',
                border: OutlineInputBorder(),
              ),
            ),
            const Text('Widoczna tylko dla Ciebie.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Anuluj')),
          if (note.isNotEmpty)
            TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('Usuń',
                    style: TextStyle(color: Colors.red))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Zapisz')),
        ],
      ),
    );
    if (saved == null || !context.mounted) return;
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    await context.read<FirebaseService>().setClientNote(
          companyId: myId,
          userId: request.userId,
          note: saved,
        );
    if (context.mounted) {
      context.read<StartPageBloc>().add(GetDataStartPageEvent());
    }
  }

  /// Znacznik statusu MOJEJ oferty — od razu widać, czy odpowiedziano.
  Widget _offerStatusChip() {
    if (offerStatus == 'none') return const SizedBox.shrink();
    final (color, icon, text) = switch (offerStatus) {
      'accepted' => (Colors.green, Icons.check_circle, 'Klient zaakceptował Twoją ofertę'),
      'rejected' => (Colors.red, Icons.cancel, 'Klient odrzucił Twoją ofertę'),
      'maybe' => (Colors.orange, Icons.help, 'Klient się zastanawia'),
      _ => (Colors.amber, Icons.mark_email_read_outlined, 'Oferta wysłana — czeka na decyzję'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _takeStatusBadge(BuildContext context) {
    if (request.takenBy.isEmpty) return const SizedBox.shrink();
    final myId = context.read<MainScreenBloc>().state.user?.id ?? '';
    final mine = request.takenBy == myId;

    late final Color color;
    late final String text;
    if (mine && request.status == 'taken') {
      color = Colors.green;
      text = 'W realizacji przez Ciebie';
    } else if (mine) {
      color = Colors.orange;
      text = 'Podjęte przez Ciebie — czeka na potwierdzenie klienta';
    } else {
      color = Colors.grey;
      text = 'Podjęte przez: ${request.takenByName}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

// Imię i nazwisko zgłaszającego (cache w pamięci — bez mielenia Firestore)
final Map<String, String> _requesterNameCache = {};

class _RequesterName extends StatelessWidget {
  final String userId;
  const _RequesterName({required this.userId});

  @override
  Widget build(BuildContext context) {
    final cached = _requesterNameCache[userId];
    if (cached != null) {
      return Text(cached,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }
    return FutureBuilder(
      future: context.read<FirebaseService>().fetchUser(userId),
      builder: (context, snap) {
        final u = snap.data;
        final name = u == null
            ? ''
            : '${u.firstName ?? ''} ${u.lastName ?? ''}'.trim();
        if (name.isNotEmpty) _requesterNameCache[userId] = name;
        return Text(name.isEmpty ? 'Zgłoszenie' : name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis);
      },
    );
  }
}

/// Etykieta przycisku: ikona + tekst, który się przycina zamiast wychodzić
/// poza obrys (domyślne Button.icon tego nie robi).
class _BtnLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BtnLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 17),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Stan realizacji na karcie firmy: prośba wysłana / potwierdzona / odrzucona.
class _RealizationStatus extends StatefulWidget {
  final Request request;
  const _RealizationStatus({required this.request});

  @override
  State<_RealizationStatus> createState() => _RealizationStatusState();
}

class _RealizationStatusState extends State<_RealizationStatus> {
  Map<String, dynamic>? _real;
  bool _loaded = false;

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
      final mine = list.where((r) => r['addedByRole'] != 'user').toList();
      if (mounted) {
        setState(() {
          _real = mine.isEmpty ? null : mine.first;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _remind() async {
    try {
      await context.read<ChatService>().sendMessage(
            widget.request.userId,
            'Dzień dobry! Dodałem zdjęcia z realizacji Twojego zgłoszenia (${widget.request.sector}). Proszę o potwierdzenie w aplikacji — zakładka Zgłoszenia.',
          );
      showToast(text: 'Wysłano przypomnienie na czacie');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _real == null) return const SizedBox.shrink();
    final status = (_real!['status'] as String?) ?? 'pending';
    final (color, icon, text) = switch (status) {
      'approved' => (Colors.green.shade700, Icons.verified,
          'Realizacja potwierdzona przez klienta'),
      'rejected' => (Colors.red.shade700, Icons.cancel_outlined,
          'Klient odrzucił zdjęcia realizacji'),
      _ => (Colors.amber.shade900, Icons.hourglass_top,
          'Wysłano prośbę o akceptację realizacji'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            RealizationThumb(photo: _real!, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
            if (status == 'pending')
              TextButton(
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: color),
                onPressed: _remind,
                child: const Text('Przypomnij'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Przycisk oferty: aktywny gdy jeszcze nie odpowiedziano, inaczej status.
class _OfferButton extends StatelessWidget {
  final String status;
  final VoidCallback onSend;
  const _OfferButton({required this.status, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const pad = EdgeInsets.symmetric(vertical: 10, horizontal: 6);

    Widget tonal(Color bg, Color fg, IconData icon, String text) =>
        FilledButton.tonal(
          style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              disabledBackgroundColor: bg,
              disabledForegroundColor: fg,
              padding: pad,
              shape: shape),
          onPressed: null,
          child: _BtnLabel(icon, text),
        );

    switch (status) {
      case 'pending':
        return tonal(Colors.amber.shade100, Colors.amber.shade900,
            Icons.hourglass_top, 'Oferta wysłana');
      case 'maybe':
        return tonal(Colors.amber.shade100, Colors.amber.shade900,
            Icons.help_outline, 'Zastanawia się');
      case 'accepted':
        return tonal(Colors.green.shade600, Colors.white, Icons.check_circle,
            'Zaakceptowana');
      case 'rejected':
        return tonal(Colors.red.shade50, Colors.red.shade700,
            Icons.cancel_outlined, 'Odrzucona');
      default:
        return FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: cDarkBlue,
              foregroundColor: Colors.white,
              padding: pad,
              shape: shape),
          onPressed: onSend,
          child: const _BtnLabel(Icons.local_offer_outlined, 'Wyślij ofertę'),
        );
    }
  }
}

/// Dialog oferty: gotowa treść do edycji (cena, termin) + Wyślij.
Future<String?> showOfferDialog(BuildContext context, String clientName) {
  final ctrl = TextEditingController(text: kDefaultOfferMessage);
  return showDialog<String>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_outlined, color: cDarkBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      clientName.isEmpty ? 'Oferta' : 'Oferta dla: $clientName',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 7,
              minLines: 5,
              maxLength: 400,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Co oferujesz, cena, termin…',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
                'Klient zobaczy ofertę przy swoim zgłoszeniu i zdecyduje ✔ / ? / ✖.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Anuluj'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: cDarkBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Wyślij ofertę',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
        ),
      ),
    );
  }
}