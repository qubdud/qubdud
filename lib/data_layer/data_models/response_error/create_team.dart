class CreateTeamError {
  final String message;
  final List<String> name;

  CreateTeamError({
    required this.message,
    this.name = const [],
  });

  factory CreateTeamError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return CreateTeamError(
      message: json['message'] ?? '',
      name: _getErrors(errors, 'name'),
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
