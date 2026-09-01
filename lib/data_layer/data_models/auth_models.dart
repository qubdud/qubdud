//Endpoint: Register Data (GET /api/register)

//Endpoint: Register (POST /api/register)

//Endpoint: Forgot Password (POST /api/forgot-password)

class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class ForgotPasswordResponse {
  final String status;
  final int code;

  ForgotPasswordResponse({
    required this.status,
    required this.code,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      status: json['status'],
      code: json['code'],
    );
  }
}


//Endpoint: Verify Reset Password Code (POST /api/verify-reset-password-code)

class VerifyResetPasswordCodeRequest {
  final String token;
  final String email;

  VerifyResetPasswordCodeRequest({
    required this.token,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
    };
  }
}

class VerifyResetPasswordCodeResponse {
  final String status;
  final int code;
  final String message;

  VerifyResetPasswordCodeResponse({
    required this.status,
    required this.code,
    required this.message,
  });

  factory VerifyResetPasswordCodeResponse.fromJson(Map<String, dynamic> json) {
    return VerifyResetPasswordCodeResponse(
      status: json['status'],
      code: json['code'],
      message: json['message'],
    );
  }
}

class VerifyResetPasswordCodeError {
  final String message;
  final Map<String, List<String>> errors;

  VerifyResetPasswordCodeError({
    required this.message,
    required this.errors,
  });

  factory VerifyResetPasswordCodeError.fromJson(Map<String, dynamic> json) {
    return VerifyResetPasswordCodeError(
      message: json['message'],
      errors: Map<String, List<String>>.from(json['errors']),
    );
  }
}

//Endpoint: Reset Password with Code (POST /api/reset-password-with-code)

class ResetPasswordRequest {
  final String token;
  final String email;
  final String password;
  final String passwordConfirmation;

  ResetPasswordRequest({
    required this.token,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class ResetPasswordResponse {
  final String status;
  final int code;
  final String message;

  ResetPasswordResponse({
    required this.status,
    required this.code,
    required this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      status: json['status'],
      code: json['code'],
      message: json['message'],
    );
  }
}

class ResetPasswordError {
  final String message;
  final Map<String, List<String>> errors;

  ResetPasswordError({
    required this.message,
    required this.errors,
  });

  factory ResetPasswordError.fromJson(Map<String, dynamic> json) {
    return ResetPasswordError(
      message: json['message'],
      errors: Map<String, List<String>>.from(json['errors']),
    );
  }
}

// Endpoint: Logout (POST /api/logout)

class LogoutResponse {
  final String status;
  final int code;

  LogoutResponse({
    required this.status,
    required this.code,
  });

  factory LogoutResponse.fromJson(Map<String, dynamic> json) {
    return LogoutResponse(
      status: json['status'],
      code: json['code'],
    );
  }
}
