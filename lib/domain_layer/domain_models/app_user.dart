import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class AppUser {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? bio;
  final bool? firma;
  final String? nip;
  final String? companyName;
  final String? companyCategory;
  final String? companySector;
  final LatLng? companyLocation;
  final String? companyCity;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.bio,
    this.firma,
    this.nip,
    this.companyName,
    this.companyCategory,
    this.companySector,
    this.companyLocation,
    this.companyCity,
    this.createdAt,
  });



  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final loc = data['companyLocation'] ?? {};




    return AppUser(
      id: doc.id,
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      bio: data['bio'] as String?,
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
      createdAt:  (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  get displayName => companyName??firstName;

  Map<String, dynamic> toMap() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (email != null) 'email': email,
      'firma': firma??false,
      if (nip != null) 'nip': nip,
      if (companyName != null) 'companyName': companyName,
      if (companyCategory != null) 'companyCategory': companyCategory,
      if (companySector != null) 'companySector': companySector,
      if (companyLocation != null) 'companyLocation': {
        'lat': companyLocation!.latitude??0,
        'lng': companyLocation!.longitude??0,
      },
      if (companyCity != null) 'companyCity': companyCity,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}