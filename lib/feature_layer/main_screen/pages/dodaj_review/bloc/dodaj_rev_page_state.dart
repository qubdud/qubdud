part of 'dodaj_rev_page_bloc.dart';

abstract class DodajReviewPageState {

  static RequestMetadata? requestMetadataStatic;
  RequestMetadata? get requestMetadata => requestMetadataStatic;
  set requestMetadata(RequestMetadata? value) {
  requestMetadataStatic = value;
  }

  static PromoMetadata? promoMetadataStatic;
  PromoMetadata? get promoMetadata => promoMetadataStatic;
  set promoMetadata(PromoMetadata? value) {
    promoMetadataStatic = value;
  }

  static ReviewMetadata? reviewMetadataStatic;
  ReviewMetadata? get reviewMetadata => reviewMetadataStatic;
  set reviewMetadata(ReviewMetadata? value) {
    reviewMetadataStatic = value;
  }


  static AppUser? appUserStatic;
  AppUser? get appUser => appUserStatic;
  set appUser(AppUser? value) {
    appUserStatic = value;
  }



  static SelectedContent? selectedContentStatic;
  SelectedContent? get selectedContent => selectedContentStatic;
  set selectedContent(SelectedContent? value) {
    selectedContentStatic = value;
  }


  static List<Review> reviewsStatic = [];
  List<Review> get reviews => reviewsStatic;
  set reviews(List<Review> value) {
    reviewsStatic = value;
  }

}

class DodajReviewPageMainState extends DodajReviewPageState {}





class DodajReviewPageErrorState extends DodajReviewPageState {}

class DodajReviewShowPageState extends DodajReviewPageState {}



class DodajReviewPageLoadingState extends DodajReviewPageState {}
class DodajReviewPageUploadingState extends DodajReviewPageState {
  final double progress; // 0.0 - 1.0
  DodajReviewPageUploadingState(this.progress);
}


class DodajReviewPagePromoState extends DodajReviewPageState {}

class DodajRequestPromoState extends DodajReviewPageState {
final String thumbPath;
  DodajRequestPromoState(this.thumbPath);
}



class DodajReviewPageNextState extends DodajReviewPageState {}

class RequestMetadata  {
  final String category;
  final String sector;
  final LatLng location;
  final String city;
  final String description;
  final bool is24;
  RequestMetadata({
    required this.category,
    required this.sector,
    required this.location,
    required this.city,
    required this.description,
    required this.is24,
  });
}

class PromoMetadata  {
  final String category;
  final String sector;
  final LatLng location;
  final String description;
  PromoMetadata({
    required this.category,
    required this.sector,
    required this.location,
    required this.description,
  });
}

class SelectedContent  {
  final File file;
  final String fileType;
  final String selectType;
  SelectedContent({
    required this.file,
    required this.fileType,
    required this.selectType,
  });
}


class ReviewMetadata  {
  final int score;
  final String description;
  ReviewMetadata({
    required this.score,
    required this.description,
  });
}
