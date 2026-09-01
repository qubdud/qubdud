import 'package:multiple_result/multiple_result.dart';
import 'package:qb/data_layer/data_models/request/edit_team.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/request/create_team.dart';
import '../../data_layer/data_models/request/login.dart';
import '../../data_layer/data_models/request/register.dart';
import '../../data_layer/data_models/request/vote.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../../data_layer/data_models/response/login.dart';
import '../../data_layer/data_models/response_error/create_team.dart';
import '../../data_layer/data_models/response_error/login.dart';
import '../../data_layer/data_models/response_error/register.dart';
import '../domain_models/team_info.dart';
import '../domain_models/team_invite.dart';
import '../domain_models/team_invite_request.dart';
import '../domain_models/team_stats.dart';
import '../domain_models/user_invite.dart';
import '../domain_models/user_invite_request.dart';

mixin TeamRepositoryMixin {
  AppApi get appApi;
  Future<Result<ApiResponse, CreateTeamError>> createTeam(CreateTeamRequest createTeamRequest) async {
    final result = await appApi.createTeam(createTeamRequest.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(CreateTeamError.fromJson(result.tryGetError()!));
    }
  }

  Future<Result<ApiResponse, CreateTeamError>> editTeam(EditTeamRequest editRequest) async {
    final result = await appApi.editTeam(editRequest.toJson());
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error(CreateTeamError.fromJson(result.tryGetError()!));
    }
  }



  Future<Result<List<TeamInvite>, String>> getInvitableTeams() async {
    final result = await appApi.getInvitableTeams();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<TeamInvite> teams = data.map((team) => TeamInvite.fromJson(team)).toList();
      return Success(teams);
    } else {
      return Error('Error fetching teams');
    }
  }

  // Wysłanie zaproszenia przez użytkownika do drużyny
  Future<Result<ApiResponse, String>> sendRequestToJoinTeam(String teamId) async {
    final result = await appApi.sendRequestToJoinTeam(teamId);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error sending join request');
    }
  }

  // Pobranie listy otrzymanych zaproszeń od drużyn
  Future<Result<List<TeamInviteRequest>, String>> getPendingTeamInvites() async {
    final result = await appApi.getPendingTeamInvites();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<TeamInviteRequest> invites = data.map((invite) => TeamInviteRequest.fromJson(invite)).toList();
      return Success(invites);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  // Akceptowanie zaproszenia od drużyny
  Future<Result<ApiResponse, String>> acceptTeamRequest(String inviteId) async {
    final result = await appApi.acceptTeamRequest(inviteId);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error accepting invite');
    }
  }

  // Pobranie listy użytkowników, których można zaprosić
  Future<Result<List<UserInvite>, String>> getInvitableUsers() async {
    final result = await appApi.getInvitableUsers();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<UserInvite> users = data.map((user) => UserInvite.fromJson(user)).toList();
      return Success(users);
    } else {
      return Error('Error fetching users');
    }
  }

  // Wysłanie zaproszenia użytkownikowi
  Future<Result<ApiResponse, String>> sendInviteToUser(String userId) async {
    final result = await appApi.sendInviteToUser(userId);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error sending invite');
    }
  }

  // Pobranie listy otrzymanych zaproszeń od użytkowników
  Future<Result<List<UserInviteRequest>, String>> getPendingUserInvites() async {
    final result = await appApi.getPendingUserInvites();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<UserInviteRequest> invites = data.map((invite) => UserInviteRequest.fromJson(invite)).toList();
      return Success(invites);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  // Akceptowanie zaproszenia użytkownika
  Future<Result<ApiResponse, String>> acceptUserInvite(String inviteId) async {
    final result = await appApi.acceptUserRequest(inviteId);
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error accepting user invite');
    }
  }

  // Pobranie listy otrzymanych zaproszeń od użytkowników

  Future<Result<TeamInfo, String>> getTeamInfo() async {
    final result = await appApi.getTeamInfo();
    if (result.isSuccess()) {
      return Success(TeamInfo.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error fetching team info');
    }
  }

  Future<Result<TeamStatistics, String>> getTeamScore() async {
    final result = await appApi.getTeamScore();
    if (result.isSuccess()) {
      return Success(TeamStatistics.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error fetching team info');
    }
  }

  Future<Result<List<TeamMember>, String>> getTeamMembers() async {
    final result = await appApi.getTeamMembers();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<TeamMember> teamMembers = [];

      for (var group in data) {  // Poprawka: Używamy `data`, a nie niezdefiniowanego `departmentGroups`
        String departmentGroup = group['name'];
        int color = group['color'];

        for (var passenger in group['passengers']) {
          teamMembers.add(TeamMember.fromJson(passenger, departmentGroup, color));
        }
      }

      return Success(teamMembers);  // Zwracamy `Success`
    } else {
      return Error('Error fetching team members');
    }
  }

  Future<Result<TeamStickers, String>> getTeamStickers() async {
    final result = await appApi.getTeamStickers();
    if (result.isSuccess()) {
      return Success(TeamStickers.fromJson(result.tryGetSuccess()));
    } else {
      return Error('Error fetching team stickers');
    }
  }

  Future<Result<ApiResponse, String>> removeVehicle() async {
    final result = await appApi.removeVehicle();
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error accepting user invite');
    }
  }




}
