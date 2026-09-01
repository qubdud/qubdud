import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';

import '../../../../domain_layer/repository.dart';
import '../../../shared/functions/show_toast_error.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;


  AuthBloc({
    required AppRepository repository,
  }) : super(AuthInitialState()) {
    on<AuthGoToLoginPageEvent>((event, emit) {
      emit(AuthLoginPageState());
    });

    on<AuthGoToRegisterPageEvent>((event, emit) {
      emit(AuthRegisterPageState());
    });

    on<AuthGoToRegistrationCompletePageEvent>((event, emit) {
      emit(AuthRegistrationCompletePageState());
    });

    on<AuthGoToForgotPasswordCompletePageEvent>((event, emit) {
      emit(AuthForgotPasswordCompletePageState());
    });

    on<AuthGoToForgotPasswordPageEvent>((event, emit) {
      emit(AuthForgotPasswordPageState());
    });

    on<AuthGoToResetPasswordPageEvent>((event, emit) {
      emit(AuthResetPasswordPageState());
    });

    on<AuthGoToPasswordChangedPageEvent>((event, emit) {
      emit(AuthPasswordChangedPageState());
    });



   _initDeepLinks();

  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();


    final Uri initialUri = await _appLinks.uriLinkStream.first.timeout(Duration(milliseconds: 100), onTimeout: ()=>Uri());
    if (initialUri.host.isEmpty) {
      add(AuthGoToLoginPageEvent());
    }else{
      _handleUri(initialUri);
    }
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
      });
  }
  _handleUri(Uri uri){
    if (uri.pathSegments.contains('verify')) {

      emit(AuthVerificationPageState(uri));
    }

    else if (uri.pathSegments.contains('reset-password')) {
      showToastError(text: uri.origin);
      add(AuthGoToLoginPageEvent());    }
    else {
     // showToastError(text: uri.origin);
      add(AuthGoToLoginPageEvent());    }
  }

  @override
  Future<void> close() {
    _linkSubscription?.cancel();
    return super.close();
  }



}
