import 'package:flutter/material.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_card.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _section(
              '1. Czym jest aplikacja',
              'Aplikacja QUBDUD łączy firmy usługowe z użytkownikami. Firmy publikują '
                  'filmy prezentujące swoją działalność, a użytkownicy mogą dodawać '
                  'zgłoszenia (np. awarie lub potrzebę wykonania usługi), przeglądać firmy, '
                  'wystawiać recenzje oraz kontaktować się przez czat.',
            ),
            _section(
              '2. Konto',
              'Do publikowania treści (zgłoszeń, filmów, recenzji, wiadomości) wymagane '
                  'jest konto. Rejestrując konto firmowe oświadczasz, że jesteś uprawniony '
                  'do reprezentowania firmy, którą rejestrujesz, a podane dane (w tym NIP '
                  'i adres prowadzenia działalności) są prawdziwe. Przeglądanie treści jest '
                  'możliwe bez konta.',
            ),
            _section(
              '3. Treści użytkowników',
              'Publikujesz treści na własną odpowiedzialność. Zabronione jest zamieszczanie '
                  'treści bezprawnych, obraźliwych, wprowadzających w błąd, naruszających '
                  'prawa osób trzecich (w tym prawa autorskie i wizerunek) oraz spamu. '
                  'Treści naruszające regulamin mogą zostać usunięte, a konto zablokowane.',
            ),
            _section(
              '4. Recenzje',
              'Recenzje powinny opierać się na rzeczywistych doświadczeniach z daną firmą. '
                  'Zabronione jest wystawianie recenzji fikcyjnych, zlecanych lub mających '
                  'na celu nieuczciwe zaniżenie albo zawyżenie oceny.',
            ),
            _section(
              '5. Odpowiedzialność',
              'Aplikacja służy wyłącznie do nawiązywania kontaktu między użytkownikami '
                  'a firmami. Nie jesteśmy stroną umów zawieranych między nimi i nie '
                  'odpowiadamy za jakość, terminowość ani rozliczenie usług.',
            ),
            _section(
              '6. Dane osobowe (RODO)',
              'Administratorem danych osobowych jest operator aplikacji. Przetwarzamy dane '
                  'podane przy rejestracji (imię, nazwisko, e-mail, telefon, a dla firm także '
                  'dane firmy) oraz treści publikowane w aplikacji — wyłącznie w celu '
                  'świadczenia usług aplikacji. Masz prawo dostępu do swoich danych, ich '
                  'sprostowania, usunięcia oraz przenoszenia. Dane nie są sprzedawane '
                  'podmiotom trzecim.',
            ),
            _section(
              '7. Usunięcie konta',
              'Możesz w każdej chwili zażądać usunięcia konta wraz z powiązanymi danymi. '
                  'Publiczne treści (np. recenzje) mogą pozostać w formie zanonimizowanej.',
            ),
            _section(
              '8. Zmiany regulaminu',
              'Regulamin może ulec zmianie. O istotnych zmianach poinformujemy w aplikacji. '
                  'Dalsze korzystanie z aplikacji po zmianie oznacza jej akceptację.',
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: WCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: cDarkBrown)),
              const SizedBox(height: 8),
              Text(body,
                  style: const TextStyle(fontSize: 15, color: cDarkBrown)),
            ],
          ),
        ),
      ),
    );
  }
}
