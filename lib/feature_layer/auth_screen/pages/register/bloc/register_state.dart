part of 'register_bloc.dart';

abstract class RegisterState {

  static RegisterData? registerDataStatic;
  RegisterData? get registerData => registerDataStatic;
  set registerData(RegisterData? value) {
    registerDataStatic = value;
  }

  static RegisterNipData? registerNipDataStatic;
  RegisterNipData? get registerNipData => registerNipDataStatic;
  set registerNipData(RegisterNipData? value) {
    registerNipDataStatic = value;
  }

}

class RegisterInitialState extends RegisterState {
  RegisterInitialState() : super();
}

class RegisterMainState extends RegisterState {
  RegisterMainState() : super();
}

class RegisterErrorState extends RegisterState {
  final RegisterError registerError;

  RegisterErrorState({required this.registerError});
}

class RegisterNipLoadedState extends RegisterState {}

class RegisterNipFailState extends RegisterState {
  String message;

  RegisterNipFailState(this.message);
}


class RegisterLoadingState extends RegisterState {}

class RegisterBackState extends RegisterState {}

class RegisterNextState extends RegisterState {}
