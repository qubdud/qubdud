import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/constants.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../../core_screen/bloc/core_screen_bloc.dart';

/// Po rejestracji konto jest już zalogowane — wysyłamy link weryfikacyjny
/// i wpuszczamy do aplikacji.
class RegistrationCompletePage extends StatefulWidget {
  const RegistrationCompletePage({super.key});

  @override
  State<RegistrationCompletePage> createState() =>
      _RegistrationCompletePageState();
}

class _RegistrationCompletePageState extends State<RegistrationCompletePage> {
  bool? _sent;

  @override
  void initState() {
    super.initState();
    _sendVerification();
  }

  Future<void> _sendVerification() async {
    try {
      await FirebaseAuth.instance.setLanguageCode('pl');
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      debugPrint('Weryfikacja e-mail: $e');
      if (mounted) setState(() => _sent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

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
            switch (_sent) {
              null => 'Wysyłamy link potwierdzający adres e-mail…',
              true => 'Na adres $email wysłaliśmy link potwierdzający. '
                  'Kliknij go, aby zweryfikować adres e-mail.',
              false => 'Nie udało się wysłać linku potwierdzającego na $email.',
            },
            textAlign: TextAlign.center,
            style: const TextStyle(color: cDarkBrown, fontSize: 16),
          ),
          if (_sent == false)
            TextButton(
              onPressed: () {
                setState(() => _sent = null);
                _sendVerification();
              },
              child: const Text('Wyślij ponownie'),
            ),
          const SizedBox(height: 48),
          WButton(
            text: 'Przejdź do aplikacji',
            onPressed: () {
              Globals.instance.anonim = false;
              context.read<CoreScreenBloc>().add(CoreScreenGoToMainScreenEvent());
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
