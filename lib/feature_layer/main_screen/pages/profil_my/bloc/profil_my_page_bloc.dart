import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:qb/domain_layer/chat_service.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import '../../../../../domain_layer/domain_models/company_info.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../bloc/main_bloc.dart';

part 'profil_my_page_event.dart';
part 'profil_my_page_state.dart';

class MyProfilPageBloc extends Bloc<MyProfilPageEvent, MyProfilPageState> {
  MyProfilPageBloc({
    required FirebaseService firebase,
    required ChatService chat,
  }) : super(MyProfilPageInitialState()) {
    on<GoToMainMyProfilPageEvent>((event, emit) async {
      emit(MyProfilPageMainState());
    });

    // po zapisie formularz zostaje na ekranie z wpisanymi wartościami;
    // reszta apki dostaje profil z lokalnej kopii (offline też ze zmianami)
    Future<void> profileSaved(String userId, bool synced) async {
      final fresh = await firebase.cachedUser(userId);
      if (fresh != null) MainScreenState.userStatic = fresh;
      chat.clearProfileCache();
      showToast(
          text: synced
              ? 'Zapisano'
              : 'Brak sieci — zmiany zapiszą się po połączeniu');
    }

    on<GetDataMyProfilPageEvent>((event, emit) async {
      emit(MyProfilPageLoadingState());

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) throw Exception('Brak użytkownika');


        // Pobierz filmy
        final videos = await firebase.getPromosMetadataByUser(userId);
        state.videos = videos;

        // Pobierz dane firmy
        final companyInfo = await firebase.getProfileByUser(userId);
        state.companyInfo = companyInfo;

        final reviews = await firebase.getReviewByUser(userId);
        state.reviews = reviews;

        // Kosz — ukryte zgłoszenia
        state.trashedRequests = await firebase.getTrashedRequests(userId: userId);

        emit(MyProfilPageMainState());
      } catch (e) {
        debugPrint('Mój profil: wczytywanie: $e');
        state.videos = [];
        state.companyInfo = null;
        showToastError(text: 'Nie udało się wczytać profilu');
        emit(MyProfilPageMainState());
      }
    });


    on<TryDeleteMyPromoProfilPageEvent>((event, emit) async {
      try {
        await firebase.deletePromoMetadata(event.id);
        showToast(text: 'Usunięto');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        debugPrint('Mój profil: usuwanie prezentacji: $e');
        showToastError(text: 'Nie udało się usunąć prezentacji');
        emit(MyProfilPageMainState());
      }

    });




    on<UpdateUserDataEvent>((event, emit) async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      emit(MyProfilPageSavingState());
      try {
        final synced = await firebase.updateUserData(userId, {
          'firstName': event.firstName,
          'lastName': event.lastName,
          if (event.phone != null) 'phone': event.phone,
          if (event.bio != null) 'bio': event.bio,
        });
        await profileSaved(userId, synced);
      } catch (_) {
        showToastError(text: 'Nie udało się zapisać zmian');
      }
      emit(MyProfilPageMainState());
    });

    on<UpdateCompanyDataEvent>((event, emit) async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      emit(MyProfilPageSavingState());
      try {
        var synced = await firebase.updateUserData(userId, {
          'companyName': event.companyName,
          'bio': event.bio,
          'phone': event.phone,
          'companyCity': event.companyCity,
          'companyAddress': event.companyAddress,
          'www': event.www,
          'contactEmail': event.contactEmail,
          'showPhone': event.showPhone,
          'showAddress': event.showAddress,
          if (event.companyLocation != null)
            'companyLocation': {
              'lat': event.companyLocation!.latitude,
              'lng': event.companyLocation!.longitude,
            },
        });
        // filmy firmy dziedziczą lokalizację — przepnij istniejące
        if (event.companyLocation != null) {
          await firebase
              .updateCompanyPromosLocation(userId, event.companyLocation!)
              .timeout(const Duration(seconds: 8),
                  onTimeout: () => synced = false);
        }
        await profileSaved(userId, synced);
      } catch (_) {
        showToastError(text: 'Nie udało się zapisać zmian');
      }
      emit(MyProfilPageMainState());
    });

    on<TryDeleteMyReviewProfilPageEvent>((event, emit) async {
      try {
        await firebase.deleteReviewMetadata(event.id);
        showToast(text: 'Usunięto recenzję');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        debugPrint('Mój profil: usuwanie recenzji: $e');
        showToastError(text: 'Nie udało się usunąć recenzji');
        emit(MyProfilPageMainState());
      }
    });


    on<TryRestoreFromTrashEvent>((event, emit) async {
      try {
        await firebase.restoreRequest(userId: FirebaseAuth.instance.currentUser!.uid, requestId: event.requestId);
        state.trashedRequests = state.trashedRequests.where((r) => r.id != event.requestId).toList();
        showToast(text: 'Przywrócono — zgłoszenie znów widoczne');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
        emit(MyProfilPageMainState());
      }
    });

    on<TryDeleteFromTrashEvent>((event, emit) async {
      try {
        // znika z kosza, ale zostaje ukryte w feedzie (samo zgłoszenie nie jest usuwane)
        await firebase.purgeFromTrash(userId: FirebaseAuth.instance.currentUser!.uid, requestId: event.requestId);
        state.trashedRequests = state.trashedRequests.where((r) => r.id != event.requestId).toList();
        showToast(text: 'Usunięto z kosza');
        emit(MyProfilPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
        emit(MyProfilPageMainState());
      }
    });

    add(GetDataMyProfilPageEvent());
  }
}