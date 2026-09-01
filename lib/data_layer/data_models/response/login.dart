class LoginResponse {
  final String status;
  final String code;
  final String message;
  final String token;

  LoginResponse({
    required this.status,
    required this.code,
    required this.message,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'],
      code: json['code'] ?? '',
      message: json['message'],
      token: json['data']['token'],
    );
  }
}
