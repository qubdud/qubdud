part of 'user_info_bloc.dart';

abstract class UserInfoComponentState {

}

class UserInfoComponentInitialState extends UserInfoComponentState {}

class UserInfoComponentMainState extends UserInfoComponentState {

 final AppUser user;

  UserInfoComponentMainState(this.user);


}


class UserInfoComponentLoadingState extends UserInfoComponentState {}

class UserInfoComponentNextState extends UserInfoComponentState {}
