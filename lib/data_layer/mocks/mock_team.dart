import 'package:dio/dio.dart';

Response<dynamic> mockTeamResponse(RequestOptions options) {
  if (options.path == '/team/create' && options.method == 'POST') {
    final data = options.data;
    if (data != null && data is Map<String, dynamic> && (data['name'] as String).length > 8) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "status": "success",
          "message": "Team OK",
        },
      );
    } else {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {
            "status": "error",
            "message": "Invalid request data: ${data?['name'] ?? 'null'}",
            "errors": {
              "name": ["Nazwa musi miec 8 znakow dlugosci.."]
            }
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }
  }

  if (options.path == '/team/score' && options.method == 'GET') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        "detail_stats": [
          {"name": "Business tasks", "points": 572},
          {"name": "Duels", "points": 77},
          {"name": "Challenges", "points": 350},
          {"name": "Educational tasks", "points": 204}
        ],
        "points": 1203,
        "rank": 5
      },
    );
  }

  if (options.path == '/team/info' && options.method == 'GET') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {"id": "123", "name": "Awesome Team", "points": 1500, "ranking": 1, "camperType": 1, "camperColor": 2},
    );
  }

  if (options.path == '/team/members' && options.method == 'GET') {
    return Response(requestOptions: options, statusCode: 200, data: [
      {"name": "John Doe", "countryCode": "HR", "department": "Sales", "departmentGroup": "OT", "points": 450},
      {"name": "Jane Smith", "countryCode": "GR", "department": "Commercial", "departmentGroup": "OT", "points": 780},
      {"name": "Mark Johnson", "countryCode": "HU", "department": "Marketing", "departmentGroup": "OT", "points": 320},
      {"name": "Emily Davis", "countryCode": "IT", "department": "Products", "departmentGroup": "OT", "points": 540},
      {"name": "Michael Brown", "countryCode": "PL", "department": "Corporate & Control", "departmentGroup": "OT", "points": 610},
      {"name": "Laura Wilson", "countryCode": "RS", "department": "Sales", "departmentGroup": "OT", "points": 200},
      {"name": "James Taylor", "countryCode": "SK", "department": "IT", "departmentGroup": "IT", "points": 750},
      {"name": "Olivia Martinez", "countryCode": "SI", "department": "IT", "departmentGroup": "IT", "points": 690},
      {"name": "William Anderson", "countryCode": "HR", "department": "Operations", "departmentGroup": "OP", "points": 410},
      {"name": "Sophia Thomas", "countryCode": "GR", "department": "Operations", "departmentGroup": "OP", "points": 370},
      {"name": "Daniel White", "countryCode": "HU", "department": "Operations", "departmentGroup": "OP", "points": 680},
      {"name": "Mia Harris", "countryCode": "IT", "department": "Marketing", "departmentGroup": "OT", "points": 150},
      {"name": "Ethan Lewis", "countryCode": "PL", "department": "Products", "departmentGroup": "OT", "points": 520},
      {"name": "Charlotte Walker", "countryCode": "RS", "department": "Corporate & Control", "departmentGroup": "OT", "points": 300}
    ]);
  }

  if (options.path == '/team/stickers' && options.method == 'GET') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        "stickers": ["poland", "italy", "czech"]
      },
    );
  }

  throw DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 400,
      data: {
        "status": "error",
        "message": "Invalid request data",
      },
    ),
    type: DioExceptionType.badResponse,
  );
}
