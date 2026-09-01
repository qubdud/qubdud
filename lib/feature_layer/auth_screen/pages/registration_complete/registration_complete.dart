import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../bloc/auth_bloc.dart';

class RegistrationCompletePage extends StatelessWidget {
  const RegistrationCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: topPadding > 1 ? topPadding : 64),
          const SizedBox(height: 20),
          const Text('QUBDUD',
              style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 72),
          const SizedBox(height: 24),
          WLabel(text: 'Zarejestrowano!'),
          const SizedBox(height: 24),
          Text(
            'Dziękujemy za rejestrację.\nMożesz teraz się zalogować.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cDarkBrown, fontSize: 16),
          ),
          const SizedBox(height: 48),
          WButton(
            text: 'Zaloguj się',
            onPressed: () =>
                context.read<AuthBloc>().add(AuthGoToLoginPageEvent()),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}