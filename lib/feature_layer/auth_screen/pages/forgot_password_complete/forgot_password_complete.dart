
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/constants.dart';
import '../../../../shared/widgets/w_button.dart';
import '../../../../shared/widgets/w_label.dart';
import '../../bloc/auth_bloc.dart';
import '../login/bloc/login_bloc.dart';

class ForgotPasswordCompletePage extends StatefulWidget {
  const ForgotPasswordCompletePage({super.key});

  @override
  State<ForgotPasswordCompletePage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordCompletePage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constrains) {
        var topPadding = MediaQuery.of(context).padding.top;
        final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;
        return SingleChildScrollView(
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
                  const SizedBox(height: 20),
                  WLabel(text: 'Check the e-mail'.toUpperCase()),
                ],
              ),
              const SizedBox(height: 20),
              // Login Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Click the link received in the e-mail to reset and set up a new password to your account.',
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
                      SizedBox(height: 24,),

                      Center(
                        child: WButton(text: 'Log in', onPressed: (){
                          context.read<AuthBloc>().add(AuthGoToLoginPageEvent());

                        },),
                      ),

                      SizedBox(height: 24,),

                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                              'If you did not receive the e-mail with the code, please check the Spam or Other folder in your inbox. If you have not received the message, please contact us by e-mail to: ',
                              style: TextStyle(
                                color: cDarkBrown,
                                fontSize: 16,
                                fontFamily: 'FiraSans',
                              ),
                            ),
                            TextSpan(
                              text:
                              'contact@nexiexplorers.com',
                              style: TextStyle(
                                  color: cDarkBrown,
                                  fontSize: 14,
                                  fontFamily: 'FiraSans',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),




                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Register Section
              isWideScreen
                  ? const SizedBox(height: 60)
                  : Image.asset(
                'assets/images/kamper_mob.png',
                fit: BoxFit.fitWidth,
              ),
            ],
          ),
        );
      }),
    );
  }
}
