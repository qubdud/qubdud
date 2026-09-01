import 'dart:async';
import 'dart:developer' as dev;
import 'package:multiple_result/multiple_result.dart';
import '../shared/globals.dart';
import 'package:dio/dio.dart';

import 'mocks/mock_invites.dart';
import 'mocks/mock_news.dart';
import 'mocks/mock_notifications.dart';
import 'mocks/mock_others.dart';
import 'mocks/mock_team.dart';
import 'mocks/mock_user.dart';

class AppApi {
  AppApi({Dio? dio, this.useMocks = false})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: '${Globals.instance.baseUrl}/api',
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )) {
    if (useMocks) {
      addMockInterceptor(MockInterceptor());
    }
  }

  final Dio _dio;
  final bool useMocks; // Flaga przełączająca tryb mock/API
  String token = '';

  void setToken(String tok) {
    token = tok;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void setURL(String url) {
    _dio.options.baseUrl = '$url/api';
  }

  void addMockInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Future<Result<dynamic, dynamic>> sendChallengeSubmission({
    required String challengeId,
    required String description,
    required bool isPublic,
    required bool copyrightConsent,
    required List<String> photoFilePaths, // ścieżki do zdjęć
  }) async {
    final formData = FormData();

    formData.fields.addAll([
      MapEntry('challenge_id', challengeId),
      MapEntry('description', description),
      MapEntry('public', isPublic ? '1' : '0'),
      MapEntry('copyright_consent', copyrightConsent ? '1' : '0'),
    ]);

    for (int i = 0; i < photoFilePaths.length; i++) {
      final path = photoFilePaths[i];
      final file = await MultipartFile.fromFile(path, filename: path.split('/').last);
      formData.files.add(MapEntry('photo_files[$i]', file));
    }


    try {
      final response = await _dio.post('/challenges/create', data: formData);
      dev.log(response.data.toString());
      return Success(response.data);
    } catch (e) {
      if (e is DioException && e.response != null) {
        dev.log(e.response!.data.toString());
        return Error(e.response?.data);
      }
      return Error('Unexpected error');
    }
  }



  Future<Result<dynamic, dynamic>> _makeRequest(String endpoint, {String method = 'GET', Map<String, dynamic>? data, bool isStatusCode = false}) async {
    print('\n###\n$endpoint\n');
    print(data.toString());
    try {
      Response response;
      if (method == 'GET') {
        response = await _dio.get(endpoint);
      } else {
        response = await _dio.post(endpoint, data: data);
      }
      print('Success\n');
      dev.log(response.data.toString());
      return Success(response.data); // Zwraca dane w przypadku sukcesu
    } catch (e) {
      if (e is DioException && e.response != null) {

        dev.log(e.response!.data.toString());
        if (isStatusCode){
          (e.response!.data as Map<String, dynamic>).putIfAbsent('status_code', ()=>e.response!.statusCode);
        }
        return Error(e.response?.data); // Zwraca dane błędu, jeśli dostępne
      }
      print('Error ???\n');
      return Error('Unexpected error');
    }
  }




//User
  Future<Result<dynamic, dynamic>> getMe() => _makeRequest('/user/me'); // OK

  Future<Result<dynamic, dynamic>> getCurrentStage() => _makeRequest('/stage/current');

  //Lista drużyn do których może dołaczyć user.
  Future<Result<dynamic, dynamic>> getInvitableTeams() => _makeRequest('/vehicles'); //OK

  //Wysłanie zaproszenia przez usera do drużyny z prośbą o dołączenie

  Future<Result<dynamic, dynamic>> getRegisterNIPData(String nip) => _makeRequest('/register/$nip');

  Future<Result<dynamic, dynamic>> sendRequestToJoinTeam(String teamId) => _makeRequest('/vehicles-offer', method: 'POST', data: {"vehicle_id":teamId}); //OK

  Future<Result<dynamic, dynamic>> createTeam(data) => _makeRequest('/vehicle', method: 'POST', data: data); //ok

  Future<Result<dynamic, dynamic>> editTeam(data) => _makeRequest('/vehicle-custom', method: 'POST', data: data); //ok

  Future<Result<dynamic, dynamic>> getTeamMembers() => _makeRequest('/vehicle-members'); //ok

  Future<Result<dynamic, dynamic>> getChatUsers() => _makeRequest('/chat/list'); //ok

  Future<Result<dynamic, dynamic>> getTeamInfo() => _makeRequest('/vehicle'); //ok

  Future<Result<dynamic, dynamic>> getTeamScore() => _makeRequest('/vehicle-score-details'); //ok

  Future<Result<dynamic, dynamic>> getUserScore() => _makeRequest('/user/score-details'); //ok

  Future<Result<dynamic, dynamic>> getUserELearnings() => _makeRequest('/user/elearnings'); //ok

  Future<Result<dynamic, dynamic>> getUserBusinessTasks() => _makeRequest('/user/business-tasks'); //ok

  Future<Result<dynamic, dynamic>> registerPushToken(String pushToken) => _makeRequest('/fcm/store-token', method: 'POST', data: {"token":pushToken}); //ok

  Future<Result<dynamic, dynamic>> sendChatPush(String token) => _makeRequest('/fcm/send-push', method: 'POST', data: {"token":token}); //ok

  Future<Result<dynamic, dynamic>> getPendingTeamInvites() => _makeRequest('/vehicles-invite'); //ok

  Future<Result<dynamic, dynamic>> acceptTeamRequest(String inviteId) => _makeRequest('/vehicles-invite-accept',method: 'POST', data: {"vehicle_invitation_id":inviteId});

  Future<Result<dynamic, dynamic>> acceptUserRequest(String inviteId) => _makeRequest('/vehicles-offer-accept',method: 'POST', data: {"vehicle_invitation_id":inviteId});

  Future<Result<dynamic, dynamic>> getNews() => _makeRequest('/news/list');

  Future<Result<dynamic, dynamic>> sendVote(data) => _makeRequest('/vote-trip-destination', method: 'POST', data: data);

  Future<Result<dynamic, dynamic>> getVoteData() => _makeRequest('/vote-trip-destination');

  Future<Result<dynamic, dynamic>> markNewsAsRead() => _makeRequest('/news/mark-as-read', method: 'POST');

  Future<Result<dynamic, dynamic>> getNewsCounter() => _makeRequest('/news/counter');

  Future<Result<dynamic, dynamic>> sendContact(data) => _makeRequest('/contact', method: 'POST', data: data);

  Future<Result<dynamic, dynamic>> removeVehicle() => _makeRequest('/vehicle-remove', method: 'POST');

  Future<Result<dynamic, dynamic>> getInvitableUsers() => _makeRequest('/passengers');

  Future<Result<dynamic, dynamic>> sendInviteToUser (String inviteId) => _makeRequest('/vehicles-invite',method: 'POST', data: {"user_id":inviteId});

  Future<Result<dynamic, dynamic>> getPendingUserInvites() => _makeRequest('/vehicles-offer');

  Future<Result<dynamic, dynamic>> getUnreadNotifications() => _makeRequest('/notifications/unread');

  Future<Result<dynamic, dynamic>> getReadNotifications() => _makeRequest('/notifications/read');

  Future<Result<dynamic, dynamic>> getNotificationsCounters() => _makeRequest('/notifications/counter');

  Future<Result<dynamic, dynamic>> resetNotificationsCounters() => _makeRequest('/notifications/read', method: 'POST');

  Future<Result<dynamic, dynamic>> changePassword(data) => _makeRequest('/user/change-password', method: 'POST', data: data);

  Future<Result<dynamic, dynamic>> forgotPassword(data) => _makeRequest('/forgot-password', method: 'POST', data: data);

  Future<Result<dynamic, dynamic>> getCurrentChallenges() => _makeRequest('/challenges/current');

  Future<Result<dynamic, dynamic>> getHistoryChallenges() => _makeRequest('/challenges/history');

  Future<Result<dynamic, dynamic>> deleteChallenge (String id) => _makeRequest('/challenges/delete',method: 'POST', data: {"post_id":id});

  Future<Result<dynamic, dynamic>> getWallPost(String id) => _makeRequest('/wall/single-post/$id');

  Future<Result<dynamic, dynamic>> sendCommentPost(String id, String cont) => _makeRequest('/wall/comment',method: 'POST', data: {"post_id":id, "content":cont});

  Future<Result<dynamic, dynamic>> likePost(String id) => _makeRequest('/wall/like',method: 'POST', data: {"post_id":id});

  Future<Result<dynamic, dynamic>> getWallPosts() => _makeRequest('/wall/all-posts?posts_limit=10&cache=0');

  Future<Result<dynamic, dynamic>> getRanking(String rankingType) => _makeRequest('/ranking?ranking=$rankingType');

  Future<Result<dynamic, dynamic>> getRankingTeamStages() => _makeRequest('/ranking/team/stages');

  Future<Result<dynamic, dynamic>> getRankingTeamHalf() => _makeRequest('/ranking/team/half');

  Future<Result<dynamic, dynamic>> getRankingIndividualStages() => _makeRequest('/ranking/individual/stages');

  Future<Result<dynamic, dynamic>> getDuelHistory() => _makeRequest('/duel/history');

  Future<Result<dynamic, dynamic>> getDuelSummary(int id) => _makeRequest('/duel/summary/$id');

  Future<Result<dynamic, dynamic>> storeDuelQuestion(int id, int questionId, int answerId) => _makeRequest('/duel/store-answer/$id',method: 'POST', data: {"question_id":questionId, "answer_id":answerId});

  Future<Result<dynamic, dynamic>> getDuelQuestion(int id) => _makeRequest('/duel/get-next-question/$id');


  //AppData
  Future<Result<dynamic, dynamic>> getAppVersion() => _makeRequest('/app/version');

  Future<Result<dynamic, dynamic>> login(data) => _makeRequest('/login', method: 'POST', data: data, isStatusCode: true);

  Future<Result<dynamic, dynamic>> getTeamStickers() => _makeRequest('/vehicle-stickers');



//Done
  Future<Result<dynamic, dynamic>> getRegisterData() => _makeRequest('/register');

  Future<Result<dynamic, dynamic>> register(data) => _makeRequest('/register', method: 'POST', data: data);
}

/// Example Mock Interceptor
class MockInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path == '/user/me') {
      handler.resolve(mockUserResponse(options));
    } else if (options.path == '/notifications/counters' && options.method == 'GET') {
      handler.resolve(mockNotificationsResponse(options));
    } else if (options.path.startsWith('/invites')) {
      handler.resolve(mockInvitesResponse(options));
    } else if (options.path == '/news') {
      handler.resolve(mockNewsResponse(options));
    } else if (options.path.startsWith('/team')) {
      handler.resolve(mockTeamResponse(options));
    } else if (options.path == '/app' || options.path == '/vote' || options.path == '/login') {
      handler.resolve(mockOthersResponse(options));
    } else {
      handler.reject(DioException(requestOptions: options, response: Response(requestOptions: options, statusCode: 404, data: {'message': 'Not Found'})));
    }
  }
}
