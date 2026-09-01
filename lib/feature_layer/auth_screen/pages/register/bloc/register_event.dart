part of 'register_bloc.dart';

abstract class RegisterEvent {}

class TryRegisterEvent extends RegisterEvent {
  final RegisterRequest registerRequest;
  TryRegisterEvent({required this.registerRequest});
}

class GetNipDataEvent extends RegisterEvent {
  final String nip;
  GetNipDataEvent(this.nip);
}


class GetDataRegisterEvent extends RegisterEvent {}

class GoToLoginRegisterEvent extends RegisterEvent {}
