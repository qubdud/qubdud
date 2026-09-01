part of 'news_page_bloc.dart';

abstract class NewsPageEvent {}

class GetDataNewsPageEvent extends NewsPageEvent {}

class GoToMainNewsPageEvent extends NewsPageEvent {}

class ResetNotificationsEvent extends NewsPageEvent {}
