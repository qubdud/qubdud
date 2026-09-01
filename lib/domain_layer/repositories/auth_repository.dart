import 'package:multiple_result/multiple_result.dart';
import 'package:qb/data_layer/data_models/auth_models.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/request/login.dart';
import '../../data_layer/data_models/request/register.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response/login.dart';
import '../../data_layer/data_models/response_error/forgot_pass.dart';
import '../../data_layer/data_models/response_error/login.dart';
import '../../data_layer/data_models/response_error/register.dart';
import '../domain_models/register_data.dart';

mixin AuthRepositoryMixin {
  AppApi get appApi;

  Future<Result<LoginResponse, LoginError>> login(LoginRequest loginRequest) async {
    final result = await appApi.login(loginRequest.toJson());
    if (result.isSuccess()) {
      return Success(LoginResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(LoginError.fromJson(result.tryGetError()!));
    }
  }

  Future<Result<ApiResponse, RegisterError>> register(RegisterRequest request) async {
    final result = await appApi.register(request.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(RegisterError.fromJson(result.tryGetError()!));
    }
  }

  Future<Result<RegisterNipData, String>> getRegisterNipData(String nip) async {
    final result = await appApi.getRegisterNIPData(nip);
    if (result.isSuccess()) {
      dynamic data = result.tryGetSuccess()!;
      return Success(RegisterNipData.fromJson(data));
    } else {
      dynamic data = result.tryGetError()!;
      return Error(data['message']);
    }
  }


  Future<Result<RegisterData, String>> getRegisterData() async {
    final result = await appApi.getRegisterData();
    if (result.isSuccess()) {
      dynamic data = result.tryGetSuccess()!;
      return Success(RegisterData.fromJson(data));
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<ApiResponse, ForgotPasswordError>> forgotPassword(ForgotPasswordRequest request) async {
    final result = await appApi.forgotPassword(request.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(ForgotPasswordError.fromJson(result.tryGetError()!));
    }
  }



}
