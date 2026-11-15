import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/push_service.dart';

part 'core_screen_event.dart';
part 'core_screen_state.dart';

class CoreScreenBloc extends Bloc<CoreScreenEvent, CoreScreenState> {
  CoreScreenBloc() : super(CoreScreenLoadingState()) {
    on<CoreScreenCheckAuthenticationEvent>(_onCheckAuth);
    on<CoreScreenGoToMainScreenEvent>(_onGoToMain);

    add(CoreScreenCheckAuthenticationEvent());
  }

  Future<void> _onCheckAuth(
      CoreScreenCheckAuthenticationEvent event,
      Emitter<CoreScreenState> emit,
      ) async {
    emit(CoreScreenLoadingState());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emit(CoreScreenAuthenticatedState());
    } else {
      PushService.retryPendingDelete();
      emit(CoreScreenUnauthenticatedState(toRegister: event.toRegister));
    }
  }

  Future<void> _onGoToMain(
      CoreScreenGoToMainScreenEvent event,
      Emitter<CoreScreenState> emit,
      ) async {
    emit(CoreScreenAuthenticatedState());
  }
}