class ApiResponse<T> {
  final String? status;
  final int? code;
  final String? message;
  final dynamic data;
  final dynamic errors;

  ApiResponse({this.status, this.code, this.message, this.data, this.errors});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ApiResponse(
      status: json['status'],
      code: json['code'],
      message: json['message'],
      data: json['data'],
      errors: json['errors'],
    );
  }
}
