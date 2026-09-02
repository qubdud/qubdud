import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qb/shared/widgets/before_after.dart';

import '../../../../../domain_layer/chat_service.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';

/// Sekcja „Zdjęcia realizacji" na widoku zgłoszenia — widoczna po
/// obustronnym potwierdzeniu zadania:
/// - firma realizująca dodaje zdjęcia,
/// - właściciel zgłoszenia może poprosić o zdjęcia na czacie.
class RealizationSection extends StatefulWidget {
  final Request request;

  const RealizationSection({super.key, required this.request});

  @override
  State<RealizationSection> createState() => _RealizationSectionState();
}

class _RealizationSectionState extends State<RealizationSection> {
  List<Map<String, dynamic>> _photos = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await context
          .read<FirebaseService>()
          .getRealizationsForRequest(widget.request.id);
      if (mounted) setState(() => _photos = photos);
    } catch (_) {}
  }

  Future<void> _addPhoto({bool withBefore = false}) async {
    File? before;
    if (withBefore) {
      showToast(text: 'Wybierz zdjęcie PRZED');
      final pickedBefore = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedBefore == null || !mounted) return;
      before = File(pickedBefore.path);
      showToast(text: 'Teraz wybierz zdjęcie PO');
    }
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().addRealization(
            companyId: widget.request.takenBy,
            requestId: widget.request.id,
            requestOwnerId: widget.request.userId,
            category: widget.request.category,
            image: File(picked.path),
            beforeImage: before,
          );
      showToast(text: 'Dodano — klient musi jeszcze potwierdzić');
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _askForPhotos() async {
    await context.read<ChatService>().sendMessage(
          widget.request.takenBy,
          'Dzień dobry, czy mogę prosić o zdjęcia z realizacji mojego zgłoszenia (${widget.request.category})?',
        );
    if (!mounted) return;
    context
        .read<MainScreenBloc>()
        .add(GoToChatEvent(widget.request.takenBy, chatName: widget.request.takenByName));
  }

  Future<void> _decide(String id, String status) async {
    setState(() => _busy = true);
    try {
      await context
          .read<FirebaseService>()
          .setRealizationStatus(id, status, requestId: widget.request.id);
      showToast(
          text: status == 'approved'
              ? 'Potwierdzono — zlecenie zamknięte, zdjęcia trafią na profil firmy'
              : 'Odrzucono — zlecenie zamknięte');
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _remove(String id) async {
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
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().deleteRealization(id);
      await _load();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
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
    if (req.status != 'taken' || me == null) return const SizedBox.shrink();

    final isRealizingCompany = me.id == req.takenBy;
    final isOwner = me.id == req.userId;
    // jedno zgłoszenie = jedna realizacja (zdjęcie lub para Przed/Po)
    final existing = _photos.isNotEmpty ? _photos.first : null;
    final status = (existing?['status'] as String?) ?? 'approved';

    // osoby postronne widzą tylko potwierdzone
    if (!isRealizingCompany && !isOwner && (existing == null || status != 'approved')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        WSmallLabel(text: 'Zdjęcia realizacji'),
        const SizedBox(height: 8),
        if (existing == null)
          Text(
            isRealizingCompany
                ? 'Pochwal się wykonaną pracą — dodaj zdjęcie lub parę Przed/Po. Po potwierdzeniu przez klienta trafi do galerii „Realizacje" na Twoim profilu.'
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
        else if (isRealizingCompany) ...[
          if (existing == null) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Dodaj zdjęcie realizacji'),
              onPressed: () => _addPhoto(),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.compare_outlined, size: 18),
              label: const Text('Dodaj parę Przed / Po'),
              onPressed: () => _addPhoto(withBefore: true),
            ),
          ] else
            TextButton.icon(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
              label: Text('Usuń zdjęcia', style: TextStyle(color: Colors.red.shade400)),
              onPressed: () => _remove(existing['id'] as String),
            ),
        ] else if (isOwner) ...[
          if (existing == null)
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
                    onPressed: () => _decide(existing['id'] as String, 'approved'),
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
                    onPressed: () => _decide(existing['id'] as String, 'rejected'),
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
        const SizedBox(height: 16),
      ],
    );
  }
}
