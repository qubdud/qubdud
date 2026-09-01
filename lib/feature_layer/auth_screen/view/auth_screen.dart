import 'dart:async';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../shared/constants.dart';
import '../../../shared/widgets/loading.dart';
import '../../core_screen/widgets/background.dart';
import '../bloc/auth_bloc.dart';
import '../pages/forgot_password/view/forgot_password_page.dart';
import '../pages/forgot_password_complete/forgot_password_complete.dart';
import '../pages/login/view/login_page.dart';
import '../pages/register/view/register_page.dart';
import '../pages/registration_complete/registration_complete.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: const View(),
    );
  }
}

class View extends StatelessWidget {
  const View({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Obsługa zdarzeń, jeśli potrzeba (np. powiadomienia, komunikaty itp.)
      },
      builder: (context, state) {
        return BackgroundImage(
          //imageAsset: isWideScreen ? 'assets/images/bg_mapa.png' : 'assets/images/bg_logowanie_mob.png',
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxColumnSize),
                    child: _buildWidgetBasedOnState(state),
                  ),
                )),
          ),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(AuthState state) {
    if (state is AuthLoginPageState) {
      return const LoginPage(key: ValueKey('LoginPage'));
    } else if (state is AuthRegisterPageState) {
      return const RegisterPage(key: ValueKey('RegisterPage'));
    } else if (state is AuthRegistrationCompletePageState) {
      return const RegistrationCompletePage(key: ValueKey('RegistrationCompletePage'));
    } else if (state is AuthForgotPasswordPageState) {
         return const ForgotPasswordPage(key: ValueKey('ForgotPasswordPage'));
    } else if (state is AuthForgotPasswordCompletePageState) {
      return const ForgotPasswordCompletePage(key: ValueKey('ForgotPasswordCompPage'));
    } else {
      return const Loading(key: ValueKey('Loading'),);
    }
  }
}
