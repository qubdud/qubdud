part of 'notifications_page_bloc.dart';

abstract class NotificationPageEvent {}

class GetDataNotificationPageEvent extends NotificationPageEvent {}

class GoToMainNotificationPageEvent extends NotificationPageEvent {}

class GoToLoadingNotificationPageEvent extends NotificationPageEvent {}

class ResetNotificationsEvent extends NotificationPageEvent {}
