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
        padding: const EdgeInsets.fromLTRB(kGapL, 0, kGapL, kGapL),
        child: Column(
          children: [
            SizedBox(height: topPadding + kGapXl),
            const Text('QUBDUD',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: kGapL),
            WLabel(text: 'Sprawdź pocztę'),
            const Text(
              'Kliknij link otrzymany w wiadomości e-mail, aby ustawić nowe hasło do konta.',
              style: TextStyle(color: cDarkBrown, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kGapXl),
            WButton(
              text: 'Zaloguj się',
              onPressed: () =>
                  context.read<AuthBloc>().add(AuthGoToLoginPageEvent()),
            ),
            const SizedBox(height: kGapL),
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
