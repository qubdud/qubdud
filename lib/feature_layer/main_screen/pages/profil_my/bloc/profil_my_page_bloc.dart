import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../data_layer/data_models/request/contact.dart';
import '../../../../../data_layer/data_models/response_error/contact.dart';
import '../../../../../domain_layer/domain_models/company_info.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/show_toast_error.dart';

part 'profil_my_page_event.dart';
part 'profil_my_page_state.dart';

class MyProfilPageBloc extends Bloc<MyProfilPageEvent, MyProfilPageState> {
  MyProfilPageBloc({
    required FirebaseService firebase,
  }) : super(MyProfilPageInitialState()) {
    on<GoToMainMyProfilPageEvent>((event, emit) async {
      emit(MyProfilPageMainState());
    });

    on<SetDataMyProfilPageEvent>((event, emit) async {
      emit(MyProfilPageLoadingState());
      try {

        final userId = FirebaseAuth.instance.currentUser?.uid;



        await firebase.saveProfile(ProfileInfo(userId: userId!, description: event.description, timestamp: null));



        showToast(text: 'Zapisano');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd zapisu danych\n${e}');
        emit(MyProfilPageMainState());
      }

    });



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

        final requests = await firebase.getRequestsMetadataByUser(userId);
        state.requests = requests;

        final reviews = await firebase.getReviewByUser(userId);
        state.reviews = reviews;

        // Kosz — ukryte zgłoszenia
        state.trashedRequests = await firebase.getTrashedRequests(userId: userId);

        emit(MyProfilPageMainState());
      } catch (e) {
        print(e);
        state.videos = [];
        state.companyInfo = null;

        showToastError(text: 'Błąd pobierania danych\n${e}');
        emit(MyProfilPageMainState());
      }
    });


    on<TryDeleteMyRequestProfilPageEvent>((event, emit) async {
      try {

        await firebase.deleteRequestMetadata( event.id );
        showToast(text: 'Usunięto');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        state.videos =[];
        showToastError(text: 'Błąd\n${e}');
        emit(MyProfilPageMainState());
      }

    });

    on<TryDeleteMyPromoProfilPageEvent>((event, emit) async {
      try {
        await firebase.deletePromoMetadata(event.id);
        showToast(text: 'Usunięto');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        state.videos =[];
        showToastError(text: 'Błąd\n${e}');
        emit(MyProfilPageMainState());
      }

    });




    on<UpdateRequestDescriptionEvent>((event, emit) async {
      try {
        await firebase.updateRequestDescription(event.id, event.newDescription);
        showToast(text: 'Zapisano');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd zapisu: $e');
      }
    });

    on<UpdateUserDataEvent>((event, emit) async {
      emit(MyProfilPageLoadingState());
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;
        await firebase.updateUserData(userId, {
          'firstName': event.firstName,
          'lastName': event.lastName,
          'phone': event.phone,
          'bio': event.bio,
        });
        showToast(text: 'Zapisano');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd zapisu: $e');
        emit(MyProfilPageMainState());
      }
    });

    on<UpdateCompanyDataEvent>((event, emit) async {
      emit(MyProfilPageLoadingState());
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return;
        await firebase.updateUserData(userId, {
          'companyName': event.companyName,
          'bio': event.bio,
          'phone': event.phone,
        });
        showToast(text: 'Zapisano');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd zapisu: $e');
        emit(MyProfilPageMainState());
      }
    });

    on<TryDeleteMyReviewProfilPageEvent>((event, emit) async {
      try {
        await firebase.deleteReviewMetadata(event.id);
        showToast(text: 'Usunięto recenzję');
        add(GetDataMyProfilPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd: $e');
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
        // Trwale usuwa TYLKO z listy skipped usera (nie usuwa samego zgłoszenia)
        await firebase.restoreRequest(userId: FirebaseAuth.instance.currentUser!.uid, requestId: event.requestId);
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