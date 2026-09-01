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
  List<Request> get myRequests => requestsStatic;
  set myRequests(List<Request> value) {
    myRequestsStatic = value;
  }

  static List<Review> myReviewStatic = [];
  List<Review> get myReview => myReviewStatic;
  set myReview(List<Review> value) {
    myReviewStatic = value;
  }

  // Zgłoszenia ukryte (kosz) — dla firmy
  static List<Request> trashedRequestsStatic = [];
  List<Request> get trashedRequests => trashedRequestsStatic;
  set trashedRequests(List<Request> value) {
    trashedRequestsStatic = value;
  }

}

class StartPageInitialState extends StartPageState {}

class StartPageMainState extends StartPageState {}


class StartPageLoadingState extends StartPageState {}

class StartPageNextState extends StartPageState {}