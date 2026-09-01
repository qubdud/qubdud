class SaleResult {
  final int id;
  final DateTime from;
  final DateTime to;
  final String name;
  final bool active;
  final SalesIndividual individual;
  final SalesBusiness business;
  final SalesBusiness tokenized;

  SaleResult({
    required this.id,
    required this.from,
    required this.to,
    required this.name,
    required this.active,
    required this.individual,
    required this.business,
    required this.tokenized,
  });

  factory SaleResult.fromJson(Map<String, dynamic> json) {
    return SaleResult(
      id: json['id'],
      from: DateTime.parse(json['from']),
      to: DateTime.parse(json['to']),
      name: json['name'],
      active: json['active'],
      individual: SalesIndividual.fromJson(json['individual']),
      business: SalesBusiness.fromJson(json['business']),
      tokenized: SalesBusiness.fromJson(json['tokenized']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
      'name': name,
      'active': active,
      'individual': individual.toJson(),
      'business': business.toJson(),
    };
  }
}

class SalesIndividual {
  final String name;
  final int saleCount;
  final String percentage;
  final List<SalesThreshold> thresholds;

  SalesIndividual({
    required this.name,
    required this.saleCount,
    required this.percentage,
    required this.thresholds,
  });

  factory SalesIndividual.fromJson(Map<String, dynamic> json) {
    return SalesIndividual(
      name: json['name'],
      saleCount: json['sale_count'],
      percentage: json['percentage'],
      thresholds: (json['thresholds'] as List).map((item) => SalesThreshold.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sale_count': saleCount,
      'percentage': percentage,
      'thresholds': thresholds.map((item) => item.toJson()).toList(),
    };
  }
}

class SalesThreshold {
  int quantity;
  final int points;
  final SalesThresholdLabels labels;

  SalesThreshold({
    required this.quantity,
    required this.points,
    required this.labels,
  });

  factory SalesThreshold.fromJson(Map<String, dynamic> json) {
    return SalesThreshold(
      quantity: json['quantity'],
      points: json['points'],
      labels: SalesThresholdLabels.fromJson(json['labels']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'points': points,
      'labels': labels.toJson(),
    };
  }
}

class SalesThresholdLabels {
  final String label1;
  final String label2;

  SalesThresholdLabels({
    required this.label1,
    required this.label2,
  });

  factory SalesThresholdLabels.fromJson(Map<String, dynamic> json) {
    return SalesThresholdLabels(
      label1: json['label_1'],
      label2: json['label_2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label_1': label1,
      'label_2': label2,
    };
  }
}

class SalesBusiness {
  final String name;
  final int saleCount;
  final String label1;
  final String label2;

  SalesBusiness({
    required this.name,
    required this.saleCount,
    required this.label1,
    required this.label2,
  });

  factory SalesBusiness.fromJson(Map<String, dynamic> json) {
    return SalesBusiness(
      name: json['name'],
      saleCount: json['sale_count'],
      label1: json['label_1'],
      label2: json['label_2'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sale_count': saleCount,
      'label_1': label1,
      'label_2': label2,
    };
  }
}
