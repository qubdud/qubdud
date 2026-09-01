class ContactError {
  final String apimessage;
  final List<String> subject;
  final List<String> message;

  ContactError({
    required this.apimessage,
    this.subject = const [],
    this.message = const [],
  });

  factory ContactError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return ContactError(
      apimessage: json['message'] ?? '',
      subject: _getErrors(errors, 'topic'),
      message: _getErrors(errors, 'message'),
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
