part of 'profil_user_page_bloc.dart';

abstract class ProfilUserPageState {}

class ProfilUserPageInitialState extends ProfilUserPageState {
  ProfilUserPageInitialState() : super();
}

class ProfilUserPageMainState extends ProfilUserPageState {
  ProfilUserPageMainState() : super();
}

class ProfilUserPageErrorState extends ProfilUserPageState {
  final ContactError contactError;

  ProfilUserPageErrorState({required this.contactError});
}

class ProfilUserPageLoadingState extends ProfilUserPageState {}

class ProfilUserPageNextState extends ProfilUserPageState {}
