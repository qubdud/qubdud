import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../constants.dart';
import 'w_button.dart';

/// Pełnoekranowa blokada dla trybu anonimowego — ten sam wzór co na Profilu.
/// Anonim może tylko szukać i oglądać; dane firm i kontakt są po zalogowaniu.
class AnonimGateView extends StatelessWidget {
  final String what;
  final IconData icon;

  const AnonimGateView({
    super.key,
    this.what = 'Ta część aplikacji jest dostępna po zalogowaniu.',
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(kGapL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey),
            const SizedBox(height: kGapL),
            const Text('Przeglądasz aplikację anonimowo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: kGapS),
            Text(what,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: kGapXl),
            WButton(
              text: 'Zaloguj się',
              onPressed: () =>
                  context.read<MainScreenBloc>().add(LogoutEvent()),
            ),
            const SizedBox(height: kGapL),
            GestureDetector(
              onTap: () => context
                  .read<MainScreenBloc>()
                  .add(LogoutEvent(toRegister: true)),
              child: const Text('lub zarejestruj się',
                  style: TextStyle(
                    color: cDarkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Podpis zamiast nazwy firmy, gdy oglądający nie jest zalogowany.
const String kAnonimCompanyLabel = 'Zaloguj się, aby zobaczyć firmę';

/// Jeden wspólny komunikat dla anonima przy każdej akcji wymagającej konta
/// (ulubione, kontakt, rezerwacja, prośba o telefon…). Zamiast toastów
/// i snackbarów w różnych stylach — dolna karta z przyciskiem logowania.
Future<void> showLoginPrompt(BuildContext context, String action) {
  final bloc = context.read<MainScreenBloc>();
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(kGapL, kGapXl, kGapL, kGapL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: kGapM),
            const Text('Przeglądasz aplikację anonimowo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: kGapS),
            Text('Aby $action, zaloguj się lub załóż konto.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: kGapL),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  bloc.add(LogoutEvent());
                },
                child: const Text('Zaloguj się'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nie teraz'),
            ),
          ],
        ),
      ),
    ),
  );
}
