class PricelessMomentsCardRequest {
  final String pricelessMomentsCard;

  PricelessMomentsCardRequest({
    required this.pricelessMomentsCard,
  });

  Map<String, dynamic> toJson() {
    return {
      'priceless_moments_card': pricelessMomentsCard,
    };
  }
}
