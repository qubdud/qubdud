import 'package:flutter/gestures.dart';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../data_layer/data_models/auth_models.dart';
import '../../../../../domain_layer/repository.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/w_button.dart';

import '../../../../../shared/widgets/w_checkbox.dart';
import '../../../../../shared/widgets/w_input_field.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_label.dart';

import '../../../bloc/auth_bloc.dart';
import '../bloc/forgot_password_bloc.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForgotPasswordBloc(repository: context.read<AppRepository>()),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  String? emailError;

  late final TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordNextState) {
          context.read<AuthBloc>().add(AuthGoToForgotPasswordCompletePageEvent());
        }
        if (state is ForgotPasswordBackState) {
          context.read<AuthBloc>().add(AuthGoToLoginPageEvent());
        }

        if (state is ForgotPasswordMainState) {}

        if (state is ForgotPasswordErrorState) {
          final errors = state.forgotPasswordError;

          setState(() {
            emailError = errors.email.isNotEmpty ? errors.email.join('\n') : null;
          });
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
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
          child: _buildWidgetBasedOnState(state),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(ForgotPasswordState state) {
    if (state is ForgotPasswordLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is ForgotPasswordInitialState || state is ForgotPasswordErrorState) {
      return LayoutBuilder(builder: (context, constrains) {
        var topPadding = MediaQuery.of(context).padding.top;
        final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;
        return SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Logo and Title Section
              Column(
                children: [
                  SizedBox(height: topPadding > 1 ? topPadding : 64), // Optional padding
                  Image.asset(
                    'assets/logotypy.png',
                    width: constrains.maxWidth / 2,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/nexi_logo.png', // Replace with your logo asset
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        context.read<AuthBloc>().add(AuthGoToLoginPageEvent());
                      },
                      child: const Text(
                        '< Back',
                        style: TextStyle(color: cDarkerBlue, fontSize: 18, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  WLabel(text: 'Forgot your password?'.toUpperCase()),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Enter the e-mail address you created your account with. You will soon receive a message with a code to reset your password.',
                          style: TextStyle(
                            color: cDarkBrown,
                            fontSize: 16,
                            fontFamily: 'FiraSans',
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                ],
              ),
              SizedBox(
                height: 24,
              ),
              WInputField(
                controller: email,
                label: 'Corporate E-mail address',
                errorText: emailError,
                isPassword: false,
                hintText: 'Type in e-mail address',
              ),

              SizedBox(
                height: 24,
              ),

              WButton(text: 'Send a message', onPressed: () {
                context.read<ForgotPasswordBloc>().add(TryForgotPasswordEvent(
                    forgotPasswordRequest: ForgotPasswordRequest(email: email.text)

                ));


              }),
              SizedBox(
                height: 24,
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                      'If you did not receive the e-mail with the link, please check the Spam or Other folder in your inbox. If you have not received the message, please contact us by e-mail to: ',
                      style: TextStyle(
                        color: cDarkBrown,
                        fontSize: 16,
                        fontFamily: 'FiraSans',
                      ),
                    ),
                    TextSpan(
                      text: 'contact@nexiexplorers.com',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cDarkBrown,
                        fontSize: 16,
                        fontFamily: 'FiraSans',
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),

              isWideScreen
                  ? const SizedBox(height: 80)
                  : Image.asset(
                'assets/images/kamper_mob.png',
                fit: BoxFit.fitWidth,
              ),




            ],
          ),


        ));
      });
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}
