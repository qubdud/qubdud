class SaleRequest {
  final String saleCardType;
  final String lastDigitsOfCard;
  final String saleWeek;
  final String saleMonth;

  SaleRequest({
    required this.saleCardType,
    required this.lastDigitsOfCard,
    required this.saleWeek,
    required this.saleMonth,
  });

  Map<String, dynamic> toJson() {
    return {
      'sale_card_type': saleCardType,
      'last_digits_of_card': lastDigitsOfCard,
      'sale_week': saleWeek,
      'sale_month': saleMonth,
    };
  }
}
