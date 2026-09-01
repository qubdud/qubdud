class ChallengeError {
  final int statusCode;
  final String message;
  final List<String> public;
  final List<String> copyright;
  final List<String> description;
  final List<String> files;


  ChallengeError({
    required this.message,
    this.public = const [],
    this.copyright = const [],
    this.description = const [],
    this.files = const [],

    this.statusCode = 0,
  });

  factory ChallengeError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return ChallengeError(
      message: json['message'] ?? '',
      public: _getErrors(errors, 'public'),
      copyright: _getErrors(errors, 'copyright_consent'),
      description: _getErrors(errors, 'description'),
      files: _getErrors(errors, 'photo_files'),
      statusCode: json['status_code'] ?? 0,
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
