import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class AppUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? bio;
  /// Czym są terminy w kalendarzu (konsultacja, strzyżenie, rozmowa…)
  final String? slotsInfo;
  final String? www;
  final String? contactEmail;
  /// firma decyduje, co pokazać publicznie (domyślnie: wszystko)
  final bool showPhone;
  final bool showAddress;
  final bool? firma;
  final String? nip;
  final String? companyName;
  final String? companyCategory;
  final String? companySector;
  final LatLng? companyLocation;
  final String? companyCity;
  final Map<String, dynamic>? companyAddress;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.bio,
    this.slotsInfo,
    this.www,
    this.contactEmail,
    this.showPhone = true,
    this.showAddress = true,
    this.firma,
    this.nip,
    this.companyName,
    this.companyCategory,
    this.companySector,
    this.companyLocation,
    this.companyCity,
    this.companyAddress,
    this.createdAt,
  });



  /// [contact] — users/{uid}/private/contact; bez niego zostają pola jawne
  /// (telefon firmy, u kont sprzed migracji także klienta).
  /// [contactDenied] — brak dostępu do private/contact: bez jawnych pól poza telefonem firmy.
  factory AppUser.fromDoc(DocumentSnapshot doc,
      {Map<String, dynamic>? contact, bool contactDenied = false}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final loc = data['companyLocation'] ?? {};
    final isFirma = (data['firma'] as bool?) ?? (data['isCompany'] as bool?) ?? false;

    return AppUser(
      id: doc.id,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: contactDenied ? null : _nonEmpty(contact?['email']) ?? data['email'] as String?,
      phone: contactDenied && !isFirma
          ? null
          : _nonEmpty(contact?['phone']) ?? data['phone'] as String?,
      bio: data['bio'] as String?,
      slotsInfo: data['slotsInfo'] as String?,
      www: data['www'] as String?,
      contactEmail: data['contactEmail'] as String?,
      showPhone: data['showPhone'] != false,
      showAddress: data['showAddress'] != false,
      firma: (data['firma'] as bool?) ?? (data['isCompany'] as bool?) ?? false,
      nip: data['nip'] as String?,
      companyName: data['companyName'] as String?,
      companyCategory: data['companyCategory'] as String?,
      companySector: data['companySector'] as String?,
      companyLocation: LatLng(
        (loc['lat'] ?? 0.0).toDouble(),
        (loc['lng'] ?? 0.0).toDouble(),
      ),
      companyCity: data['companyCity'] as String?,
      companyAddress: data['companyAddress'] == null
          ? null
          : Map<String, dynamic>.from(data['companyAddress']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  get displayName => companyName??firstName;

  Map<String, dynamic> toMap() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (bio != null) 'bio': bio,
      if (slotsInfo != null) 'slotsInfo': slotsInfo,
      'firma': firma ?? false,
      'isCompany': firma ?? false,
      if (nip != null) 'nip': nip,
      if (companyName != null) 'companyName': companyName,
      if (companyCategory != null) 'companyCategory': companyCategory,
      if (companySector != null) 'companySector': companySector,
      if (companyLocation != null) 'companyLocation': {
        'lat': companyLocation!.latitude,
        'lng': companyLocation!.longitude,
      },
      if (companyCity != null) 'companyCity': companyCity,
      if (companyAddress != null) 'companyAddress': companyAddress,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;
