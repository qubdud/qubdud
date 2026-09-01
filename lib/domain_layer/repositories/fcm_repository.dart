import 'package:multiple_result/multiple_result.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/request/login.dart';
import '../../data_layer/data_models/request/register.dart';
import '../../data_layer/data_models/request/vote.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response/login.dart';
import '../../data_layer/data_models/response_error/login.dart';
import '../../data_layer/data_models/response_error/register.dart';
import '../domain_models/chat_user.dart';
import '../domain_models/vote.dart';

mixin FcmRepositoryMixin {
  AppApi get appApi;

  Future<Result<ApiResponse, String>> storePushToken(String pushToken) async {
    final result = await appApi.registerPushToken(pushToken);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error sending join request');
    }
  }

  Future<Result<ApiResponse, String>> sendChatPush(String token) async {
    final result = await appApi.sendChatPush(token);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error sending join request');
    }
  }


}
