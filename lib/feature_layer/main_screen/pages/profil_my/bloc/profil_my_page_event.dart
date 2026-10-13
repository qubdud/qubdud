part of 'profil_my_page_bloc.dart';

abstract class MyProfilPageEvent {}

class GetDataMyProfilPageEvent extends MyProfilPageEvent {}

class GoToMainMyProfilPageEvent extends MyProfilPageEvent {}

class TryDeleteMyPromoProfilPageEvent extends MyProfilPageEvent {
  final String id;
  TryDeleteMyPromoProfilPageEvent({required this.id });
}


class TryDeleteMyReviewProfilPageEvent extends MyProfilPageEvent {
  final String id;
  TryDeleteMyReviewProfilPageEvent({required this.id});
}

/// [phone]/[bio] = null — pole nie jest zapisywane (u konta firmowego
/// w trybie użytkownika należy do profilu firmy).
class UpdateUserDataEvent extends MyProfilPageEvent {
  final String firstName;
  final String lastName;
  final String? phone;
  final String? bio;
  UpdateUserDataEvent({required this.firstName, required this.lastName, this.phone, this.bio});
}

class UpdateCompanyDataEvent extends MyProfilPageEvent {
  final String companyName;
  final String bio;
  final String phone;
  final String companyCity;
  final LatLng? companyLocation;
  final Map<String, String> companyAddress;
  final String www;
  final String contactEmail;
  final bool showPhone;
  final bool showAddress;
  UpdateCompanyDataEvent({
    this.www = '',
    this.contactEmail = '',
    this.showPhone = true,
    this.showAddress = true,
    required this.companyName,
    required this.bio,
    required this.phone,
    required this.companyCity,
    required this.companyLocation,
    required this.companyAddress,
  });
}

class TryRestoreFromTrashEvent extends MyProfilPageEvent {
  final String requestId;
  TryRestoreFromTrashEvent(this.requestId);
}

class TryDeleteFromTrashEvent extends MyProfilPageEvent {
  final String requestId;
  TryDeleteFromTrashEvent(this.requestId);
}