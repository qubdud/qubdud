import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';

import '../../../../../../domain_layer/domain_models/news.dart';
import '../../../../../../domain_layer/repository.dart';
import '../../../../../domain_layer/domain_models/notification.dart';

part 'notifications_page_event.dart';

part 'notifications_page_state.dart';

class NotificationPageBloc extends Bloc<NotificationPageEvent, NotificationPageState> {
  Timer? resetTimer;

  NotificationPageBloc({
    required AppRepository repository, required MainScreenBloc mainBloc
  }) : super(NotificationPageLoadingState()) {
    on<GetDataNotificationPageEvent>((event, emit) async {
      emit(NotificationPageLoadingState());
      var readResult = await repository.getReadNotifications();
      var unreadResult = await repository.getUnreadNotifications();


      if(readResult.isSuccess() && unreadResult.isSuccess() ){
        state.notifications = unreadResult.tryGetSuccess()!;
        state.notificationsOld = readResult.tryGetSuccess()!;
        emit(NotificationPageMainState());
        add(ResetNotificationsEvent());
      }
    });

    on<GoToLoadingNotificationPageEvent>((event, emit) async {
      emit(NotificationPageLoadingState());
    });



    on<ResetNotificationsEvent>((event, emit) async {
     var resetResult = await repository.resetNotificationCounters();

     resetResult.whenSuccess((x){
       mainBloc.state.notificationCounter=0;
     });


    });

    add(GetDataNotificationPageEvent());
  }

  @override
  Future<void> close() {

    // Anuluj timer, gdy Bloc jest zamykany

    resetTimer?.cancel();
    return super.close();
  }
}
