class ChangePassError {
  final String message;
  final List<String> oldPassword;
  final List<String> password;
  final List<String> passwordConfiration;

  ChangePassError({
    required this.message,
    this.oldPassword = const [],
    this.password = const [],
    this.passwordConfiration = const [],
  });

  factory ChangePassError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return ChangePassError(
      message: json['message'] ?? '',
      oldPassword: _getErrors(errors, 'old_password'),
      password: _getErrors(errors, 'password'),
      passwordConfiration: _getErrors(errors, 'password_confirmation'),
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
