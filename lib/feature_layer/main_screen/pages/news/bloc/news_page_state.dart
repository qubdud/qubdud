part of 'news_page_bloc.dart';

abstract class NewsPageState {
  static List<News> newsStatic = [];

  List<News> get news => newsStatic;

  set news(List<News> value) {
    newsStatic = value;
  }
}

class NewsPageInitialState extends NewsPageState {
  NewsPageInitialState() : super();
}

class NewsPageMainState extends NewsPageState {
  NewsPageMainState() : super();
}

class NewsPageLoadingState extends NewsPageState {}

class NewsPageNextState extends NewsPageState {}
