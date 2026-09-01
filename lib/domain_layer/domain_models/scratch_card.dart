class ScratchCard {
  final int id;
  final String name;
  final String type;
  final String color;
  final String image;
  final int quantityToWin;
  final int currentQuantity;

  ScratchCard({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.image,
    required this.quantityToWin,
    required this.currentQuantity,
  });

  // Factory constructor for creating a ScratchCard from JSON
  factory ScratchCard.fromJson(Map<String, dynamic> json) {
    return ScratchCard(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        color: json['color'],
        image: json['image'],
        quantityToWin: json['quantity_to_win'],
        currentQuantity: json['current_quantity']);
  }

  // Convert a ScratchCard instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'image': image,
    };
  }
}
