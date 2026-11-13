import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';

part 'dodaj_page_event.dart';

part 'dodaj_page_state.dart';

/// Miniatura JPG (720 px wysokości) do list; null, gdy pliku nie da się
/// odczytać (np. HEIC bez dekodera).
Future<String?> makeThumbnail(File file, String fileType) async {
  final tempDir = await getTemporaryDirectory();
  final out = p.join(tempDir.path, '${p.basename(file.path)}-thumb.jpg');
  if (fileType == 'video') {
    return VideoThumbnail.thumbnailFile(
      video: file.path,
      thumbnailPath: out,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 720,
      quality: 75,
    );
  }
  // dekodowanie dużego zdjęcia poza wątkiem UI
  final jpg = await compute(_resizeToJpg, await file.readAsBytes());
  if (jpg == null) return null;
  await File(out).writeAsBytes(jpg);
  return out;
}

Uint8List? _resizeToJpg(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  // copyResize obraca wg EXIF, więc miniatura może iść bez metadanych (GPS)
  final small = img.copyResize(image, height: 720)..exif = img.ExifData();
  return img.encodeJpg(small, quality: 75);
}

/// Komunikat dla użytkownika po nieudanym uploadzie.
String uploadErrorText(Object e) =>
    e is FirebaseException && e.code == 'unauthorized'
        ? 'Plik jest za duży albo ma nieobsługiwany format.'
        : 'Nie udało się wysłać pliku. Spróbuj ponownie.';

class DodajPageBloc extends Bloc<DodajPageEvent, DodajPageState> {
  DodajPageBloc({required FirebaseService firebase})
    : super(DodajPageMainState()) {

    on<SelectedDodajPageEvent>((event, emit) async {
      emit(DodajPageLoadingState());
      state.selectedContent = SelectedContent(file: event.file, fileType: event.fileType, selectType: event.selectType);
      state.requestMetadata = null;

      if (event.selectType != 'request') {
        add(DodajDodajPageEvent());
        return;
      }
      String? thumb;
      try {
        thumb = await makeThumbnail(event.file, event.fileType);
      } catch (_) {}
      if (thumb == null) {
        showToastError(text: 'Nie udało się odczytać pliku. Wybierz inne zdjęcie lub film.');
        emit(DodajPageMainState());
        return;
      }
      emit(DodajRequestPromoState(thumb));
    });

    on<SkipFileDodajPageEvent>((event, emit) {
      state.selectedContent = null;
      state.requestMetadata = null;
      emit(DodajRequestPromoState(''));
    });

    // Cały zapis w jednym handlerze: wyjście z ekranu w trakcie wysyłania
    // zamyka BLoC (emit staje się no-op), ale plik i metadane i tak się zapiszą.
    on<DodajDodajPageEvent>((event, emit) async {
      final current = state;
      final content = state.selectedContent;
      final meta = state.requestMetadata;
      emit(DodajPageLoadingState());

      if (content == null) {
        if (meta == null) {
          emit(DodajPageMainState());
          return;
        }
        try {
          await firebase.saveRequestMetadata(Request(
            userId: FirebaseAuth.instance.currentUser!.uid,
            category: meta.category,
            sector: meta.sector,
            location: meta.location,
            city: meta.city,
            description: meta.description,
            is24: meta.is24,
            timing: meta.timing,
            budget: meta.budget,
            answers: meta.answers,
            fileName: '',
            mediaType: 'none',
            fileUrl: '',
            thumbUrl: '',
            id: '',
            timestamp: null,
          )).timeout(const Duration(seconds: 10));
          showToast(text: 'Przesłano');
          emit(DodajPageNextState());
        } on TimeoutException {
          showToast(text: 'Brak internetu — zgłoszenie wyśle się po połączeniu');
          emit(DodajPageNextState());
        } catch (e) {
          showToastError(text: 'Nie udało się dodać zgłoszenia. Sprawdź internet i spróbuj ponownie.');
          emit(DodajRequestPromoState(''));
        }
        return;
      }

      String? thumb;
      try {
        thumb = current is DodajRequestPromoState
            ? current.thumbPath
            : await makeThumbnail(content.file, content.fileType);
      } catch (_) {}
      if (thumb == null) {
        showToastError(text: 'Nie udało się odczytać pliku. Wybierz inny.');
        emit(DodajPageMainState());
        return;
      }

      try {
        final user =
            await firebase.fetchUser(FirebaseAuth.instance.currentUser!.uid);
        state.appUser = user;
        final mediaType = content.fileType == 'video' ? 'video' : 'image';
        final media = await firebase.uploadMedia(
          file: content.file,
          thumb: File(thumb),
          mediaType: mediaType,
          onProgress: (progress) => emit(DodajPageUploadingState(progress)),
        );

        if (content.selectType == 'promo') {
          await firebase.savePromoVideoMetadata(Promo(
            userId: user!.id,
            category: user.companyCategory!,
            sector: user.companySector!,
            location: user.companyLocation!,
            companyName: user.companyName ?? '',
            fileName: media.fileName,
            fileUrl: media.fileUrl,
            thumbUrl: media.thumbUrl,
            id: '',
            timestamp: null,
            description: '',
          ));
        } else if (meta != null) {
          await firebase.saveRequestMetadata(Request(
            userId: user!.id,
            category: meta.category,
            sector: meta.sector,
            location: meta.location,
            city: meta.city,
            description: meta.description,
            is24: meta.is24,
            timing: meta.timing,
            budget: meta.budget,
            answers: meta.answers,
            fileName: media.fileName,
            mediaType: mediaType,
            fileUrl: media.fileUrl,
            thumbUrl: media.thumbUrl,
            id: '',
            timestamp: null,
          ));
        } else {
          throw StateError('Brak danych zgłoszenia');
        }

        showToast(text: 'Przesłano');
        emit(DodajPageNextState());
      } catch (e) {
        showToastError(text: uploadErrorText(e));
        // zgłoszenie: powrót do formularza z wpisanymi danymi
        emit(content.selectType == 'request'
            ? DodajRequestPromoState(thumb)
            : DodajPageMainState());
      }
    });
  }
}
