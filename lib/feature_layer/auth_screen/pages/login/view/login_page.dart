import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/constants.dart';
import '../../../../../shared/demo_accounts.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_checkbox.dart';
import '../../../../../shared/widgets/w_input_field.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../core_screen/bloc/core_screen_bloc.dart';
import '../../../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  DemoAccount? _selectedDemo;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  static const _keyEmail = 'saved_email';
  static const _keyRemember = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (remember) {
      setState(() {
        _rememberMe = true;
        _email.text = prefs.getString(_keyEmail) ?? '';
      });
    }
  }

  Future<void> _saveEmailIfNeeded(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keyEmail, email);
    } else {
      await prefs.remove(_keyEmail);
      await prefs.setBool(_keyRemember, false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _email.text.trim().isEmpty ? 'Pole wymagane' : null;
      _passwordError = _password.text.trim().isEmpty ? 'Pole wymagane' : null;
      _generalError = null;
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      await _saveEmailIfNeeded(_email.text.trim());
      Globals.instance.anonim = false;  // ← DODAJ
      if (!mounted) return;
      context.read<CoreScreenBloc>().add(CoreScreenGoToMainScreenEvent());
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            _generalError = 'Nieprawidłowy e-mail lub hasło.';
            break;
          case 'invalid-email':
            _emailError = 'Nieprawidłowy adres e-mail.';
            break;
          case 'user-disabled':
            _generalError = 'Konto zostało zablokowane.';
            break;
          default:
            _generalError = e.message ?? 'Błąd logowania.';
        }
      });
    } catch (e) {
      setState(() => _generalError = 'Wystąpił nieoczekiwany błąd.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _browseAnonymously() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      Globals.instance.anonim = true;   // ← DODAJ
      if (!mounted) return;
      context.read<CoreScreenBloc>().add(CoreScreenGoToMainScreenEvent());
    } catch (e) {
      setState(() => _generalError = 'Nie udało się uruchomić trybu przeglądania.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Loading();

    final topPadding = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: topPadding > 1 ? topPadding : 64),
          const SizedBox(height: 20),
          const Text('QUBDUD',
              style: TextStyle(fontSize: 33, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          WButton(text: 'Przeglądaj', onPressed: _browseAnonymously),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: WLabel(text: 'Logowanie')),
                const SizedBox(height: 16),

                // ── WERSJA TESTOWA: szybki wybór konta ─────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DemoAccount>(
                      isExpanded: true,
                      value: _selectedDemo,
                      hint: const Text('⚡ Wybierz konto testowe',
                          style: TextStyle(fontSize: 15)),
                      items: demoAccounts
                          .map((a) => DropdownMenuItem(
                                value: a,
                                child: Text(a.label,
                                    style: const TextStyle(fontSize: 15),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (a) {
                        if (a == null) return;
                        setState(() {
                          _selectedDemo = a;
                          _email.text = a.email;
                          _password.text = a.password;
                          _emailError = null;
                          _passwordError = null;
                          _generalError = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                WInputField(
                  controller: _email,
                  label: 'E-mail',
                  errorText: _emailError,
                  isPassword: false,
                  hintText: 'Wpisz adres e-mail',
                //  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                WInputField(
                  controller: _password,
                  label: 'Hasło',
                  errorText: _passwordError,
                  hintText: 'Wpisz hasło',
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onTogglePasswordVisibility: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    WCheckbox(
                      isError: false,
                      value: _rememberMe,
                      onChanged: (val) =>
                          setState(() => _rememberMe = val ?? false),
                    ),
                    const SizedBox(width: 12),
                    const Text('Zapamiętaj mnie', style: TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_generalError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_generalError!,
                        style: const TextStyle(color: Colors.red, fontSize: 14)),
                  ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(AuthGoToForgotPasswordPageEvent()),
                    child: const Text('Zapomniałeś hasła?',
                        style: TextStyle(
                          color: cDarkerBlue,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        )),
                  ),
                ),
                const SizedBox(height: 24),
                Center(child: WButton(text: 'Zaloguj się', onPressed: _login)),
                const SizedBox(height: 32),
                const Center(
                  child: Text('Nie masz konta?',
                      style: TextStyle(color: cDarkBrown)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: GestureDetector(
                    onTap: () => context
                        .read<AuthBloc>()
                        .add(AuthGoToRegisterPageEvent()),
                    child: const Text('Zarejestruj się',
                        style: TextStyle(
                          color: cDarkBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}