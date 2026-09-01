import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _addPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().addRealization(
            companyId: widget.request.takenBy,
            requestId: widget.request.id,
            category: widget.request.category,
            image: File(picked.path),
          );
      showToast(text: 'Dodano zdjęcie realizacji');
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
        .add(GoToChatEvent(widget.request.takenBy));
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<MainScreenBloc>().state.user;
    final req = widget.request;
    if (req.status != 'taken' || me == null) return const SizedBox.shrink();

    final isRealizingCompany = me.id == req.takenBy;
    final isOwner = me.id == req.userId;
    if (!isRealizingCompany && !isOwner && _photos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        WSmallLabel(text: 'Zdjęcia realizacji'),
        const SizedBox(height: 8),
        if (_photos.isEmpty)
          Text(
            isRealizingCompany
                ? 'Pochwal się wykonaną pracą — dodaj zdjęcia. Trafią też do galerii „Realizacje" na Twoim profilu.'
                : 'Firma nie dodała jeszcze zdjęć realizacji.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, i) {
                final p = _photos[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(12),
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                              imageUrl: p['imageUrl'] ?? ''),
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: p['imageUrl'] ?? '',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        if (_busy)
          const Center(child: CircularProgressIndicator())
        else if (isRealizingCompany)
          OutlinedButton.icon(
            icon: const Icon(Icons.add_a_photo_outlined, size: 18),
            label: const Text('Dodaj zdjęcie realizacji'),
            onPressed: _addPhoto,
          )
        else if (isOwner)
          OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera_back_outlined, size: 18),
            label: const Text('Poproś o zdjęcia realizacji'),
            onPressed: _askForPhotos,
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
