import 'package:multiple_result/multiple_result.dart';
import 'package:qb/data_layer/data_models/request/change_pass.dart';
import 'package:qb/data_layer/data_models/request/contact.dart';
import 'package:qb/data_layer/data_models/response_error/change_pass.dart';
import 'package:qb/data_layer/data_models/response_error/contact.dart';
import 'package:qb/domain_layer/domain_models/business_task.dart';
import 'package:qb/domain_layer/domain_models/elearnings.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/request/login.dart';
import '../../data_layer/data_models/request/register.dart';
import '../../data_layer/data_models/request/vote.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response/login.dart';
import '../../data_layer/data_models/response_error/login.dart';
import '../../data_layer/data_models/response_error/register.dart';
import '../domain_models/chat_user.dart';
import '../domain_models/register_data.dart';
import '../domain_models/user_stats.dart';
import '../domain_models/vote.dart';

mixin UserRepositoryMixin {
  AppApi get appApi;

  Future<Result<ApiResponse, String>> sendVote(VoteRequest voteRequest) async {
    final result = await appApi.sendVote(voteRequest.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error');
    }
  }


  Future<Result<VoteData, String>> getVoteData() async {
    final result = await appApi.getVoteData();
    if (result.isSuccess()) {
      return Success(VoteData.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error');
    }
  }

  Future<Result<ElearningData, String>> getUserELearnings() async {
    final result = await appApi.getUserELearnings();
    if (result.isSuccess()) {
      return Success(ElearningData.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error');
    }
  }



  Future<Result<List<ChatUser>, String>> getChatUsers() async {
    final result = await appApi.getChatUsers();
    if (result.isSuccess()) {
      final List<dynamic> jsonData = result.tryGetSuccess()!['data'];
      return Success(jsonData.map((user) => ChatUser.fromJson(user)).toList());
    } else {
      return Error('Error');
    }
  }

  Future<Result<UserStatistics, String>> getUserScore() async {
    final result = await appApi.getUserScore();
    if (result.isSuccess()) {
      return Success(UserStatistics.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error fetching team info');
    }
  }

  Future<Result<List<BusinessTask>, String>> getUserBusinessTasks() async {
    final result = await appApi.getUserBusinessTasks();
    if (result.isSuccess()) {
      final List<dynamic> jsonData = result.tryGetSuccess()!['data'];
      return Success(jsonData.map((user) => BusinessTask.fromJson(user)).toList());
    } else {
      return Error('Error');
    }
  }


  Future<Result<ApiResponse, ContactError>> sendContact(ContactRequest contactRequest) async {
    final result = await appApi.sendContact(contactRequest.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(ContactError.fromJson(result.tryGetError()!));
    }
  }

  Future<Result<ApiResponse, ChangePassError>> changePassword(ChangePassRequest request) async {
    final result = await appApi.changePassword(request.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(ChangePassError.fromJson(result.tryGetError()!));
    }
  }

}
