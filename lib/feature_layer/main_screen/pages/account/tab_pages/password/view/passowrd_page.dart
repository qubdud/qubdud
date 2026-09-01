import 'package:qb/data_layer/data_models/request/change_pass.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/feature_layer/main_screen/pages/account/bloc/account_page_bloc.dart';


import '../../../../../../../domain_layer/repository.dart';
import '../../../../../../../shared/constants.dart';
import '../../../../../../../shared/widgets/loading.dart';
import '../../../../../../../shared/widgets/w_button.dart';
import '../../../../../../../shared/widgets/w_card.dart';
import '../../../../../../../shared/widgets/w_input_field.dart';
import '../../../../../../../shared/widgets/w_label.dart';
import '../../../../../../../shared/widgets/w_small_label.dart';
import '../bloc/password_page_bloc.dart';

class PasswordAccountPage extends StatelessWidget {
  const PasswordAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PasswordAccountPageBloc(repository: context.read<AppRepository>()),
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
  String? oldPasswordError;
  String? passwordError;
  String? passwordConfirmationError;
  bool oldPassVisible = false;
  bool currPassVisible = false;

  late final TextEditingController oldPassword = TextEditingController();
  late final TextEditingController password = TextEditingController();
  late final TextEditingController passwordConfirmation = TextEditingController();


  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    return BlocConsumer<PasswordAccountPageBloc, PasswordPageAccountPageState>(
      listener: (context, state) {
        if (state is PasswordAccountPageMainState) {}


        if (state is PasswordAccountPageLoadingState) {
          setState(() {
            oldPasswordError = null;
            passwordError = null;
            passwordConfirmationError = null;
          });
        }

        if (state is PasswordAccountPageNextState) {

          var parentContext = context;
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: WCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: isWideScreen ? 16 : 0, horizontal: isWideScreen ? 40 : 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(
                            'Your password  has been changed',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                          SizedBox(height: 20),
                          WButton(
                              text: 'Close',
                              onPressed: () {
                                if (mounted) {
                                  parentContext.read<AccountPageBloc>().add(GoToStatisticsAccountPageEvent());
                                }
                                Navigator.of(context, rootNavigator: true).pop();
                              }),

                        ],
                      ),
                    )),
              );
            },
          );


        }

        if (state is PasswordAccountPageErrorState) {
          final errors = state.changePassError;

          setState(() {
            // Przypisanie błędów do odpowiednich pól
            oldPasswordError = errors.oldPassword.isNotEmpty ? errors.oldPassword.join('\n') : null;
            passwordError = errors.password.isNotEmpty ? errors.password.join('\n') : null;
            passwordConfirmationError = errors.passwordConfiration.isNotEmpty ? errors.passwordConfiration.join('\n') : null;
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

  Widget _buildWidgetBasedOnState(PasswordPageAccountPageState state) {

    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is PasswordAccountPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! PasswordAccountPageInitialState) {
      return SizedBox(
        width: maxColumnSize,
        child: SingleChildScrollView(



              child: Column(children:

              [
                const SizedBox(height: 16),


                WCard(
                  child: Column(
                    children: [

                      WSmallLabel(text:'Change password'),

                      SelectableText.rich(
                        TextSpan(
                          style: TextStyle(color: cDarkBrown ),
                          children: [
                            TextSpan(
                              style: TextStyle(fontWeight:FontWeight.bold ),
                              text: 'Attention! ',
                            ),
                            TextSpan(
                              text: ' The password you create must be at least 8 characters long and contain at least one uppercase and lowercase letter, a number and a special character (e.g. !, @, #, \$, %, etc.)',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16,),





                      WInputField(
                        controller: oldPassword,
                        label: 'Current Password',
                        maxLines: 1,
                        errorText: oldPasswordError,
                        isPassword: true,
                        hintText: 'Type in a password',
                        obscureText: !oldPassVisible,
                        onTogglePasswordVisibility: (){
                          setState(() {
                            oldPassVisible = !oldPassVisible;
                          });
                        },


                      ),
                      const SizedBox(height: 16),
                      WInputField(
                        controller: password,
                        label: 'New Password',
                        errorText: passwordError,
                        isPassword: true,
                        hintText: 'Type in password',

                        obscureText: !currPassVisible,
                        onTogglePasswordVisibility: (){
                          setState(() {
                            currPassVisible = !currPassVisible;
                          });
                        },



                      ),
                      const SizedBox(height: 16),
                      WInputField(
                        controller: passwordConfirmation,
                        label: 'Repeat new password',
                        errorText: passwordConfirmationError,
                        isPassword: true,
                        hintText: 'Type in password',

                        obscureText: !currPassVisible,
                        onTogglePasswordVisibility: (){
                          setState(() {
                            currPassVisible = !currPassVisible;
                          });
                        },



                      ),



                      const SizedBox(height: 32),

                      Center(
                        child: WButton(
                          text: 'Save',
                          onPressed: () {
                            context.read<PasswordAccountPageBloc>().add(TryChangePasswordAccountPageEvent(
                                    changePassRequest: ChangePassRequest(

                                  oldPassword: oldPassword.value.text,
                                  password: password.value.text,
                                      passwordConfirmation: passwordConfirmation.value.text,
                                )));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),

                const SizedBox(height: 60),

              ]),


        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}
