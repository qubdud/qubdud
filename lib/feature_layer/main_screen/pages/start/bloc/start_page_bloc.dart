import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';

part 'start_page_event.dart';
part 'start_page_state.dart';


class StartPageBloc extends Bloc<StartPageEvent, StartPageState> {
  StartPageBloc({
    required FirebaseService firebase,
    required AppUser user,

  }) : super(StartPageLoadingState()) {
    on<GoToMainStartPageEvent>((event, emit) async {

      emit(StartPageLoadingState());

      add(GetDataStartPageEvent());
    });

    on<GetDataStartPageEvent>((event, emit) async {

      emit(StartPageLoadingState());
      try {
        if(user.firma!){
          state.requests = await firebase.getNearbyRequests(category: user.companyCategory!, sector: user.companySector!, myLocation: user.companyLocation!, userId: user.id);
          state.myOfferStatuses = await firebase.getMyOfferStatuses(
              state.requests.map((r) => r.id).toList(), user.id);
          state.clientNotes = await firebase.getClientNotes(user.id);
        }

        state.myRequests = await firebase.getRequestsMetadataByUser(user.id);

        // Dla firmy: recenzje OTRZYMANE; dla usera: recenzje WYSTAWIONE
        if (user.firma ?? false) {
          state.myReview = await firebase.getReviewsMetadataByReviewedUser(user.id);
        } else {
          state.myReview = await firebase.getReviewByUser(user.id);
        }

        state.favVideo = await firebase.getFavoritePromos(user.id);
        state.videos = await firebase.getRandomPromos();

        // Załaduj kosz (skipped z flagą trashed)
        if (user.firma ?? false) {
          state.trashedRequests = await firebase.getTrashedRequests(userId: user.id);
        }

        emit(StartPageMainState());
      } catch (e) {


        state.videos =[];
        //showToastError(text: 'Błąd pobierania\n${e}');

        emit(StartPageMainState());
      }

    });


    on<SkipRequestEvent>((event, emit) async {
      try {

// 1. Zapisz w Firebase, że to ogłoszenie jest pominięte
        await firebase.skipRequest(
            userId: user.id,
            requestId: event.requestId
        );

// 2. Usuń to ogłoszenie lokalnie ze stanu, aby natychmiast zniknęło z listy
        state.requests = state.requests
            .where((req) => req.id != event.requestId)
            .toList();

        emit(StartPageMainState());
      } catch (e) {
        print(e);
// obsługa błędu
      }
    });


    on<TryAddFavStartPageEvent>((event, emit) async {

      try {
        await firebase.addPromoToFavorites(userId: user.id, promoId: event.promoId);

        state.favVideo = await firebase.getFavoritePromos(user.id);


        emit(StartPageMainState());

        showToast(text: 'Dodano do ulubionych');

      } catch (e) {

        state.videos =[];
        showToastError(text: 'Błąd nie dodano\n${e}');

        emit(StartPageMainState());
      }

    });


    on<TryRemoveFavStartPageEvent>((event, emit) async {

      try {
        await firebase.removePromoFromFavorites(userId: user.id, promoId: event.promoId);


        state.favVideo = await firebase.getFavoritePromos(user.id);


        emit(StartPageMainState());


        showToast(text: 'Usunięto z ulubionych');

      } catch (e) {

        state.videos =[];
        showToastError(text: 'Błąd nie dodano\n${e}');

        emit(StartPageMainState());
      }

    });



    on<TryAddContactStartPageEvent>((event, emit) async {
      try {
        await firebase.addContact(myUserId: user.id, contactUserId: event.contactUserId);
        showToast(text: 'Dodano do kontaktów');
      } catch (e) {
        showToastError(text: 'Błąd: $e');
      }
    });

    on<TryQuickOfferEvent>((event, emit) async {
      try {
        await firebase.sendOffer(
          requestId: event.requestId,
          companyId: user.id,
          companyName: user.companyName ?? 'Firma',
          message:
              'Jestem zainteresowany tym zleceniem — mogę się nim zająć. Proszę o kontakt.',
        );
        state.myOfferStatuses = {
          ...state.myOfferStatuses,
          event.requestId: 'pending',
        };
        showToast(text: 'Oferta wysłana');
        emit(StartPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
      }
    });

    on<TryHideRequestEvent>((event, emit) async {
      try {
        // Przenieś do koszyka — zapisz w skippedRequests z flagą 'trashed'
        await firebase.trashRequest(userId: user.id, requestId: event.requestId);
        state.trashedRequests = [...state.trashedRequests,
          state.requests.firstWhere((r) => r.id == event.requestId)];
        state.requests = state.requests.where((r) => r.id != event.requestId).toList();
        showToast(text: 'Zgłoszenie ukryte');
        emit(StartPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
      }
    });

    on<TryRestoreRequestEvent>((event, emit) async {
      try {
        await firebase.restoreRequest(userId: user.id, requestId: event.requestId);
        state.requests = [...state.requests,
          state.trashedRequests.firstWhere((r) => r.id == event.requestId)];
        state.trashedRequests = state.trashedRequests.where((r) => r.id != event.requestId).toList();
        showToast(text: 'Przywrócono zgłoszenie');
        emit(StartPageMainState());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
      }
    });

    add(GetDataStartPageEvent());
  }

}