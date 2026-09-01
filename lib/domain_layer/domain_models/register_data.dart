import 'country.dart';

class RegisterData {
  final List<Country> countries;
  final List<Agreement> agreements; // 🔥 Teraz to jest lista!

  RegisterData({required this.countries, required this.agreements});

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;

    return RegisterData(
      countries: data?['countries'] != null ? (data!['countries'] as List<dynamic>).map((e) => Country.fromJson(e)).toList() : [],
      agreements: data?['agreements'] != null ? (data!['agreements'] as Map<String, dynamic>).entries.map((entry) => Agreement.fromJson(entry.key, entry.value)).toList() : [],
    );
  }
}

class Agreement {
  final String id; // 🔥 Teraz mamy ID agreementu
  final int mustBeAccepted;
  final String text;
  final String label;

  Agreement({required this.id, required this.mustBeAccepted, required this.text, required this.label});

  factory Agreement.fromJson(String id, Map<String, dynamic> json) {
    return Agreement(
      id: id, // 🔥 Przekazujemy ID jako klucz z JSON-a
      mustBeAccepted: json['must_be_accepted'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
class RegisterNipData {
  final String companyName;
  final String registerStreet;
  final String registerBuildingNr;
  final String registerFlatNr;
  final String registerCity;
  final String registerPostCode;

  RegisterNipData({
    required this.companyName,
    required this.registerStreet,
    required this.registerBuildingNr,
    required this.registerFlatNr,
    required this.registerCity,
    required this.registerPostCode,
  });

  factory RegisterNipData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return RegisterNipData(
      companyName: data['company_name'] ?? '',
      registerStreet: data['register_street'] ?? '',
      registerBuildingNr: data['register_building_nr'] ?? '',
      registerFlatNr: data['register_flat_nr'] ?? '',
      registerCity: data['register_city'] ?? '',
      registerPostCode: data['register_post_code'] ?? '',
    );
  }
}