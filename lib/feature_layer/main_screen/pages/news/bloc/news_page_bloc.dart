import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';

import '../../../../../../domain_layer/domain_models/news.dart';
import '../../../../../../domain_layer/repository.dart';

part 'news_page_event.dart';

part 'news_page_state.dart';

class NewsPageBloc extends Bloc<NewsPageEvent, NewsPageState> {
  Timer? resetTimer;

  NewsPageBloc({
    required AppRepository repository, required MainScreenBloc mainBloc
  }) : super(NewsPageLoadingState()) {
    on<GetDataNewsPageEvent>((event, emit) async {
      emit(NewsPageLoadingState());
      var newsResult = await repository.getNews();
      newsResult.whenSuccess((res) {
        state.news = res;

        repository.markNewsAsRead().then(
            (val){
              mainBloc.state.newsCounter=0;
            }

        );


        emit(NewsPageMainState());
      });

    });

    on<ResetNotificationsEvent>((event, emit) async {

    });

    add(GetDataNewsPageEvent());
  }

  @override
  Future<void> close() {
    // Anuluj timer, gdy Bloc jest zamykany

    resetTimer?.cancel();
    return super.close();
  }
}
