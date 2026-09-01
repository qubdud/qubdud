class Institution {
  final String id;
  final String address;

  Institution({
    required this.id,
    required this.address,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    return Institution(
      id: json['id'],
      address: json['address'],
    );
  }
}
