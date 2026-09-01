import 'package:multiple_result/multiple_result.dart';
import 'package:qb/domain_layer/domain_models/stage.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/request/login.dart';
import '../../data_layer/data_models/request/register.dart';
import '../../data_layer/data_models/request/vote.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response/login.dart';
import '../../data_layer/data_models/response_error/login.dart';
import '../../data_layer/data_models/response_error/register.dart';
import '../domain_models/vote.dart';

mixin StageRepositoryMixin {
  AppApi get appApi;
  Future<Result<StageData, String>> getCurrentStage() async {
    final result = await appApi.getCurrentStage();
    if (result.isSuccess()) {
      return Success(StageData.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error');
    }
  }
}
