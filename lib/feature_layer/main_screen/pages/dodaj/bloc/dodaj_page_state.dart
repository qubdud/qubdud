part of 'dodaj_page_bloc.dart';

abstract class DodajPageState {

  static RequestMetadata? requestMetadataStatic;
  RequestMetadata? get requestMetadata => requestMetadataStatic;
  set requestMetadata(RequestMetadata? value) {
  requestMetadataStatic = value;
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


}

class DodajPageMainState extends DodajPageState {}





class DodajPageErrorState extends DodajPageState {}
class DodajPageLoadingState extends DodajPageState {}
class DodajPageUploadingState extends DodajPageState {
  final double progress; // 0.0 - 1.0
  DodajPageUploadingState(this.progress);
}


class DodajPagePromoState extends DodajPageState {}

class DodajRequestPromoState extends DodajPageState {
final String thumbPath;

  DodajRequestPromoState(this.thumbPath);

}


class DodajPageNextState extends DodajPageState {}

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
