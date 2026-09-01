class RegisterRequest {
  final List<AgreementSelection> agreements; // 🔥 Lista zgód zamiast mapy
  final String firstName;
  final String lastName;
  final String email;
  final String emailConfirmation;
  final String password;
  final String passwordConfirmation;
  final String countryId;

  RegisterRequest({
    required this.agreements,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailConfirmation,
    required this.password,
    required this.passwordConfirmation,
    required this.countryId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'email_confirmation': emailConfirmation,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'country_id': countryId,
    };

    for (var agreement in agreements) {
      if (agreement.value != null) {
        json.putIfAbsent(agreement.id, () => agreement.value!);
      }
    }

    return json;
  }
}

class AgreementSelection {
  final String id; // np. "agreement_1"
  bool? value; // true, false lub null

  AgreementSelection({required this.id, this.value});
}
