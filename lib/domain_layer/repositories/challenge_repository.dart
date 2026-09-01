import 'package:multiple_result/multiple_result.dart';
import 'package:qb/data_layer/data_models/request/challenge.dart';
import 'package:qb/domain_layer/domain_models/challenge.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response_error/challenge.dart';
import '../domain_models/ranks.dart';



mixin ChallengeRepositoryMixin {
  AppApi get appApi;

  Future<Result<List<Challenge>, String>> getCurrentChallenges() async {
    final result = await appApi.getCurrentChallenges();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<Challenge> challenges = data.map((item) => Challenge.fromJson(item)).toList();
      return Success(challenges);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<List<Challenge>, String>> getHistoryChallenges() async {
    final result = await appApi.getHistoryChallenges();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<Challenge> challenges = data.map((item) => Challenge.fromJson(item)).toList();
      return Success(challenges);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<Post, String>> getWallPost(String id) async {
    final result = await appApi.getWallPost(id);
    if (result.isSuccess()) {
      return Success(Post.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error(result.tryGetError()!.toString());
    }
  }

  Future<Result<List<Post>, String>> getWallPosts() async {
    final result = await appApi.getWallPosts();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data']['posts'];
      List<Post> posts = data.map((item) => Post.fromJson(item)).toList();
      return Success(posts);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<ApiResponse, String>> deleteChallenge(String id) async {
    final result = await appApi.deleteChallenge(id);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error');
    }
  }




  Future<Result<ApiResponse, ChallengeError>> sendChallenge(ChallengeRequest request) async {
    final result = await appApi.sendChallengeSubmission(
        challengeId: request.id, description: request.description, isPublic: request.public, copyrightConsent: request.copyright, photoFilePaths: request.files);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(ChallengeError.fromJson(result.tryGetError()!));
    }
  }

  Future<Result<String, String>> sendCommentPost (String id, String con) async {
    final result = await appApi.sendCommentPost(id,con);
    if (result.isSuccess()) {
      return Success('Ok');
    } else {
      return Error(result.tryGetError()!);
    }
  }


  Future<Result<String, String>> likePost (String id) async {
    final result = await appApi.likePost(id);
    if (result.isSuccess()) {
      return Success('Ok');
    } else {
      return Error(result.tryGetError()!);
    }
  }

  Future<Result<Ranking, String>> getRanking(String rankingType) async {
    final result = await appApi.getRanking(rankingType);
    if (result.isSuccess()) {
      return Success(Ranking.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error fetching data');
    }
  }

  Future<Result<List<RankingOption>, String>> getRankingTeamStages() async {
    final result = await appApi.getRankingTeamStages();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<RankingOption> res = data.map((item) => RankingOption.fromJson(item)).toList();
      return Success(res);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<List<RankingOption>, String>> getRankingTeamHalf() async {
    final result = await appApi.getRankingTeamHalf();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<RankingOption> res = data.map((item) => RankingOption.fromJson(item)).toList();
      return Success(res);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<List<RankingOption>, String>> getRankingIndividualStages() async {
    final result = await appApi.getRankingIndividualStages();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<RankingOption> res = data.map((item) => RankingOption.fromJson(item)).toList();
      return Success(res);
    } else {
      return Error('Error fetching pending invites');
    }
  }

}
