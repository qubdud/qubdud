import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/widgets/before_after.dart';

import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/realizations.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';

/// Sekcja „Zdjęcia realizacji" na widoku zgłoszenia — widoczna po
/// obustronnym potwierdzeniu zadania:
/// - firma realizująca dodaje zdjęcia (jedna realizacja; odrzuconą zastępuje),
/// - właściciel zgłoszenia potwierdza/odrzuca je albo prosi o zdjęcia na czacie,
/// - zdjęcia dodane przez klienta są pokazywane osobno.
class RealizationSection extends StatefulWidget {
  final Request request;

  const RealizationSection({super.key, required this.request});

  @override
  State<RealizationSection> createState() => _RealizationSectionState();
}

class _RealizationSectionState extends State<RealizationSection> {
  List<Map<String, dynamic>> _photos = [];
  bool _busy = false;
  late String _jobStatus = widget.request.realizationStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RealizationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _photos = [];
      _jobStatus = widget.request.realizationStatus;
      _load();
    } else if (oldWidget.request.realizationStatus !=
        widget.request.realizationStatus) {
      // zmiana na żywo (nasłuch zgłoszenia): druga strona dodała/wycofała zdjęcia lub zdecydowała
      _jobStatus = widget.request.realizationStatus;
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.request.id;
    try {
      final photos =
          await context.read<FirebaseService>().getRealizationsForRequest(id);
      if (mounted && id == widget.request.id) setState(() => _photos = photos);
    } catch (_) {}
  }

  Future<void> _addPhoto({bool withBefore = false}) async {
    setState(() => _busy = true);
    final ok = await pickAndAddRealization(context, widget.request,
        mode: withBefore ? 'pair' : 'single');
    if (ok) await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _askForPhotos() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<ChatService>().sendMessage(
            widget.request.takenBy,
            'Dzień dobry, czy mogę prosić o zdjęcia z realizacji mojego zgłoszenia (${widget.request.category})?',
          );
    } catch (_) {
      showToastError(text: 'Nie udało się wysłać wiadomości');
      if (mounted) setState(() => _busy = false);
      return;
    }
    // _busy zostaje do przejścia na czat — ekran znika z opóźnieniem animacji
    if (!mounted) return;
    context
        .read<MainScreenBloc>()
        .add(GoToChatEvent(widget.request.takenBy, chatName: widget.request.takenByName));
  }

  Future<void> _decide(String status) async {
    setState(() => _busy = true);
    try {
      await context
          .read<FirebaseService>()
          .setRealizationStatus(widget.request.id, status);
      final withPhotos = _photos.any((r) => r['addedByRole'] != 'user');
      showToast(
          text: status == 'approved'
              ? (withPhotos
                  ? 'Potwierdzono — zlecenie zamknięte, zdjęcia trafią na profil firmy'
                  : 'Potwierdzono — zlecenie zamknięte')
              : (withPhotos
                  ? 'Odrzucono — firma może dodać inne zdjęcia'
                  : 'Firma dostanie informację, że zlecenie nie jest skończone'));
      if (mounted) setState(() => _jobStatus = status);
      await _load();
    } on StateError catch (e) {
      // firma cofnęła prośbę — nic już nie czeka na decyzję
      showToastError(text: e.message);
      if (mounted) setState(() => _jobStatus = '');
      await _load();
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać decyzji');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _markDone(bool done) async {
    if (done) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Zlecenie wykonane?'),
          content: const Text(
              'Klient dostanie prośbę o potwierdzenie. Po potwierdzeniu zlecenie się zamknie i klient będzie mógł wystawić opinię.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Wykonane')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().markJobDone(widget.request.id, done: done);
      if (mounted) setState(() => _jobStatus = done ? 'pending' : '');
    } catch (_) {
      showToastError(text: 'Nie udało się zapisać');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _withdraw(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć zdjęcia realizacji?'),
        content: const Text('Będziesz mógł dodać nowe.'),
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
    setState(() => _busy = true);
    try {
      await context
          .read<FirebaseService>()
          .withdrawRealization(id, widget.request.id);
      if (mounted) setState(() => _jobStatus = '');
      await _load();
    } catch (_) {
      showToastError(text: 'Nie udało się usunąć zdjęć');
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _statusChip(String status) {
    final (color, icon, text) = switch (status) {
      'approved' => (Colors.green.shade700, Icons.check_circle, 'Potwierdzone przez klienta'),
      'rejected' => (Colors.red.shade700, Icons.cancel, 'Odrzucone przez klienta'),
      _ => (Colors.amber.shade800, Icons.hourglass_top, 'Czeka na potwierdzenie klienta'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<MainScreenBloc>().state.user;
    final req = widget.request;
    // po potwierdzeniu zgłoszenie jest zamknięte — wynik zostaje, akcje znikają
    final active = req.status == 'taken';
    if ((!active && req.realizationStatus != 'approved') || me == null) {
      return const SizedBox.shrink();
    }

    final isRealizingCompany = me.id == req.takenBy;
    final isOwner = me.id == req.userId;
    // zdjęcia firmy i klienta osobno; lista jest od najnowszych
    final companyPhotos =
        _photos.where((r) => r['addedByRole'] != 'user').toList();
    final clientPhotos =
        _photos.where((r) => r['addedByRole'] == 'user').toList();
    final existing = companyPhotos.isNotEmpty ? companyPhotos.first : null;
    final status = (existing?['status'] as String?) ?? 'approved';

    // osoby postronne widzą tylko potwierdzone
    if (!isRealizingCompany && !isOwner && (existing == null || status != 'approved')) {
      return const SizedBox.shrink();
    }

    // zlecenie zakończone bez zdjęć, czeka na klienta
    final noPhotoPending = existing == null && _jobStatus == 'pending';
    final canAdd = isRealizingCompany &&
        !noPhotoPending &&
        (existing == null || status == 'rejected');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        WSmallLabel(text: 'Zdjęcia realizacji'),
        const SizedBox(height: 8),
        if (existing == null && _jobStatus == 'approved')
          Center(child: _statusChip('approved'))
        else if (noPhotoPending)
          Center(child: _statusChip('pending'))
        else if (existing == null)
          Text(
            isRealizingCompany
                ? (_jobStatus == 'rejected'
                    ? 'Klient nie potwierdził wykonania — ustalcie szczegóły na czacie.'
                    : 'Pochwal się wykonaną pracą — dodaj zdjęcie lub parę Przed/Po. Po potwierdzeniu przez klienta trafi do galerii „Realizacje" na Twoim profilu.')
                : 'Firma nie dodała jeszcze zdjęć realizacji.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          )
        else ...[
          Center(child: RealizationThumb(photo: existing, size: 140)),
          const SizedBox(height: 10),
          Center(child: _statusChip(status)),
        ],
        const SizedBox(height: 12),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else if (!active)
          const SizedBox.shrink()
        else if (isRealizingCompany) ...[
          if (canAdd) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(existing == null
                  ? 'Dodaj zdjęcie realizacji'
                  : 'Dodaj właściwe zdjęcie'),
              onPressed: () => _addPhoto(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.compare_outlined, size: 18),
              label: const Text('Dodaj parę Przed / Po'),
              onPressed: () => _addPhoto(withBefore: true),
            ),
            if (existing == null && _jobStatus != 'approved') ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.task_alt, size: 18),
                label: const Text('Zlecenie wykonane (bez zdjęć)'),
                onPressed: () => _markDone(true),
              ),
            ],
          ] else if (noPhotoPending)
            TextButton.icon(
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Cofnij — jeszcze nie skończone'),
              onPressed: () => _markDone(false),
            )
          else if (status == 'pending')
            TextButton.icon(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
              label: Text('Usuń zdjęcia', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () => _withdraw(existing!['id'] as String),
            ),
        ] else if (isOwner) ...[
          if (noPhotoPending) ...[
            Text(
              'Firma oznaczyła zlecenie jako wykonane. Potwierdź, jeśli praca jest zrobiona — zlecenie się zamknie.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Potwierdzam'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                    onPressed: () => _decide('approved'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Jeszcze nie'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300)),
                    onPressed: () => _decide('rejected'),
                  ),
                ),
              ],
            ),
          ] else if (existing == null && _jobStatus != 'approved')
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera_back_outlined, size: 18),
              label: const Text('Poproś o zdjęcia realizacji'),
              onPressed: _askForPhotos,
            )
          else if (status == 'pending') ...[
            Text(
              'Czy to zdjęcia z Twojego zlecenia? Po potwierdzeniu trafią do portfolio firmy.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Potwierdzam'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green.shade600),
                    onPressed: () => _decide('approved'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('To nie moje'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300)),
                    onPressed: () => _decide('rejected'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'rejected')
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_camera_back_outlined, size: 18),
              label: const Text('Poproś o inne zdjęcia'),
              onPressed: _askForPhotos,
            ),
        ],
        if (clientPhotos.isNotEmpty && (isOwner || isRealizingCompany)) ...[
          const SizedBox(height: 16),
          Text(
            isOwner
                ? 'Twoje zdjęcia'
                : 'Zdjęcia od klienta — możesz je opublikować na swoim profilu',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in clientPhotos) RealizationThumb(photo: p, size: 70),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
