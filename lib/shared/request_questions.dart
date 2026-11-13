/// Pytania kreatora zgłoszenia — wspólne (termin, budżet) i zależne od kategorii.
/// Odpowiedzi trafiają do zgłoszenia jako `timing`, `budget` i `answers` (pytanie → odpowiedź),
/// więc zmiana treści pytań nie psuje starych zgłoszeń.

const kRequestTiming = {
  'asap': 'Jak najszybciej',
  'week': 'W tym tygodniu',
  'month': 'W tym miesiącu',
  'flexible': 'Elastycznie',
};

class RequestQuestion {
  final String label;
  final List<String> options;
  const RequestQuestion(this.label, this.options);
}

const Map<String, List<RequestQuestion>> kCategoryQuestions = {
  'Budowlane i Remontowe': [
    RequestQuestion('Rodzaj obiektu', ['Mieszkanie', 'Dom', 'Lokal usługowy', 'Inny']),
    RequestQuestion('Zakres', ['Drobna naprawa', 'Remont części', 'Remont całości', 'Budowa od zera']),
    RequestQuestion('Materiały', ['Mam swoje', 'Po stronie wykonawcy', 'Do ustalenia']),
  ],
  'Edukacja Kursy Szkolenia': [
    RequestQuestion('Forma', ['Stacjonarnie', 'Online', 'Obojętnie']),
    RequestQuestion('Poziom', ['Podstawowy', 'Średni', 'Zaawansowany']),
    RequestQuestion('Dla kogo', ['Dziecko', 'Dorosły', 'Grupa / firma']),
  ],
  'Finansowe': [
    RequestQuestion('Dla kogo', ['Osoba prywatna', 'Jednoosobowa firma', 'Spółka']),
    RequestQuestion('Rodzaj', ['Jednorazowo', 'Stała współpraca']),
  ],
  'Gastronomiczne': [
    RequestQuestion('Liczba osób', ['Do 10', '10–30', '30–100', 'Ponad 100']),
    RequestQuestion('Forma', ['Dowóz', 'Na miejscu', 'Odbiór osobisty']),
  ],
  'IT i Informatyczne': [
    RequestQuestion('Czego dotyczy', ['Komputer / laptop', 'Telefon', 'Sieć / internet', 'Strona lub aplikacja', 'Inne']),
    RequestQuestion('Gdzie', ['U mnie', 'W serwisie', 'Zdalnie']),
  ],
  'Montaż i naprawa': [
    RequestQuestion('Rodzaj', ['Naprawa', 'Montaż', 'Przegląd / serwis']),
    RequestQuestion('Gdzie', ['U mnie', 'W serwisie']),
    RequestQuestion('Gwarancja producenta', ['Tak', 'Nie', 'Nie wiem']),
  ],
  'Motoryzacja': [
    RequestQuestion('Pojazd', ['Osobowy', 'Dostawczy', 'Motocykl', 'Inny']),
    RequestQuestion('Czy pojazd jeździ?', ['Tak', 'Nie — potrzebna laweta']),
    RequestQuestion('Części', ['Mam swoje', 'Po stronie warsztatu', 'Do ustalenia']),
  ],
  'Organizacja imprez': [
    RequestQuestion('Rodzaj imprezy', ['Urodziny', 'Wesele', 'Firmowa', 'Inna']),
    RequestQuestion('Liczba gości', ['Do 20', '20–50', '50–150', 'Ponad 150']),
  ],
  'Prawne i Administracyjne': [
    RequestQuestion('Dla kogo', ['Osoba prywatna', 'Firma']),
    RequestQuestion('Forma', ['Spotkanie', 'Online / telefon', 'Obojętnie']),
  ],
  'Projektowanie': [
    RequestQuestion('Co projektujemy', ['Wnętrze', 'Budynek', 'Ogród', 'Grafika / logo', 'Inne']),
    RequestQuestion('Etap', ['Pomysł', 'Mam szkice', 'Potrzebna korekta']),
  ],
  'Sklepy': [
    RequestQuestion('Odbiór', ['Dostawa', 'Odbiór osobisty', 'Obojętnie']),
  ],
  'Sprzątanie': [
    RequestQuestion('Rodzaj obiektu', ['Mieszkanie', 'Dom', 'Biuro / lokal', 'Po remoncie']),
    RequestQuestion('Metraż', ['Do 50 m²', '50–100 m²', '100–200 m²', 'Ponad 200 m²']),
    RequestQuestion('Częstotliwość', ['Jednorazowo', 'Co tydzień', 'Co dwa tygodnie', 'Co miesiąc']),
  ],
  'Stolarskie i Ciesielskie': [
    RequestQuestion('Rodzaj', ['Meble na wymiar', 'Naprawa / renowacja', 'Konstrukcja drewniana', 'Inne']),
    RequestQuestion('Montaż', ['Z montażem', 'Bez montażu']),
  ],
  'Transport': [
    RequestQuestion('Co przewozimy', ['Przeprowadzka', 'Meble / AGD', 'Paczki', 'Osoby', 'Inne']),
    RequestQuestion('Wnoszenie', ['Potrzebne', 'Niepotrzebne']),
    RequestQuestion('Trasa', ['W mieście', 'Poza miasto', 'Za granicę']),
  ],
  'Usługi': [
    RequestQuestion('Gdzie', ['U mnie', 'U wykonawcy', 'Online']),
  ],
  'Zdrowie i uroda': [
    RequestQuestion('Gdzie', ['W gabinecie / salonie', 'Z dojazdem do mnie']),
    RequestQuestion('Pierwsza wizyta', ['Tak', 'Nie']),
  ],
  'Zwierzęta': [
    RequestQuestion('Zwierzę', ['Pies', 'Kot', 'Inne']),
    RequestQuestion('Wielkość', ['Małe', 'Średnie', 'Duże']),
    RequestQuestion('Gdzie', ['U mnie', 'U wykonawcy']),
  ],
};

/// Jedna linia podsumowania zgłoszenia dla firmy, np. „W tym tygodniu · do 800 zł · Mieszkanie, Remont części”.
String requestBriefLabel({String timing = '', int? budget, Map<String, String> answers = const {}}) {
  return [
    if (kRequestTiming[timing] != null) kRequestTiming[timing]!,
    if (budget != null) 'budżet do $budget zł',
    ...answers.values,
  ].join(' · ');
}
