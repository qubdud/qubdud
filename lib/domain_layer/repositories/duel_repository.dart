import 'package:multiple_result/multiple_result.dart';
import 'package:qb/data_layer/data_models/request/challenge.dart';
import 'package:qb/domain_layer/domain_models/challenge.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response_error/challenge.dart';
import '../domain_models/duel.dart';
import '../domain_models/ranks.dart';



mixin DueleRepositoryMixin {
  AppApi get appApi;

  Future<Result<List<Duel>, String>> getDuels() async {
    final result = await appApi.getDuelHistory();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<Duel> duels = data.map((item) => Duel.fromJson(item)).toList();
      return Success(duels);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<DuelSummary, String>> getDuelSummary(int id) async {
    final result = await appApi.getDuelSummary(id);
    if (result.isSuccess()) {
      return Success(DuelSummary.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<DuelQuestion, String>> getDuelQuestion(int id) async {
    final result = await appApi.getDuelQuestion(id);
    if (result.isSuccess()) {
      return Success(DuelQuestion.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error(result.tryGetError()!['message']);
    }
  }

  Future<Result<ApiResponse, String>> storeDuelQuestion(int id, int questionId, int answerId) async {
    final result = await appApi.storeDuelQuestion(id, questionId, answerId);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(result.tryGetError()!['message']);
    }
  }


}
