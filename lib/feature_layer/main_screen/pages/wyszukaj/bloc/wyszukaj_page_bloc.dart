import 'dart:async';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bloc/bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/globals.dart';


part 'wyszukaj_page_event.dart';

part 'wyszukaj_page_state.dart';

class WyszukajPageBloc extends Bloc<WyszukajPageEvent, WyszukajPageState> {
  WyszukajPageBloc({
    required FirebaseService firebase,
    required AppUser user,


  }) : super(WyszukajPageLoadingState()) {


    on<TryWyszukajPageEvent>((event, emit) async {
      emit(WyszukajPageLoadingState());

      // Zapisz wyszukanie do historii
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      final entry = '${event.category}|${event.sector}|${event.location.latitude},${event.location.longitude}';
      history.remove(entry); // usuń duplikat
      history.insert(0, entry);
      if (history.length > 10) history.removeLast();
      await prefs.setStringList('search_history', history);

      state.videos = await firebase.getNearbyPromos(category: event.category, sector: event.sector, myLocation: event.location);
      Globals.instance.lastSearch = state.videos;
      Globals.instance.lastSearchIndex = 0;
      emit(WyszukajPageResultsState());
    });

    on<GoToLastWyszukajPageEvent>((event, emit) async {
      emit(WyszukajPageLoadingState());
      if(Globals.instance.lastSearch.isNotEmpty){
        state.videos = Globals.instance.lastSearch;
        emit(WyszukajPageResultsState());
      }

      else{
        emit(WyszukajPageMainState());
      }



    });




    on<TryAddFavWyszukajPageEvent>((event, emit) async {
      try {


        await firebase.addPromoToFavorites(userId: user.id, promoId: event.promoId);

        showToast(text: 'Dodano do ulubionych');

      } catch (e) {

        state.videos =[];
        showToastError(text: 'Błąd nie dodano\n${e}');


      }

    });


    on<TryAddContactEvent>((event, emit) async {
      try {
        await firebase.addContact(
          myUserId: user.id,
          contactUserId: event.contactUserId,
        );
        showToast(text: 'Dodano do kontaktów');
      } catch (e) {
        showToastError(text: 'Błąd: $e');
      }
    });

    add(GoToLastWyszukajPageEvent());

  }




}