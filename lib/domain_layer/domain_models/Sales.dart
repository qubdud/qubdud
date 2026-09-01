class SaleHistory {
  final String id;
  final String month;
  final String week;
  final String saleCardType;
  final String lastDigitsOfCard;
  final double pointsForSale;
  final String transactionality;
  final bool activity;
  final int tokenized;
  final String status;

  SaleHistory({
    required this.id,
    required this.month,
    required this.week,
    required this.saleCardType,
    required this.lastDigitsOfCard,
    required this.pointsForSale,
    required this.transactionality,
    required this.activity,
    required this.tokenized,
    required this.status,
  });

  factory SaleHistory.fromJson(Map<String, dynamic> json) {
    return SaleHistory(
      id: json['id'],
      month: json['month'],
      week: json['week'],
      saleCardType: json['sale_card_type'],
      lastDigitsOfCard: json['last_digits_of_card'],
      pointsForSale: double.parse(json['points_for_sale']),
      transactionality: json['transactionality'],
      activity: json['activity'],
      tokenized: json['tokenized'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'week': week,
      'sale_card_type': saleCardType,
      'last_digits_of_card': lastDigitsOfCard,
      'points_for_sale': pointsForSale.toString(),
      'transactionality': transactionality,
      'activity': activity,
      'tokenized': tokenized,
      'status': status,
    };
  }
}

class SaleCardType {
  final String id;
  final String name;
  final String type;
  final double pointsForSale;

  SaleCardType({
    required this.id,
    required this.name,
    required this.type,
    required this.pointsForSale,
  });

  factory SaleCardType.fromJson(Map<String, dynamic> json) {
    return SaleCardType(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      pointsForSale: double.parse(json['points_for_sale']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'points_for_sale': pointsForSale.toString(),
    };
  }
}

class SaleWeek {
  final String id;
  final String from;
  final String to;
  final String period;

  SaleWeek({
    required this.id,
    required this.from,
    required this.to,
    required this.period,
  });

  factory SaleWeek.fromJson(Map<String, dynamic> json) {
    return SaleWeek(
      id: json['id'],
      from: json['from'],
      to: json['to'],
      period: json['period'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'period': period,
    };
  }
}

class SaleMonth {
  final int id;
  final String uuid;
  final bool isCurrent;
  final String name;
  final String start;
  final String end;

  SaleMonth({
    required this.id,
    required this.uuid,
    required this.isCurrent,
    required this.name,
    required this.start,
    required this.end,
  });

  factory SaleMonth.fromJson(Map<String, dynamic> json) {
    return SaleMonth(
      id: json['id'],
      uuid: json['uuid'],
      isCurrent: json['is_current'],
      name: json['name'],
      start: json['start'],
      end: json['end'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'is_current': isCurrent,
      'name': name,
      'start': start,
      'end': end,
    };
  }
}

class SaleStatus {
  final String status;

  SaleStatus({required this.status});

  factory SaleStatus.fromJson(String json) {
    return SaleStatus(status: json);
  }

  String toJson() {
    return status;
  }
}

class SaleData {
  final List<SaleHistory> history;
  final List<SaleCardType> saleCardTypes;
  final List<SaleWeek> saleWeeks;
  final List<SaleMonth> saleMonths;
  final List<SaleMonth> allMonths;
  final List<String> statuses;

  SaleData({
    required this.history,
    required this.saleCardTypes,
    required this.saleWeeks,
    required this.saleMonths,
    required this.allMonths,
    required this.statuses,
  });

  factory SaleData.fromJson(Map<String, dynamic> json) {
    return SaleData(
      history: (json['history'] as List<dynamic>).map((e) => SaleHistory.fromJson(e as Map<String, dynamic>)).toList(),
      saleCardTypes: (json['sale_card_types'] as List<dynamic>).map((e) => SaleCardType.fromJson(e as Map<String, dynamic>)).toList(),
      saleWeeks: (json['sale_weeks'] as List<dynamic>).map((e) => SaleWeek.fromJson(e as Map<String, dynamic>)).toList(),
      saleMonths: (json['sale_months'] as List<dynamic>).map((e) => SaleMonth.fromJson(e as Map<String, dynamic>)).toList(),
      allMonths: (json['all_months'] as List<dynamic>).map((e) => SaleMonth.fromJson(e as Map<String, dynamic>)).toList(),
      statuses: List<String>.from(json['statuses'] as List<dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'history': history.map((e) => e.toJson()).toList(),
      'sale_card_types': saleCardTypes.map((e) => e.toJson()).toList(),
      'sale_weeks': saleWeeks.map((e) => e.toJson()).toList(),
      'sale_months': saleMonths.map((e) => e.toJson()).toList(),
      'all_months': allMonths.map((e) => e.toJson()).toList(),
      'statuses': statuses,
    };
  }
}
