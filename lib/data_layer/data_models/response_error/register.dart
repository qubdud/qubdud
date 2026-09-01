class RegisterError {
  final String message;
  final Map<String, List<String>> agreementErrors; // 🔥 Dynamiczne błędy dla agreements
  final List<String> firstName;
  final List<String> lastName;
  final List<String> email;
  final List<String> emailConfirmation;
  final List<String> password;
  final List<String> passwordConfirmation;
  final List<String> countryId;

  RegisterError({
    required this.message,
    this.agreementErrors = const {}, // 🔥 Dynamiczne błędy
    this.firstName = const [],
    this.lastName = const [],
    this.email = const [],
    this.emailConfirmation = const [],
    this.password = const [],
    this.passwordConfirmation = const [],
    this.countryId = const [],
  });

  factory RegisterError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};

    // 🔥 Pobieramy dynamiczne błędy agreements
    final agreementErrors = errors.entries
        .where((entry) => entry.key.startsWith('agreement')) // ✅ Pobiera tylko błędy dla agreements
        .map((entry) => MapEntry(entry.key, _getErrors(errors, entry.key)))
        .toMap(); // 🔥 Konwersja do Map<String, List<String>>

    return RegisterError(
      message: json['message'] ?? '',
      agreementErrors: agreementErrors,
      firstName: _getErrors(errors, 'first_name'),
      lastName: _getErrors(errors, 'last_name'),
      email: _getErrors(errors, 'email'),
      emailConfirmation: _getErrors(errors, 'email_confirmation'),
      password: _getErrors(errors, 'password'),
      passwordConfirmation: _getErrors(errors, 'password_confirmation'),
      countryId: _getErrors(errors, 'country_id'),
    );
  }

  /// Helper method to extract and convert errors
  static List<String> _getErrors(Map<String, dynamic> errors, String field) {
    final fieldErrors = errors[field];
    if (fieldErrors is List) {
      return List<String>.from(fieldErrors);
    }
    return []; // Zwracamy pustą listę, jeśli brak błędów
  }
}

extension MapEntryExtension<K, V> on Iterable<MapEntry<K, V>> {
  /// Konwertuje Listę `MapEntry` na `Map<K, V>`
  Map<K, V> toMap() {
    return {for (var entry in this) entry.key: entry.value};
  }
}
