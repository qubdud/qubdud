import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import '../../dodaj/bloc/dodaj_page_bloc.dart' show makeThumbnail, uploadErrorText;
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/globals.dart';

part 'dodaj_rev_page_event.dart';
part 'dodaj_rev_page_state.dart';

class DodajReviewPageBloc extends Bloc<DodajReviewPageEvent, DodajReviewPageState> {

  DodajReviewPageBloc({required FirebaseService firebase})

      : super(DodajReviewPageLoadingState()) {



    on<SelectedDodajReviewPageEvent>((event, emit) async {
      emit(DodajReviewPageLoadingState());
      state.selectedContent = SelectedContent(file: event.file, fileType: event.fileType, selectType: event.selectType);
      state.reviewMetadata = null;
      String? thumb;
      try {
        thumb = await makeThumbnail(event.file, event.fileType);
      } catch (_) {}
      if (thumb == null) {
        showToastError(text: 'Nie udało się odczytać pliku. Wybierz inne zdjęcie lub film.');
        emit(DodajReviewPageMainState());
        return;
      }
      emit(DodajRequestPromoState(thumb));
    });

    // Cały zapis w jednym handlerze: wyjście z ekranu w trakcie wysyłania
    // zamyka BLoC (emit staje się no-op), ale recenzja i tak się zapisze.
    on<DodajDodajReviewPageEvent>((event, emit) async {
      final current = state;
      final content = state.selectedContent!;
      emit(DodajReviewPageLoadingState());

      String? thumb;
      try {
        thumb = current is DodajRequestPromoState
            ? current.thumbPath
            : await makeThumbnail(content.file, content.fileType);
      } catch (_) {}
      if (thumb == null) {
        showToastError(text: 'Nie udało się odczytać pliku. Wybierz inny.');
        emit(DodajReviewPageMainState());
        return;
      }

      try {
        final user =
            await firebase.fetchUser(FirebaseAuth.instance.currentUser!.uid);
        state.appUser = user;
        final media = await firebase.uploadMedia(
          file: content.file,
          thumb: File(thumb),
          mediaType: content.fileType == 'video' ? 'video' : 'image',
          onProgress: (progress) =>
              emit(DodajReviewPageUploadingState(progress)),
        );
        final promo = Globals.instance.selectedPromo;
        await firebase.saveReviewMetadata(Review(
          userId: user!.id,
          promoId: promo?.id == 'profile_review' ? '' : (promo?.id ?? ''),
          reviewedUserId: promo?.userId ?? '',
          authorName: '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
          score: state.reviewMetadata!.score,
          description: state.reviewMetadata!.description,
          fileName: media.fileName,
          fileUrl: media.fileUrl,
          thumbUrl: media.thumbUrl,
          id: '',
          timestamp: null,
        ));
        showToast(text: 'Przesłano');
        emit(DodajReviewPageNextState());
      } catch (e) {
        // reguły przyjmują jedną recenzję klienta na firmę (id = autor_firma)
        showToastError(
            text: e is FirebaseException && e.code == 'permission-denied'
                ? 'Opinię o tej firmie możesz wystawić tylko raz.'
                : uploadErrorText(e));
        // powrót do formularza z oceną i opisem
        emit(DodajRequestPromoState(thumb));
      }
    });


    on<GetDataDodajReviewPageEvent>((event, emit) async {
      emit(DodajReviewPageLoadingState());
      try {
        // Jeśli selectedPromo to placeholder z profilu firmy (id='profile_review')
        // — pobierz pierwszy prawdziwy promo tej firmy
        if (Globals.instance.selectedPromo?.id == 'profile_review') {
          final companyId = Globals.instance.selectedPromo!.userId;
          final promos = await firebase.getPromosMetadataByUser(companyId);
          if (promos.isNotEmpty) {
            Globals.instance.selectedPromo = promos.first;
          }
          // Jeśli firma nie ma promo — zostawiamy placeholder, obsłużone niżej
        }

        final companyId = Globals.instance.selectedPromo?.userId;
        if (companyId == null || companyId.isEmpty) {
          emit(DodajReviewPageMainState());
          return;
        }
        state.reviews = await firebase.getReviewsMetadataByReviewedUser(companyId);
        emit(DodajReviewPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd pobierania danych: $e');
        emit(DodajReviewPageMainState());
      }
    });



    add(GetDataDodajReviewPageEvent());

  }






}