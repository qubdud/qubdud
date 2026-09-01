part of 'account_page_bloc.dart';

abstract class AccountPageEvent {}

class GetDataAccountPageEvent extends AccountPageEvent {}

class GoToMainAccountPageEvent extends AccountPageEvent {}

class GoToStatisticsAccountPageEvent extends AccountPageEvent {}

class GoToPersonalAccountPageEvent extends AccountPageEvent {}

class GoToPasswordAccountPageEvent extends AccountPageEvent {}

class TryDeleteAccountPageEvent extends AccountPageEvent {}



