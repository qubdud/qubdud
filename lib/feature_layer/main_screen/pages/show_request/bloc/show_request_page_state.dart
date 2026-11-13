part of 'show_request_page_bloc.dart';

abstract class ShowRequestPageState {

  static AppUser? appUserStatic;
  AppUser? get appUser => appUserStatic;
  set appUser(AppUser? value) {
    appUserStatic = value;
  }

  static LatLng? exactLocationStatic;
  LatLng? get exactLocation => exactLocationStatic;
  set exactLocation(LatLng? value) {
    exactLocationStatic = value;
  }




}

class ShowRequestPageMainState extends ShowRequestPageState {}

class ShowRequestPageErrorState extends ShowRequestPageState {}

class ShowRequestPageLoadingState extends ShowRequestPageState {}

class ShowRequestPageNextState extends ShowRequestPageState {}
