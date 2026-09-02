import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../domain_layer/domain_models/promoVideo.dart';
import '../domain_layer/firebase_service.dart';
import 'functions/show_toast.dart';
import 'functions/show_toast_error.dart';

/// Wybór trybu (zdjęcie / para Przed-Po), wybór plików i zapis realizacji.
/// Zwraca true, gdy realizacja została dodana. Używane z karty zgłoszenia
/// u firmy i z widoku zgłoszenia.
Future<bool> pickAndAddRealization(BuildContext context, Request request) async {
  final mode = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Zdjęcia realizacji',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
                'Jedno zgłoszenie = jedna realizacja. Klient musi ją potwierdzić — wtedy trafi na Twój profil, a zlecenie zostanie zamknięte.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Jedno zdjęcie (po wykonaniu)'),
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
  if (mode == null || !context.mounted) return false;

  final picker = ImagePicker();
  File? before;
  if (mode == 'pair') {
    showToast(text: 'Wybierz zdjęcie PRZED');
    final b = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (b == null || !context.mounted) return false;
    before = File(b.path);
    showToast(text: 'Teraz wybierz zdjęcie PO');
  }
  final after = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  if (after == null || !context.mounted) return false;

  try {
    await context.read<FirebaseService>().addRealization(
          companyId: request.takenBy,
          requestId: request.id,
          requestOwnerId: request.userId,
          category: request.category,
          image: File(after.path),
          beforeImage: before,
        );
    showToast(text: 'Dodano — klient dostał prośbę o potwierdzenie');
    return true;
  } catch (e) {
    showToastError(text: 'Błąd: $e');
    return false;
  }
}
