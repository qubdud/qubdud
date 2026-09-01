part of 'profil_my_page_bloc.dart';

abstract class MyProfilPageState {

  static List<Promo> videosStatic = [];
  List<Promo> get videos => videosStatic;
  set videos(List<Promo> value) { videosStatic = value; }

  static List<Request> requestsStatic = [];
  List<Request> get requests => requestsStatic;
  set requests(List<Request> value) { requestsStatic = value; }

  static List<Review> reviewsStatic = [];
  List<Review> get reviews => reviewsStatic;
  set reviews(List<Review> value) { reviewsStatic = value; }


  static ProfileInfo? companyInfoStatic;
  ProfileInfo? get companyInfo => companyInfoStatic;
  set companyInfo(ProfileInfo? value) { companyInfoStatic = value; }

  static List<Request> trashedRequestsStatic = [];
  List<Request> get trashedRequests => trashedRequestsStatic;
  set trashedRequests(List<Request> value) { trashedRequestsStatic = value; }

}

class MyProfilPageInitialState extends MyProfilPageState {
  MyProfilPageInitialState() : super();
}

class MyProfilPageMainState extends MyProfilPageState {
  MyProfilPageMainState() : super();
}

class MyProfilPageErrorState extends MyProfilPageState {
  final ContactError contactError;

  MyProfilPageErrorState({required this.contactError});
}

class MyProfilPageLoadingState extends MyProfilPageState {}

class MyProfilPageNextState extends MyProfilPageState {}