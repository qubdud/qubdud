import 'dart:async';

import 'package:multiple_result/multiple_result.dart';
import 'package:qb/domain_layer/repositories/auth_repository.dart';
import 'package:qb/domain_layer/repositories/challenge_repository.dart';
import 'package:qb/domain_layer/repositories/duel_repository.dart';
import 'package:qb/domain_layer/repositories/fcm_repository.dart';
import 'package:qb/domain_layer/repositories/notification_repository.dart';
import 'package:qb/domain_layer/repositories/stage_repository.dart';
import 'package:qb/domain_layer/repositories/team_repository.dart';
import 'package:qb/domain_layer/repositories/user_repository.dart';


import '../data_layer/api.dart';
import 'domain_models/app_data.dart';

class AppRepository with AuthRepositoryMixin,DueleRepositoryMixin,ChallengeRepositoryMixin,FcmRepositoryMixin, UserRepositoryMixin, TeamRepositoryMixin, NotificationRepositoryMixin, StageRepositoryMixin {
  final AppApi appApi;

  AppRepository({
    required this.appApi,
  });

  void setURL(String url) => appApi.setURL(url);

  void setToken(String token) => appApi.setToken(token);

  Future<Result<AppData, String>> getAppVersion() async {
    final result = await appApi.getAppVersion();

    if (result.isSuccess()) {
      return Success(AppData.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error');
    }
  }
}
