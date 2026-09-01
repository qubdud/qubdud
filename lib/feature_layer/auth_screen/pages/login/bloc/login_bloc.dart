import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../data_layer/data_models/request/login.dart';
import '../../../../../data_layer/data_models/response_error/login.dart';
import '../../../../../domain_layer/repository.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/globals.dart';

part 'login_event.dart';

part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required AppRepository repository,
  }) : super(LoginMainState()) {
    on<GoToMainLoginEvent>((event, emit) async {
      emit(LoginMainState());
    });

    on<TryLoginEvent>((event, emit) async {
      emit(LoginLoadingState());

      if(event.loginRequest.email=='none'){


       // showToastError(text: "Firebase error: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.");
        emit(LoginNextState());
      }
      else{
        try {
          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: event.loginRequest.email,
            password: event.loginRequest.password,
          );

          // Jeśli logowanie się uda, możesz zapisać token, UID itd.
          final user = credential.user;
          if (user != null) {
            Globals.instance.anonim = false;

      //      showToastError(text: "Firebase error: Error getting App Check token; using placeholder token instead. Error: com.google.firebase.FirebaseException: No AppCheckProvider installed.");

            emit(LoginNextState());

          } else {
            showToastError(text: 'Nieprawidłowe dane logowania');
            emit(LoginErrorState(loginError: LoginError(message: 'Użytkownik nie istnieje')));
          }

        } on FirebaseAuthException catch (e) {
          String errorMsg = 'Wystąpił błąd logowania';

          if (e.code == 'user-not-found') {
            errorMsg = 'Nie znaleziono użytkownika o tym adresie email';
          } else if (e.code == 'wrong-password') {
            errorMsg = 'Nieprawidłowe hasło';
          } else {
            errorMsg = e.message ?? errorMsg;
          }

          showToastError(text: e.code);
          emit(LoginErrorState(loginError: LoginError(message: errorMsg)));
        } catch (e) {
          showToastError(text: 'Błąd wewnętrzny: ${e.toString()}');
          emit(LoginErrorState(loginError: LoginError(message: e.toString())));
        }

      }


    });


/*      if(event.loginRequest.email=='none'){
        event.loginRequest.email='none';

        Globals.instance.baseUrl='https://test-nexi2025.albedomarketing.net';
        repository.setURL('https://test-nexi2025.albedomarketing.net');
     }


      var result = await repository.login(event.loginRequest);

      result.whenError((response) {

        print(response.statusCode);
        if(response.statusCode==440){
          showToast(text: response.message);
        }else{
          showToastError(text: response.message);
        }


        emit(LoginErrorState(loginError: response));
      });
      await result.whenSuccess((response) async {
        repository.setToken(response.token);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response.token);

        emit(LoginNextState());
      });*/

    // add(GoToMainLoginEvent());
  }
}
