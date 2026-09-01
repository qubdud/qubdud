import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain_layer/domain_models/promoVideo.dart';
import '../../domain_layer/firebase_service.dart';
import '../functions/show_toast.dart';
import '../functions/show_toast_error.dart';

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
  final _message = TextEditingController();
  Map<String, dynamic>? _myOffer;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context
        .read<FirebaseService>()
        .getMyOffer(widget.request.id, widget.myCompanyId)
        .then((o) {
      if (mounted) setState(() { _myOffer = o; _loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      showToastError(text: 'Napisz treść oferty');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().sendOffer(
            requestId: widget.request.id,
            companyId: widget.myCompanyId,
            companyName: widget.myCompanyName,
            message: text,
          );
      setState(() => _myOffer = {
            'companyId': widget.myCompanyId,
            'message': text,
            'status': 'pending',
          });
      showToast(text: 'Oferta wysłana');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
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

    if (_myOffer == null) {
      // brak oferty — formularz
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _message,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Twoja oferta — np. cena, termin, jak możesz pomóc…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 8),
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
          text: 'Klient zaakceptował Twoją ofertę — realizujesz to zadanie',
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

  const RequestOffersBar({super.key, required this.request, this.onChanged});

  @override
  State<RequestOffersBar> createState() => _RequestOffersBarState();
}

class _RequestOffersBarState extends State<RequestOffersBar> {
  List<Map<String, dynamic>> _offers = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final offers =
          await context.read<FirebaseService>().getOffers(widget.request.id);
      if (mounted) setState(() => _offers = offers);
    } catch (_) {}
  }

  Future<void> _setStatus(Map<String, dynamic> offer, String status) async {
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().setOfferStatus(
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
      widget.onChanged?.call();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _unlock() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odblokować zgłoszenie?'),
        content: const Text(
            'Zgłoszenie wróci do puli i znów zobaczą je inne firmy.'),
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
      await _load();
      widget.onChanged?.call();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
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
              child: Text('W realizacji: ${req.takenByName}',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
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

    final visible =
        _offers.where((o) => o['status'] != 'rejected').toList();
    if (visible.isEmpty) return const SizedBox.shrink();

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
          ...visible.map((o) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(o['companyName'] ?? 'Firma',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (o['status'] == 'maybe') ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.help_outline,
                                    size: 13, color: Colors.orange),
                              ],
                            ],
                          ),
                          if ((o['message'] ?? '').toString().isNotEmpty)
                            Text(o['message'],
                                style: const TextStyle(fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis),
                        ],
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
              )),
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
