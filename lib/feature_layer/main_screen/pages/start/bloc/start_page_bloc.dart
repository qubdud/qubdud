import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import 'package:qb/shared/functions/effective_role.dart';
import 'package:qb/shared/new_counts.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/widgets/offer_dialog.dart';

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

      if (!event.silent) emit(StartPageLoadingState());
      // każda sekcja osobno: błąd jednej nie czyści pozostałych
      final failed = <String>[];
      Future<T> section<T>(String name, Future<T> Function() load, T empty) async {
        try {
          return await load();
        } catch (_) {
          failed.add(name);
          return empty;
        }
      }

      // anonim: tylko siatka prezentacji — reszta wymaga konta (i wywala
      // permission-denied, co zostawiało pustą siatkę)
      if (user.id.isEmpty) {
        state.videos = await section(
            'prezentacji', () => firebase.getRandomPromos(limit: 20), <Promo>[]);
        state.loadErrors = failed;
        emit(StartPageMainState());
        return;
      }

      final company = user.firma == true;
      final nearbyF = section(
          'zgłoszeń',
          () async => company
              ? await firebase.getNearbyRequests(
                  category: user.companyCategory!,
                  sector: user.companySector!,
                  myLocation: user.companyLocation!,
                  userId: user.id)
              : (requests: <Request>[], myOffers: <String, Map<String, dynamic>>{}),
          (requests: <Request>[], myOffers: <String, Map<String, dynamic>>{}));
      final notesF = section('notatek',
          () async => company ? await firebase.getClientNotes(user.id) : <String, String>{},
          <String, String>{});
      final trashF = section('kosza',
          () async => company ? await firebase.getTrashedRequests(userId: user.id) : <Request>[],
          <Request>[]);
      final myRequestsF = section('Twoich zgłoszeń',
          () => firebase.getRequestsMetadataByUser(user.id), <Request>[]);
      // Dla firmy: recenzje OTRZYMANE; dla usera: recenzje WYSTAWIONE
      final reviewsF = section(
          'recenzji',
          () => company
              ? firebase.getReviewsMetadataByReviewedUser(user.id)
              : firebase.getReviewByUser(user.id),
          <Review>[]);
      final favF = section(
          'ulubionych', () => firebase.getFavoritePromos(user.id), <Promo>[]);
      final videosF = section(
          'prezentacji', () => firebase.getRandomPromos(limit: 20), <Promo>[]);

      final nearby = await nearbyF;
      state.requests = nearby.requests;
      state.myOfferStatuses = {
        for (final e in nearby.myOffers.entries)
          e.key: (e.value['status'] as String?) ?? 'pending',
      };
      state.clientNotes = await notesF;
      state.trashedRequests = await trashF;
      state.myRequests = await myRequestsF;
      state.myReview = await reviewsF;
      state.favVideo = await favF;
      state.videos = await videosF;
      state.loadErrors = failed;

      emit(StartPageMainState());

      // liczniki „co nowego" na zakładkach — w tle, Start na nie nie czeka
      unawaited(NewCounts.refresh(
        firebase: firebase,
        user: user,
        companyMode: isCompanyMode(user),
        requests: state.requests,
        myOffers: nearby.myOffers,
        myRequests: state.myRequests,
        reviews: state.myReview,
      ));
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


    Future<void> refreshFavorites(Emitter<StartPageState> emit) async {
      try {
        state.favVideo = await firebase.getFavoritePromos(user.id);
      } catch (_) {
        showToastError(text: 'Nie udało się odświeżyć ulubionych');
      }
      emit(StartPageMainState());
    }

    on<TryAddFavStartPageEvent>((event, emit) async {
      try {
        await firebase.addPromoToFavorites(userId: user.id, promoId: event.promoId);
      } catch (_) {
        showToastError(text: 'Nie udało się dodać do ulubionych');
        return;
      }
      showToast(text: 'Dodano do ulubionych');
      await refreshFavorites(emit);
    });

    on<TryRemoveFavStartPageEvent>((event, emit) async {
      try {
        await firebase.removePromoFromFavorites(userId: user.id, promoId: event.promoId);
      } catch (_) {
        showToastError(text: 'Nie udało się usunąć z ulubionych');
        return;
      }
      showToast(text: 'Usunięto z ulubionych');
      await refreshFavorites(emit);
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
          message: event.message?.trim().isNotEmpty == true
              ? event.message!.trim()
              : kDefaultOfferMessage,
          price: event.price,
          priceTo: event.priceTo,
          when: event.when,
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