import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain_layer/domain_models/app_user.dart';
import '../../domain_layer/domain_models/promoVideo.dart';
import '../../domain_layer/firebase_service.dart';
import '../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../functions/plural.dart';
import '../functions/show_toast.dart';
import '../functions/show_toast_error.dart';
import '../moderation.dart';
import 'offer_dialog.dart';

/// Sekcja dla FIRMY na widoku zgłoszenia: napisz ofertę / status decyzji.
class CompanyOfferSection extends StatefulWidget {
  final Request request;
  final String myCompanyId;
  final String myCompanyName;

  const CompanyOfferSection({
    super.key,
    required this.request,
    required this.myCompanyId,
    required this.myCompanyName,
  });

  @override
  State<CompanyOfferSection> createState() => _CompanyOfferSectionState();
}

class _CompanyOfferSectionState extends State<CompanyOfferSection> {
  Map<String, dynamic>? _myOffer;
  bool _loading = true;
  bool _busy = false;
  StreamSubscription<Map<String, dynamic>?>? _sub;

  @override
  void initState() {
    super.initState();
    // decyzja klienta (przyjęcie, odrzucenie) widoczna od razu na otwartym ekranie
    _sub = context
        .read<FirebaseService>()
        .myOfferStream(widget.request.id, widget.myCompanyId)
        .listen((o) {
      if (mounted) setState(() { _myOffer = o; _loading = false; });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _send() async {
    final draft = await showOfferDialog(context, '');
    if (draft == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().sendOffer(
            requestId: widget.request.id,
            companyId: widget.myCompanyId,
            companyName: widget.myCompanyName,
            message: draft.message,
            price: draft.price,
            priceTo: draft.priceTo,
            when: draft.when,
          );
      if (!mounted) return;
      setState(() => _myOffer = {
            'companyId': widget.myCompanyId,
            'message': draft.message,
            'status': 'pending',
          });
      showToast(text: 'Oferta wysłana');
    } catch (_) {
      showToastError(text: 'Nie udało się wysłać oferty');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    if (_loading || _busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // zadanie zablokowane na inną firmę
    if (req.status == 'taken' && req.takenBy != widget.myCompanyId) {
      return _badge(
        color: Colors.grey,
        icon: Icons.lock_outline,
        text: 'Zadanie realizuje firma ${req.takenByName}',
      );
    }

    final status = _myOffer?['status'] as String?;

    if (req.status == 'closed' && status != 'accepted') {
      return _badge(
        color: Colors.grey,
        icon: Icons.lock_outline,
        text: 'Zgłoszenie jest zamknięte',
      );
    }

    if (_myOffer == null) {
      // brak oferty — dialog z treścią, ceną i terminem
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.local_offer_outlined, size: 18),
            label: const Text('Wyślij ofertę'),
            onPressed: _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      );
    }

    switch (status) {
      case 'accepted':
        return _badge(
          color: Colors.green,
          icon: Icons.check_circle_outline,
          text: req.realizationStatus == 'approved'
              ? 'Klient potwierdził wykonanie — zlecenie zakończone'
              : 'Klient zaakceptował Twoją ofertę — realizujesz to zadanie',
        );
      case 'maybe':
        return _badge(
          color: Colors.orange,
          icon: Icons.help_outline,
          text: 'Klient się zastanawia nad Twoją ofertą',
        );
      case 'rejected':
        return _badge(
          color: Colors.red,
          icon: Icons.cancel_outlined,
          text: 'Klient odrzucił Twoją ofertę',
        );
      case 'closed':
        return _badge(
          color: Colors.grey,
          icon: Icons.block,
          text: 'Klient wybrał inną ofertę',
        );
      default:
        return _badge(
          color: Colors.blueGrey,
          icon: Icons.hourglass_top_outlined,
          text: 'Oferta wysłana — czeka na decyzję klienta',
        );
    }
  }

  Widget _badge(
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }
}

/// Pasek dla USERA pod jego zgłoszeniem: lista ofert z ✔ / ? / ✖,
/// a po akceptacji status realizacji + „Odblokuj".
class RequestOffersBar extends StatefulWidget {
  final Request request;
  final VoidCallback? onChanged;
  final VoidCallback? onEditDescription;

  const RequestOffersBar(
      {super.key, required this.request, this.onChanged, this.onEditDescription});

  @override
  State<RequestOffersBar> createState() => _RequestOffersBarState();
}

typedef _CompanyStats = ({double rating, int reviews, int jobs, double? km, int? sinceYear});

class _RequestOffersBarState extends State<RequestOffersBar> {
  List<Map<String, dynamic>> _offers = [];
  bool _offersLoaded = false;
  bool _busy = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  final Map<String, _CompanyStats?> _companies = {};

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant RequestOffersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _offers = [];
      _offersLoaded = false;
      _companies.clear();
      _listen();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _listen() {
    _sub?.cancel();
    final id = widget.request.id;
    _sub = context.read<FirebaseService>().offersStream(id).listen((offers) {
      if (mounted && id == widget.request.id) {
        setState(() {
          _offers = offers;
          _offersLoaded = true;
        });
        for (final o in offers) {
          _loadCompany((o['companyId'] ?? '').toString());
        }
      }
    }, onError: (_) {});
  }

  Future<void> _loadCompany(String companyId) async {
    if (companyId.isEmpty || _companies.containsKey(companyId)) return;
    _companies[companyId] = null;
    final firebase = context.read<FirebaseService>();
    try {
      final r = await Future.wait([
        firebase.fetchUser(companyId),
        firebase.getReviewsMetadataByReviewedUser(companyId),
        firebase.getCompletedJobsCount(companyId).catchError((_) => 0),
      ]);
      final company = r[0] as AppUser?;
      final reviews = r[1] as List<Review>;
      final jobs = r[2] as int;
      final from = widget.request.location;
      final to = company?.companyLocation;
      final km = to != null &&
              (to.latitude != 0 || to.longitude != 0) &&
              (from.latitude != 0 || from.longitude != 0)
          ? Geolocator.distanceBetween(
                  from.latitude, from.longitude, to.latitude, to.longitude) /
              1000
          : null;
      if (!mounted) return;
      if (company == null) return;
      setState(() => _companies[companyId] = (
            rating: reviews.isEmpty
                ? 0
                : reviews.map((e) => e.score).reduce((a, b) => a + b) / reviews.length,
            reviews: reviews.length,
            jobs: jobs,
            km: km,
            sinceYear: company.createdAt?.year,
          ));
    } catch (_) {
      _companies.remove(companyId);
    }
  }

  Future<bool> _confirm(Map<String, dynamic> offer, String status) async {
    final name = (offer['companyName'] ?? 'Firma').toString();
    final accept = status == 'accepted';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept ? 'Przyjąć ofertę firmy $name?' : 'Odrzucić ofertę firmy $name?'),
        content: Text(accept
            ? 'Firma dostanie powiadomienie i zobaczy Twój telefon, e-mail i dokładne miejsce, żeby się z Tobą skontaktować. '
                'Zgłoszenie zniknie z listy innych firm, a ich oferty zostaną zamknięte. '
                'Zgłoszenie możesz później odblokować.'
            : 'Firma dostanie powiadomienie, że jej oferta została odrzucona.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(accept ? 'Przyjmij' : 'Odrzuć',
                  style: TextStyle(color: accept ? Colors.green : Colors.red))),
        ],
      ),
    );
    return ok == true && mounted;
  }

  Future<void> _setStatus(Map<String, dynamic> offer, String status) async {
    final firebase = context.read<FirebaseService>();
    if (status != 'maybe' && !await _confirm(offer, status)) return;
    setState(() => _busy = true);
    try {
      await firebase.setOfferStatus(
            request: widget.request,
            companyId: offer['companyId'] ?? '',
            companyName: offer['companyName'] ?? 'Firma',
            status: status,
          );
      offer['status'] = status;
      if (status == 'accepted') {
        widget.request.status = 'taken';
        widget.request.takenBy = offer['companyId'] ?? '';
        widget.request.takenByName = offer['companyName'] ?? '';
        showToast(text: 'Zaakceptowano — zadanie zablokowane dla tej firmy');
      }
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać decyzji');
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) widget.onChanged?.call();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _unlock() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odblokować zgłoszenie?'),
        content: const Text(
            'Zgłoszenie wróci do puli i znów zobaczą je inne firmy. '
            'Zdjęcia realizacji tej firmy zostaną usunięte.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Odblokuj')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().unlockRequest(widget.request);
      widget.request.status = 'open';
      widget.request.takenBy = '';
      widget.request.takenByName = '';
      showToast(text: 'Odblokowano — zgłoszenie wróciło do puli');
    } catch (_) {
      showToastError(text: 'Nie udało się odblokować zgłoszenia');
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) widget.onChanged?.call();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    if (_busy) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // zaakceptowane — w realizacji
    if (req.status == 'taken') {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 15, color: Colors.green),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => context
                    .read<MainScreenBloc>()
                    .add(GoToProfilPublicznyFirmyEvent(req.takenBy)),
                child: Text('W realizacji: ${req.takenByName}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        decoration: TextDecoration.underline)),
              ),
            ),
            TextButton(
              onPressed: _unlock,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Odblokuj',
                  style: TextStyle(fontSize: 12, color: Colors.red)),
            ),
          ],
        ),
      );
    }

    // oferty od zablokowanych firm znikają (nie da się ich przyjąć)
    final visible = _offers
        .where((o) =>
            o['status'] != 'rejected' &&
            o['status'] != 'closed' &&
            !BlockedUsers.contains(o['companyId'] as String?))
        .toList();
    if (visible.isEmpty) return _noOffersHint(req);
    final prices = visible.map((o) => o['price']).whereType<int>().toList();
    final cheapest = prices.length > 1 ? prices.reduce((a, b) => a < b ? a : b) : null;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Oferty (${visible.length}):',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          ...visible.map((o) {
            // „?" = zastanawiam się → cała oferta na żółto
            final isMaybe = o['status'] == 'maybe';
            final maybeColor = Colors.amber.shade800;
            return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // tap w nazwę/treść = szybki podgląd profilu firmy
                      child: GestureDetector(
                        onTap: () => context.read<MainScreenBloc>().add(
                            GoToProfilPublicznyFirmyEvent(
                                o['companyId'] ?? '')),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storefront_outlined,
                                    size: 13,
                                    color: isMaybe
                                        ? maybeColor
                                        : Colors.blueGrey),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(o['companyName'] ?? 'Firma',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isMaybe ? maybeColor : null,
                                          decoration:
                                              TextDecoration.underline),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            if (_companies[o['companyId']] case final s?)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (s.reviews > 0) ...[
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: Colors.amber),
                                      Text(
                                          '${s.rating.toStringAsFixed(1).replaceAll('.', ',')} '
                                          '(${s.reviews} ${plural(s.reviews, 'opinia', 'opinie', 'opinii')})',
                                          style: const TextStyle(fontSize: 11)),
                                    ] else
                                      const Text('Bez opinii',
                                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (s.jobs > 0)
                                      Text('· ${s.jobs} ${plural(s.jobs, 'zlecenie', 'zlecenia', 'zleceń')}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (s.km != null)
                                      Text('· ${s.km! < 10 ? s.km!.toStringAsFixed(1).replaceAll('.', ',') : s.km!.round()} km',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (s.sinceYear != null)
                                      Text('· w QUBDUD od ${s.sinceYear}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            if (offerPriceLabel(o) != null || kOfferWhen[o['when']] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Wrap(
                                  spacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (offerPriceLabel(o) != null)
                                      Text(offerPriceLabel(o)!,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800)),
                                    if (cheapest != null && o['price'] == cheapest)
                                      const Text('najtańsza',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.w700)),
                                    if (kOfferWhen[o['when']] != null)
                                      Text('· ${kOfferWhen[o['when']]}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            if ((o['message'] ?? '').toString().isNotEmpty)
                              Text(o['message'],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isMaybe ? maybeColor : null),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    _decisionBtn(Icons.check, Colors.green,
                        () => _setStatus(o, 'accepted')),
                    _decisionBtn(Icons.question_mark, Colors.orange,
                        () => _setStatus(o, 'maybe')),
                    _decisionBtn(Icons.close, Colors.red,
                        () => _setStatus(o, 'rejected')),
                  ],
                ),
              );
          }),
        ],
      ),
    );
  }

  Widget _noOffersHint(Request req) {
    final ts = req.timestamp;
    if (!_offersLoaded || _offers.isNotEmpty || req.status != 'open' || ts == null ||
        DateTime.now().difference(ts) < const Duration(hours: 3)) {
      return const SizedBox.shrink();
    }
    final shortDesc = req.description.trim().length < 40;
    final tips = [
      if (shortDesc)
        'Dopisz w opisie szczegóły: co dokładnie, wymiary, stan, na kiedy i za ile mniej więcej.',
      if (req.fileUrl.isEmpty)
        'Zgłoszenia ze zdjęciem dostają więcej ofert — możesz dodać nowe ze zdjęciem.',
    ];
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
              SizedBox(width: 6),
              Expanded(
                child: Text('Jeszcze brak ofert',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              tips.isEmpty
                  ? 'Firmy z okolicy widzą Twoje zgłoszenie. Czasem odpowiedź przychodzi następnego dnia.'
                  : 'Firmy chętniej odpowiadają na konkretne zgłoszenia:',
              style: const TextStyle(fontSize: 12)),
          for (final t in tips)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $t', style: const TextStyle(fontSize: 12)),
            ),
          if (widget.onEditDescription != null && shortDesc)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onEditDescription,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Uzupełnij opis'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _decisionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
