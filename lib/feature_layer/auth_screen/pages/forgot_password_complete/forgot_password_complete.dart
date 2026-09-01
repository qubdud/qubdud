import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/constants.dart';
import '../../../../shared/widgets/w_button.dart';
import '../../../../shared/widgets/w_label.dart';
import '../../bloc/auth_bloc.dart';

class ForgotPasswordCompletePage extends StatelessWidget {
  const ForgotPasswordCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: topPadding > 1 ? topPadding : 64),
            const SizedBox(height: 20),
            const Text('QUBDUD',
                style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            WLabel(text: 'Sprawdź pocztę'),
            const SizedBox(height: 16),
            const Text(
              'Kliknij link otrzymany w wiadomości e-mail, aby ustawić nowe hasło do konta.',
              style: TextStyle(color: cDarkBrown, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            WButton(
              text: 'Zaloguj się',
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthGoToLoginPageEvent()),
            ),
            const SizedBox(height: 24),
            const Text(
              'Jeśli wiadomość nie dotarła, sprawdź folder Spam.',
              style: TextStyle(color: cDarkBrown, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
