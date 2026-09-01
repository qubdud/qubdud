import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/company_info.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/show_toast_error.dart';

part 'profil_my_page_event.dart';
part 'profil_my_page_state.dart';

class ProfilPubliczyPageBloc extends Bloc<ProfilPubliczyPageEvent, ProfilPubliczyPageState> {
  final FirebaseService firebase;
  final String targetUserId;

  ProfilPubliczyPageBloc({
    required this.firebase,
    required this.targetUserId,
  }) : super(const ProfilPubliczyPageInitialState()) {

    on<GetDataProfilPubliczyPageEvent>((event, emit) async {
      // Emitujemy stan ładowania, zachowując ewentualne obecne dane (opcjonalnie)
      emit(ProfilPubliczyPageLoadingState(
        videos: state.videos,
        companyInfo: state.companyInfo,
        targetUser: state.targetUser,
      ));

      try {
        // 1. Pobieramy dane równolegle (szybciej) lub po kolei
        final user = await firebase.fetchUser(targetUserId);
        final videos = await firebase.getPromosMetadataByUser(targetUserId);
        final companyInfo = await firebase.getProfileByUser(targetUserId);
        final reviews = await firebase.getReviewsMetadataByReviewedUser(targetUserId);

        // 2. Liczenie średniej oceny
        double avg = 0;
        if (reviews.isNotEmpty) {
          avg = reviews.fold(0.0, (sum, item) => sum + item.score) / reviews.length;
        }

        // 3. KLUCZOWA ZMIANA: Emitujemy NOWY obiekt stanu z wszystkimi danymi
        emit(ProfilPubliczyPageMainState(
          targetUser: user,
          videos: videos,
          companyInfo: companyInfo,
          reviews: reviews,
          averageScore: double.parse(avg.toStringAsFixed(1)),
          requests: [], // jeśli potrzebujesz też requestów, dodaj pobieranie
        ));

      } catch (e) {
        print("Błąd Profilu: $e");
        showToastError(text: 'Błąd pobierania danych profilu');
        // W razie błędu wracamy do MainState z pustymi listami lub poprzednimi danymi
        emit(ProfilPubliczyPageMainState(
          videos: state.videos,
          reviews: state.reviews,
          requests: state.requests,
        ));
      }
    });

    on<SetDataProfilPubliczyPageEvent>((event, emit) async {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != targetUserId) return;

      emit(ProfilPubliczyPageLoadingState(
        videos: state.videos,
        targetUser: state.targetUser,
      ));

      try {
        await firebase.saveProfile(ProfileInfo(
            userId: currentUid!,
            description: event.description,
            timestamp: null
        ));
        showToast(text: 'Zapisano opis');
        // Zamiast emitować stan ręcznie, wywołujemy odświeżenie danych
        add(GetDataProfilPubliczyPageEvent());
      } catch (e) {
        showToastError(text: 'Błąd zapisu');
        emit(ProfilPubliczyPageMainState(
          videos: state.videos,
          companyInfo: state.companyInfo,
          reviews: state.reviews, requests: [],
        ));
      }
    });

    // Inicjalizacja
    add(GetDataProfilPubliczyPageEvent());
  }
}