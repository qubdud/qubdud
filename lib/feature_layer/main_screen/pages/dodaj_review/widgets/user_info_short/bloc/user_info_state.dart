part of 'user_info_bloc.dart';

abstract class UserInfoComponentState {
  static AppUser? userStatic;

  AppUser? get user => userStatic;

  set user(AppUser? value) {
    userStatic = value;
  }


  static List<Review> reviewsStatic = [];
  List<Review> get reviews => reviewsStatic;
  set reviews(List<Review> value) {
    reviewsStatic = value;
  }




}

class UserInfoComponentInitialState extends UserInfoComponentState {}

class UserInfoComponentMainState extends UserInfoComponentState {
  final AppUser user;

  UserInfoComponentMainState(this.user);


}


class UserInfoComponentLoadingState extends UserInfoComponentState {}

class UserInfoComponentNextState extends UserInfoComponentState {}
