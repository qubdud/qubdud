import 'package:dio/dio.dart';

Response<dynamic> mockNotificationsResponse(RequestOptions options) {
  if (options.path == '/notifications/counters/reset' && options.method == 'POST') {
    final data = options.data;
    if (data != null && data['counters'] is List) {
      List<String> countersToReset = List<String>.from(data['counters']);
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "status": "success",
          "message": "Counters reset successfully",
          "reset_counters": countersToReset,
        },
      );
    }
  }
  if (options.path == '/notifications/counters' && options.method == 'GET') {
    return Response(
      requestOptions: options,
      statusCode: 200,
      data: {
        "status": "success",
        "message": "Counters fetched successfully",
        "data": {"news": 5, "notifications": 12}
      },
    );
  }

  return Response(
    requestOptions: options,
    statusCode: 400,
    data: {
      "status": "error",
      "message": "Invalid request data",
    },
  );
}
