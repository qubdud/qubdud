import 'package:flutter/material.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_card.dart';

/// Regulamin + polityka prywatności. Miejsca oznaczone [DO UZUPEŁNIENIA]
/// wymagają danych operatora (nazwa, adres, e-mail) przed publikacją.
class RulesPage extends StatelessWidget {
  const RulesPage({super.key});

  static const _operator = '[DO UZUPEŁNIENIA: nazwa, adres i NIP operatora]';
  static const _contact = '[DO UZUPEŁNIENIA: e-mail kontaktowy operatora]';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _header('Regulamin aplikacji QUBDUD'),
            _section(
              '1. Czym jest aplikacja',
              'QUBDUD łączy firmy usługowe z klientami. Firmy publikują filmy '
                  'prezentujące swoją działalność, udostępniają terminy w kalendarzu '
                  'i odpowiadają na zgłoszenia. Klienci wyszukują firmy, dodają '
                  'zgłoszenia, rezerwują terminy, rozmawiają przez czat i wystawiają '
                  'recenzje. Operatorem aplikacji jest $_operator.',
            ),
            _section(
              '2. Konto',
              'Przeglądanie prezentacji jest możliwe bez konta. Do kontaktu z firmą, '
                  'dodawania zgłoszeń, rezerwacji, recenzji i wiadomości wymagane jest '
                  'konto. Rejestrując konto firmowe oświadczasz, że jesteś uprawniony '
                  'do reprezentowania firmy, a podane dane (w tym NIP i adres) są '
                  'prawdziwe. Jedno konto firmowe ma dwa tryby: Firma i Użytkownik.',
            ),
            _section(
              '3. Zgłoszenia i oferty',
              'Zgłoszenie jest widoczne dla firm z danej branży w okolicy przez '
                  '10 dni, po czym wygasa automatycznie. Firma może odpowiedzieć '
                  'ofertą, wiadomością lub telefonicznie. Przyjęcie oferty przez '
                  'klienta ukrywa zgłoszenie przed innymi firmami do czasu jego '
                  'odblokowania. Oferty nie są wiążące — umowę zawierają strony '
                  'poza aplikacją.',
            ),
            _section(
              '4. Rezerwacje terminów',
              'Kliknięcie w wolny termin jest prośbą o rezerwację. Firma ją '
                  'potwierdza lub odrzuca. Niepotwierdzona prośba wygasa po godzinie. '
                  'Odwołanie terminu jest możliwe w zakładce Rezerwacje.',
            ),
            _section(
              '5. Realizacje i zdjęcia',
              'Firma może dodać zdjęcia wykonanej pracy do zgłoszenia. Trafiają one '
                  'do portfolio firmy wyłącznie po potwierdzeniu przez klienta. '
                  'Klient może również dodać własne zdjęcia — wtedy o ich publikacji '
                  'decyduje firma, a zdjęcie jest oznaczone jako pochodzące od klienta. '
                  'Dodając zdjęcia oświadczasz, że masz do nich prawa i nie naruszają '
                  'one wizerunku osób trzecich.',
            ),
            _section(
              '6. Recenzje',
              'Recenzję może wystawić wyłącznie klient, który miał potwierdzoną '
                  'realizację lub przyjęty termin w danej firmie. Recenzje muszą '
                  'opierać się na rzeczywistych doświadczeniach. Zabronione są '
                  'recenzje fikcyjne, zlecane lub mające na celu nieuczciwe zaniżenie '
                  'albo zawyżenie oceny. Firma może odpowiedzieć na recenzję jednym '
                  'komentarzem.',
            ),
            _section(
              '7. Treści użytkowników',
              'Publikujesz treści na własną odpowiedzialność. Zabronione są treści '
                  'bezprawne, obraźliwe, wprowadzające w błąd, naruszające prawa osób '
                  'trzecich (w tym autorskie i wizerunek) oraz spam. Treści naruszające '
                  'regulamin mogą zostać usunięte, a konto zablokowane.',
            ),
            _section(
              '8. Odpowiedzialność',
              'Aplikacja służy do nawiązywania kontaktu. Operator nie jest stroną '
                  'umów między klientami a firmami i nie odpowiada za jakość, '
                  'terminowość ani rozliczenie usług. Operator nie weryfikuje '
                  'uprawnień zawodowych firm.',
            ),
            _section(
              '9. Usunięcie konta i zmiany regulaminu',
              'Możesz w każdej chwili zażądać usunięcia konta wraz z danymi, pisząc '
                  'na $_contact. Recenzje mogą pozostać w formie zanonimizowanej. '
                  'O istotnych zmianach regulaminu poinformujemy w aplikacji; dalsze '
                  'korzystanie oznacza akceptację zmian.',
            ),
            const SizedBox(height: 8),
            _header('Polityka prywatności (RODO)'),
            _section(
              'Administrator danych',
              'Administratorem Twoich danych osobowych jest $_operator. '
                  'Kontakt w sprawach danych: $_contact.',
            ),
            _section(
              'Jakie dane przetwarzamy',
              '• Konto: imię, nazwisko, e-mail, telefon, opis; dla firm dodatkowo '
                  'nazwa, NIP, adres i lokalizacja działalności, strona www.\n'
                  '• Treści: zgłoszenia (opis, zdjęcie lub film, lokalizacja), '
                  'prezentacje, oferty, wiadomości na czacie, rezerwacje, recenzje, '
                  'zdjęcia realizacji, prywatne notatki firmy o klientach.\n'
                  '• Techniczne: identyfikator urządzenia do powiadomień push, '
                  'status obecności w czacie, historia wyszukiwań (tylko lokalnie '
                  'na Twoim telefonie).',
            ),
            _section(
              'Cele i podstawy prawne',
              '• Świadczenie usługi (art. 6 ust. 1 lit. b RODO): konto, kontakt '
                  'firma–klient, rezerwacje, powiadomienia o zdarzeniach w aplikacji.\n'
                  '• Uzasadniony interes (art. 6 ust. 1 lit. f): bezpieczeństwo, '
                  'zapobieganie nadużyciom, statystyki działania aplikacji.\n'
                  '• Zgoda (art. 6 ust. 1 lit. a): powiadomienia push — możesz ją '
                  'cofnąć w ustawieniach telefonu.',
            ),
            _section(
              'Kto widzi Twoje dane',
              'Prezentacje firm i recenzje są publiczne. Dane zgłoszenia wraz z '
                  'imieniem i telefonem widzą zalogowane firmy z danej branży w '
                  'okolicy, aby mogły się z Tobą skontaktować. Dane firmy (telefon, '
                  'adres, www) widzą zalogowani użytkownicy — firma decyduje w profilu, '
                  'co pokazać. Prywatne notatki firmy o klientach widzi tylko ta firma. '
                  'Wiadomości widzą wyłącznie uczestnicy rozmowy.',
            ),
            _section(
              'Odbiorcy i przekazywanie danych',
              'Dane są przechowywane w usługach Google Firebase (Google Ireland Ltd.) '
                  'w centrum danych w Unii Europejskiej (Warszawa). Google przetwarza '
                  'je jako podmiot przetwarzający na podstawie umowy powierzenia. '
                  'Nie sprzedajemy danych i nie przekazujemy ich innym podmiotom '
                  'w celach marketingowych.',
            ),
            _section(
              'Jak długo przechowujemy dane',
              'Dane konta — do usunięcia konta. Zgłoszenia — do 10 dni od '
                  'wystawienia, potem oznaczane jako zamknięte i widoczne tylko dla '
                  'autora do czasu usunięcia. Wiadomości i rezerwacje — do usunięcia '
                  'konta. Powiadomienia — do usunięcia przez Ciebie. Po usunięciu konta '
                  'recenzje mogą pozostać w formie zanonimizowanej.',
            ),
            _section(
              'Twoje prawa',
              'Masz prawo dostępu do danych, ich sprostowania, usunięcia, '
                  'ograniczenia przetwarzania, przenoszenia oraz sprzeciwu wobec '
                  'przetwarzania opartego na uzasadnionym interesie. Masz też prawo '
                  'wniesienia skargi do Prezesa Urzędu Ochrony Danych Osobowych. '
                  'Żądania kieruj na $_contact.',
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _header(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: cDarkBrown)),
      );

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cDarkBrown)),
              const SizedBox(height: 8),
              Text(body,
                  style: const TextStyle(
                      fontSize: 14, color: cDarkBrown, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}
