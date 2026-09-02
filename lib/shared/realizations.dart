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
Future<bool> pickAndAddRealization(
  BuildContext context,
  Request request, {
  /// 'pair' = para Przed/Po, 'single' = jedno zdjęcie
  required String mode,
  /// 'company' = prośba o potwierdzenie, 'user' = zdjęcia od klienta
  String addedByRole = 'company',
}) async {

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
          addedByRole: addedByRole,
        );
    showToast(
        text: addedByRole == 'company'
            ? 'Wysłano prośbę o potwierdzenie realizacji'
            : 'Dodano zdjęcia — firma może je pokazać w portfolio');
    return true;
  } catch (e) {
    showToastError(text: 'Błąd: $e');
    return false;
  }
}
