class ForgotPasswordError {
  final String message;
  final List<String> email;

  ForgotPasswordError({
    required this.message,
    this.email = const [],
  });

  factory ForgotPasswordError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return ForgotPasswordError(
      message: json['message'] ?? '',
      email: _getErrors(errors, 'email'),
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
