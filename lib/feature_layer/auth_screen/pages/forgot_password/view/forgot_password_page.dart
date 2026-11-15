import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_input_field.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Podaj prawidłowy adres e-mail.');
      return;
    }
    setState(() {
      _isLoading = true;
      _emailError = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthGoToForgotPasswordCompletePageEvent());
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            _emailError = 'Nieprawidłowy adres e-mail.';
            break;
          case 'user-not-found':
            _emailError = 'Nie znaleziono konta dla tego adresu.';
            break;
          case 'network-request-failed':
            _emailError = 'Brak połączenia z internetem.';
            break;
          case 'too-many-requests':
            _emailError = 'Za dużo prób — spróbuj za chwilę.';
            break;
          default:
            _emailError = 'Nie udało się wysłać wiadomości (${e.code}).';
        }
      });
    } catch (_) {
      setState(() => _emailError = 'Wystąpił nieoczekiwany błąd.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Loading();

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
            Center(
              child: GestureDetector(
                onTap: () =>
                    context.read<AuthBloc>().add(AuthGoToLoginPageEvent()),
                child: const Text(
                  '< Wróć',
                  style: TextStyle(
                      color: cDarkerBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
            const SizedBox(height: kGapL),
            WLabel(text: 'Nie pamiętasz hasła?'),
            const Text(
              'Podaj adres e-mail, którym utworzono konto. Wyślemy na niego link do ustawienia nowego hasła.',
              style: TextStyle(color: cDarkBrown, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kGapXl),
            WInputField(
              controller: _email,
              label: 'E-mail',
              errorText: _emailError,
              isPassword: false,
              hintText: 'Wpisz adres e-mail',
            ),
            const SizedBox(height: kGapXl),
            WButton(text: 'Wyślij link', onPressed: _sendResetEmail),
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
