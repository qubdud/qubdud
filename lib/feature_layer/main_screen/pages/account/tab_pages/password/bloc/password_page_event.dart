part of 'password_page_bloc.dart';

abstract class PasswordAccountPageEvent {}

class GetDataPasswordAccountPageEvent extends PasswordAccountPageEvent {}

class GoToMainPasswordAccountPageEvent extends PasswordAccountPageEvent {}

class TryChangePasswordAccountPageEvent extends PasswordAccountPageEvent {
  final ChangePassRequest changePassRequest;
  TryChangePasswordAccountPageEvent({required this.changePassRequest});
}
