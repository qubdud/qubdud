class LoginError {
  final int statusCode;
  final String message;
  final List<String> email;
  final List<String> password;

  LoginError({
    required this.message,
    this.email = const [],
    this.password = const [],
    this.statusCode = 0,
  });

  factory LoginError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return LoginError(
      message: json['message'] ?? '',
      email: _getErrors(errors, 'email'),
      password: _getErrors(errors, 'password'),
      statusCode: json['status_code'] ?? '',
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
