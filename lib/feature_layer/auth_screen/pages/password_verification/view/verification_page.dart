import 'package:flutter/gestures.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../../../data_layer/data_models/request/register.dart';
import '../../../../../domain_layer/domain_models/register_data.dart';
import '../../../../../domain_layer/repository.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/w_button.dart';


import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_label.dart';

import '../../../bloc/auth_bloc.dart';
import '../bloc/verification_bloc.dart';

class VerificationPage extends StatelessWidget {
  final Uri uri;
  const VerificationPage({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerificationBloc(repository: context.read<AppRepository>(), uri: uri),
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
  String? nameError;
  String? surnameError;
  String? emailError;
  String? emailConfirmationError;
  String? countryError;

  String? passwordError;
  String? passwordConfirmationError;

  List<Agreement> agreements = [];
  List<AgreementSelection> selectedAgreements = [];
  Map<String, String?> agreementErrors = {};

  late final TextEditingController name = TextEditingController();
  late final TextEditingController surname = TextEditingController();
  late final TextEditingController email = TextEditingController();
  late final TextEditingController emailConfirmation = TextEditingController();
  late final TextEditingController country = TextEditingController();

  late final TextEditingController password = TextEditingController();
  late final TextEditingController passwordConfirmation = TextEditingController();

  bool obscurePassword = true;

  List<String> countryStringList = [];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationBloc, VerificationState>(
      listener: (context, state) {
        if (state is VerificationNextState) {
          context.read<AuthBloc>().add(AuthGoToRegistrationCompletePageEvent());
        }
        if (state is VerificationBackState) {
          context.read<AuthBloc>().add(AuthGoToLoginPageEvent());
        }

        if (state is VerificationMainState) {}

        if (state is VerificationErrorState) {


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

  Widget _buildWidgetBasedOnState(VerificationState state) {
    if (state is VerificationLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is VerificationInitialState || state is VerificationErrorState) {



      return LayoutBuilder(builder: (context, constrains) {
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
                  WLabel(text: 'VERIFICATION COMPLETED'.toUpperCase()),
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
                      SelectableText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Thanks for confirming your willingness to participate in gamification. ',
                              style: TextStyle(
                                color: cDarkBrown,
                                fontSize: 16,
                                fontFamily: 'FiraSans',
                              ),
                            ),
                            TextSpan(
                              text:
                              'You will be able to log in after authorization by Nexi.',
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              WButton(text: 'Go back to log in',
              onPressed: (){
                context.read<AuthBloc>().add(AuthGoToLoginPageEvent());
              },),

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
      });
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}
