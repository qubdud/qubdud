part of 'verification_bloc.dart';

abstract class VerificationEvent {}

class TryVerificationEvent extends VerificationEvent {}

class GetDataVerificationEvent extends VerificationEvent {}

class GoToLoginVerificationEvent extends VerificationEvent {}
