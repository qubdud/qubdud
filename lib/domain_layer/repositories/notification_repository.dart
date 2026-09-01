import 'package:multiple_result/multiple_result.dart';

import '../../data_layer/api.dart';
import '../../data_layer/data_models/response/api_response.dart';
import '../domain_models/news.dart';
import '../domain_models/notification.dart';
import '../domain_models/notification_counters.dart';


mixin NotificationRepositoryMixin {
  AppApi get appApi;

  Future<Result<int, String>> getNewsCounter() async {
    final result = await appApi.getNewsCounter();
    if (result.isSuccess()) {
      return Success(result.tryGetSuccess()!['data']['counter']);
    } else {
      return Error('Error');
    }
  }

  Future<Result<NotificationCounters, String>> getNotificationCounters() async {
    final result = await appApi.getNotificationsCounters();
    if (result.isSuccess()) {
      return Success(NotificationCounters.fromJson(result.tryGetSuccess()!['data']));
    } else {
      return Error('Error');
    }
  }

  Future<Result<ApiResponse, String>> resetNotificationCounters() async {
    final result = await appApi.resetNotificationsCounters();
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error');
    }
  }




  Future<Result<List<News>, String>> getNews() async {
    final result = await appApi.getNews();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      List<News> news = data.map((item) => News.fromJson(item)).toList();
      return Success(news);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<List<NotificationModel>, String>> getUnreadNotifications() async {
    final result = await appApi.getUnreadNotifications();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      var notifications = data.map((item) => NotificationModel.fromJson(item)).toList();
      return Success(notifications);
    } else {
      return Error('Error fetching pending invites');
    }
  }

  Future<Result<List<NotificationModel>, String>> getReadNotifications() async {
    final result = await appApi.getReadNotifications();
    if (result.isSuccess()) {
      List<dynamic> data = result.tryGetSuccess()!['data'];
      var notifications = data.map((item) => NotificationModel.fromJson(item)).toList();
      return Success(notifications);
    } else {
      return Error('Error fetching pending invites');
    }
  }



  Future<Result<ApiResponse, String>> markNewsAsRead() async {
    final result = await appApi.markNewsAsRead();
    if (result.isSuccess()) {
      return Success(ApiResponse.fromJson(result.tryGetSuccess()!));
    } else {
      return Error('Error accepting invite');
    }
  }


}
