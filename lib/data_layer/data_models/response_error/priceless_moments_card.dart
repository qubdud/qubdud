class PricelessMomentsCardError {
  final String message;
  final List<String> pricelessMomentsCard;

  PricelessMomentsCardError({
    required this.message,
    this.pricelessMomentsCard = const [],
  });

  factory PricelessMomentsCardError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return PricelessMomentsCardError(
      message: json['message'] ?? '',
      pricelessMomentsCard: _getErrors(errors, 'priceless_moments_card'),
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
