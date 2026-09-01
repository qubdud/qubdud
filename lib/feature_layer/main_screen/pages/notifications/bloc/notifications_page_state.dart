part of 'notifications_page_bloc.dart';

abstract class NotificationPageState {

  static List<NotificationModel> notificationsStatic = [];
  List<NotificationModel> get notifications => notificationsStatic;
  set notifications(List<NotificationModel> value) {
    notificationsStatic = value;
  }

  static List<NotificationModel> notificationsOldStatic = [];
  List<NotificationModel> get notificationsOld => notificationsOldStatic;
  set notificationsOld(List<NotificationModel> value) {
    notificationsOldStatic = value;
  }

}

class NotificationPageInitialState extends NotificationPageState {
  NotificationPageInitialState() : super();
}

class NotificationPageMainState extends NotificationPageState {
  NotificationPageMainState() : super();
}

class NotificationPageLoadingState extends NotificationPageState {}

class NotificationPageNextState extends NotificationPageState {}
