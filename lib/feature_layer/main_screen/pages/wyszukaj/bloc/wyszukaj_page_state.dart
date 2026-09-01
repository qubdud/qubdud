part of 'wyszukaj_page_bloc.dart';

abstract class WyszukajPageState {

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

}

class WyszukajPageMainState extends WyszukajPageState {}

class WyszukajPageErrorState extends WyszukajPageState {}

class WyszukajPageLoadingState extends WyszukajPageState {}

class WyszukajPageResultsState extends WyszukajPageState {}
