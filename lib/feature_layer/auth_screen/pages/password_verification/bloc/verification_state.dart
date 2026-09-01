part of 'verification_bloc.dart';

abstract class VerificationState {
}

class VerificationInitialState extends VerificationState {
  VerificationInitialState() : super();
}

class VerificationMainState extends VerificationState {
  VerificationMainState() : super();
}

class VerificationErrorState extends VerificationState {}

class VerificationLoadingState extends VerificationState {}

class VerificationBackState extends VerificationState {}

class VerificationNextState extends VerificationState {}
