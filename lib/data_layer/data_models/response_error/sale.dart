class SaleError {
  final String message;
  final List<String> saleCardType;
  final List<String> lastDigitsOfCard;
  final List<String> saleWeek;
  final List<String> saleMonth;

  SaleError({
    required this.message,
    this.saleCardType = const [],
    this.lastDigitsOfCard = const [],
    this.saleWeek = const [],
    this.saleMonth = const [],
  });

  factory SaleError.fromJson(Map<String, dynamic> json) {
    final errors = json['errors'] as Map<String, dynamic>? ?? {};
    return SaleError(
      message: json['message'] ?? '',
      saleCardType: _getErrors(errors, 'sale_card_type'),
      lastDigitsOfCard: _getErrors(errors, 'last_digits_of_card'),
      saleWeek: _getErrors(errors, 'sale_week'),
      saleMonth: _getErrors(errors, 'sale_month'),
    );
  }

  /// Helper method to extract and convert errors
  static List<String> _getErrors(Map<String, dynamic> errors, String field) {
    final fieldErrors = errors[field];
    if (fieldErrors is List) {
      return List<String>.from(fieldErrors);
    }
    return []; // Return an empty list if no errors
  }
}
