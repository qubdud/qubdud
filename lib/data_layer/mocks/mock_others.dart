import 'package:dio/dio.dart';

import '../../shared/globals.dart';

Response<dynamic> mockOthersResponse(RequestOptions options) {
  if (options.path == '/vote' && options.method == 'POST') {
    final data = options.data;
    if (data != null && data['destination'] is String) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "status": "success",
          "message": "Counters reset successfully",
        },
      );
    }
  }
  if (options.path == '/app') {
    return Response(requestOptions: options, statusCode: 200, data: {
      "status": "Success",
      "code": 200,
      "message": null,
      "data": {
        "appPlatform": {
          "android": {"versionCode": 1, "versionName": "1.0.0", "link": "https://example.com/android"},
          "ios": {"versionCode": 2, "versionName": "1.0.1", "link": "https://example.com/ios"}
        },
        "appModules": [],
        "appCurrentStage": "REGISTER"
      }
    });
  }
  if (options.path == '/login' && options.method == 'POST') {
    final data = options.data;
    if (data != null && data['password'] is String) {
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          "status": "success",
          "message": "Counters reset successfully",
          "data": {"token": "1324"}
        },
      );
    }
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
