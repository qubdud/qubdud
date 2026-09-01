import 'package:bloc/bloc.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/shared/functions/show_toast.dart';
import 'package:qb/shared/functions/show_toast_error.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';

part 'single_video_page_event.dart';
part 'single_video_page_state.dart';

class SingleVideoPageBloc extends Bloc<SingleVideoPageEvent, SingleVideoPageState> {
  final FirebaseService firebase;
  final String userId; // ID zalogowanego użytkownika
  final Promo promo;   // Dane filmu

  SingleVideoPageBloc({
    required this.firebase,
    required this.userId,
    required this.promo,
  }) : super(SingleVideoPageLoadingState()) {

    on<GetDataSingleVideoEvent>((event, emit) async {
      emit(SingleVideoPageLoadingState());
      try {
        // Pobieramy dane równolegle
        final results = await Future.wait([
          firebase.fetchUser(promo.userId),
          firebase.getReviewsMetadataByReviewedUser(promo.userId),
        ]);

        final user = results[0] as AppUser?;
        final reviews = results[1] as List<dynamic>? ?? [];

        if (user != null) {
          emit(SingleVideoPageMainState(
            promo: promo,
            author: user,
            reviews: reviews,
          ));
        } else {
          //emit(SingleVideoPageErrorState("Nie znaleziono autora filmu"));
        }
      } catch (e) {
       // emit(SingleVideoPageErrorState("Błąd pobierania danych: $e"));
        showToastError(text: 'Błąd: $e');
      }
    });

    on<ToggleFavoriteVideoEvent>((event, emit) async {
      try {
        if (event.isFavorite) {
          await firebase.removePromoFromFavorites(userId: userId, promoId: event.promoId);
          showToast(text: 'Usunięto z ulubionych');
        } else {
          await firebase.addPromoToFavorites(userId: userId, promoId: event.promoId);
          showToast(text: 'Dodano do ulubionych');
        }
        // Odświeżamy dane po zmianie fav
        add(GetDataSingleVideoEvent());
      } catch (e) {
        showToastError(text: 'Błąd polubienia: $e');
      }
    });

    // Inicjalizacja pobierania danych
    add(GetDataSingleVideoEvent());
  }
}