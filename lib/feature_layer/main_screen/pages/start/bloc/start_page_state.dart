part of 'start_page_bloc.dart';

abstract class StartPageState {


  static List<Promo> videosStatic = [];
  List<Promo> get videos => videosStatic;
  set videos(List<Promo> value) {
    videosStatic = value;
  }

  static List<Promo> favVideosStatic = [];
  List<Promo> get favVideo => favVideosStatic;
  set favVideo(List<Promo> value) {
    favVideosStatic = value;
  }

  static List<Request> requestsStatic = [];
  List<Request> get requests => requestsStatic;
  set requests(List<Request> value) {
    requestsStatic = value;
  }

  static List<Request> myRequestsStatic = [];
  List<Request> get myRequests => myRequestsStatic;
  set myRequests(List<Request> value) {
    myRequestsStatic = value;
  }

  static List<Review> myReviewStatic = [];
  List<Review> get myReview => myReviewStatic;
  set myReview(List<Review> value) {
    myReviewStatic = value;
  }

  // Status mojej oferty per zgłoszenie: none/pending/maybe/accepted/rejected/closed
  static Map<String, String> myOfferStatusesStatic = {};
  Map<String, String> get myOfferStatuses => myOfferStatusesStatic;
  set myOfferStatuses(Map<String, String> value) {
    myOfferStatusesStatic = value;
  }

  // Prywatne notatki firmy o klientach: {userId: treść}
  static Map<String, String> clientNotesStatic = {};
  Map<String, String> get clientNotes => clientNotesStatic;
  set clientNotes(Map<String, String> value) {
    clientNotesStatic = value;
  }

  // Zgłoszenia ukryte (kosz) — dla firmy
  static List<Request> trashedRequestsStatic = [];
  List<Request> get trashedRequests => trashedRequestsStatic;
  set trashedRequests(List<Request> value) {
    trashedRequestsStatic = value;
  }

  // Sekcje, których nie udało się wczytać (pasek „Odśwież")
  static List<String> loadErrorsStatic = [];
  List<String> get loadErrors => loadErrorsStatic;
  set loadErrors(List<String> value) {
    loadErrorsStatic = value;
  }

}

class StartPageInitialState extends StartPageState {}

class StartPageMainState extends StartPageState {}


class StartPageLoadingState extends StartPageState {}

class StartPageNextState extends StartPageState {}