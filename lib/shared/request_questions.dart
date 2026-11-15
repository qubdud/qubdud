/// Pytania kreatora zgłoszenia — wspólne (termin, budżet) i zależne od kategorii albo branży.
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
    RequestQuestion('Rodzaj obiektu', ['Mieszkanie', 'Dom', 'Biuro / lokal']),
    RequestQuestion('Rodzaj sprzątania', ['Standardowe', 'Generalne', 'Po remoncie']),
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

const _obiekt = RequestQuestion('Rodzaj obiektu', ['Mieszkanie', 'Dom', 'Lokal usługowy', 'Inny']);
const _materialy = RequestQuestion('Materiały', ['Mam swoje', 'Po stronie wykonawcy', 'Do ustalenia']);
const _naIle = RequestQuestion('Na ile', ['1 dzień', 'Kilka dni', 'Tydzień i dłużej']);
const _pojazd = RequestQuestion('Pojazd', ['Osobowy', 'Dostawczy', 'Motocykl', 'Inny']);
const _pierwszaWizyta = RequestQuestion('Pierwsza wizyta', ['Tak', 'Nie']);

const _montazNaMiejscu = [
  RequestQuestion('Rodzaj', ['Nowy montaż', 'Wymiana', 'Naprawa / regulacja']),
  _obiekt,
  _materialy,
];
const _ogrzewanieChlodzenie = [
  RequestQuestion('Rodzaj', ['Awaria / naprawa', 'Nowy montaż / wymiana', 'Przegląd / serwis']),
  _obiekt,
  RequestQuestion('Gwarancja producenta', ['Tak', 'Nie', 'Nie wiem']),
];
const _gabinetLubOnline = [
  RequestQuestion('Gdzie', ['W gabinecie', 'Online']),
  _pierwszaWizyta,
];

/// Branże, do których nie pasują pytania ich kategorii (np. pralnia w „Sprzątaniu”).
const Map<String, List<RequestQuestion>> kSectorQuestions = {
  // Budowlane i Remontowe
  'Brukarz': [
    RequestQuestion('Co do ułożenia', ['Podjazd', 'Chodnik / ścieżka', 'Taras', 'Parking / plac']),
    RequestQuestion('Powierzchnia', ['Do 20 m²', '20–50 m²', '50–150 m²', 'Ponad 150 m²']),
    _materialy,
  ],
  'Budowa domów murowanych': [
    RequestQuestion('Etap', ['Stan surowy otwarty', 'Stan surowy zamknięty', 'Dom pod klucz', 'Rozbudowa']),
    RequestQuestion('Projekt', ['Mam projekt', 'Potrzebuję projektu']),
    _materialy,
  ],
  'Dekarz': [
    RequestQuestion('Rodzaj prac', ['Naprawa / przeciek', 'Wymiana pokrycia', 'Nowy dach', 'Rynny / obróbki']),
    RequestQuestion('Rodzaj obiektu', ['Dom', 'Budynek gospodarczy', 'Blok / kamienica', 'Inny']),
    _materialy,
  ],
  'Elektryk': [
    RequestQuestion('Rodzaj prac', ['Awaria', 'Drobna naprawa / montaż', 'Nowa instalacja / wymiana', 'Pomiary / przegląd']),
    _obiekt,
  ],
  'Geodeta': [
    RequestQuestion('Rodzaj usługi', ['Mapa do celów projektowych', 'Wytyczenie budynku', 'Podział / wznowienie granic', 'Inwentaryzacja powykonawcza', 'Inne']),
    RequestQuestion('Nieruchomość', ['Działka niezabudowana', 'Działka z budynkiem', 'Lokal']),
  ],
  'Hydraulik': [
    RequestQuestion('Rodzaj prac', ['Awaria / przeciek', 'Udrożnienie odpływu', 'Montaż / wymiana', 'Nowa instalacja']),
    _obiekt,
  ],
  'Kominiarz': [
    RequestQuestion('Usługa', ['Przegląd okresowy', 'Czyszczenie', 'Udrożnienie', 'Opinia kominiarska']),
    RequestQuestion('Przewód', ['Gazowy', 'Dymowy (węgiel / drewno)', 'Wentylacyjny', 'Kominek']),
  ],
  'Wynajem sprzętu budowlanego': [
    RequestQuestion('Sprzęt', ['Rusztowanie', 'Betoniarka / zagęszczarka', 'Elektronarzędzia', 'Minikoparka', 'Inne']),
    _naIle,
    RequestQuestion('Dostawa', ['Odbiorę sam', 'Potrzebny dowóz']),
  ],
  'Złota rączka': [
    RequestQuestion('Zakres', ['Jedna drobna naprawa', 'Kilka drobnych prac', 'Montaż (półki, karnisze, lampy)']),
    _obiekt,
    _materialy,
  ],
  // Edukacja Kursy Szkolenia
  'Korepetycje': [
    RequestQuestion('Przedmiot', ['Matematyka', 'Język obcy', 'Język polski', 'Fizyka / chemia', 'Inny']),
    RequestQuestion('Poziom', ['Szkoła podstawowa', 'Liceum / technikum', 'Matura', 'Studia']),
    RequestQuestion('Forma', ['Stacjonarnie', 'Online', 'Obojętnie']),
  ],
  'Kurs prawa jazdy': [
    RequestQuestion('Kategoria', ['B', 'A / A2 / AM', 'C / C+E', 'Inna']),
    RequestQuestion('Zakres', ['Pełny kurs', 'Jazdy doszkalające']),
    RequestQuestion('Skrzynia biegów', ['Manualna', 'Automatyczna', 'Obojętnie']),
  ],
  'Przedszkola': [
    RequestQuestion('Wiek dziecka', ['2–3 lata', '4–5 lat', '6 lat']),
    RequestQuestion('Od kiedy', ['Od zaraz', 'Od września', 'Inny termin']),
    RequestQuestion('Rodzaj', ['Publiczne', 'Prywatne', 'Obojętnie']),
  ],
  'Szkoła': [
    RequestQuestion('Poziom', ['Podstawowa', 'Liceum / technikum', 'Policealna / dla dorosłych']),
    RequestQuestion('Od kiedy', ['Od zaraz', 'Od września', 'Inny termin']),
    RequestQuestion('Rodzaj', ['Publiczna', 'Prywatna / społeczna', 'Obojętnie']),
  ],
  'Żłobek': [
    RequestQuestion('Wiek dziecka', ['Do 1 roku', '1–2 lata', '2–3 lata']),
    RequestQuestion('Od kiedy', ['Od zaraz', 'Od września', 'Inny termin']),
    RequestQuestion('Rodzaj', ['Publiczny', 'Prywatny', 'Obojętnie']),
  ],
  // Finansowe
  'Ubezpieczenia': [
    RequestQuestion('Co ubezpieczyć', ['Samochód', 'Dom / mieszkanie', 'Życie / zdrowie', 'Firmę', 'Podróż']),
    RequestQuestion('Dla kogo', ['Osoba prywatna', 'Firma']),
  ],
  // IT i Informatyczne
  'Cyberbezpieczeństwo': [
    RequestQuestion('Czego dotyczy', ['Włamanie / wirus', 'Audyt zabezpieczeń', 'Szkolenie', 'Inne']),
    RequestQuestion('Dla kogo', ['Osoba prywatna', 'Firma']),
  ],
  'E-commerce': [
    RequestQuestion('Zakres', ['Nowy sklep', 'Rozwój sklepu', 'Integracje / płatności', 'Marketing']),
    RequestQuestion('Platforma', ['Shopify', 'WooCommerce', 'PrestaShop', 'Inna / nie wiem']),
  ],
  'Naprawa telefonów': [
    RequestQuestion('Usterka', ['Zbity ekran', 'Bateria / ładowanie', 'Zalanie', 'Nie włącza się', 'Inne']),
    RequestQuestion('Gdzie', ['W serwisie', 'Z dojazdem do mnie']),
  ],
  'Odzyskiwanie danych': [
    RequestQuestion('Nośnik', ['Dysk komputera', 'Pendrive / karta pamięci', 'Telefon', 'Serwer / NAS']),
    RequestQuestion('Co się stało', ['Usunięte pliki', 'Uszkodzenie nośnika', 'Nie wiem']),
  ],
  'Social media': [
    RequestQuestion('Platforma', ['Facebook / Instagram', 'TikTok', 'LinkedIn', 'Kilka']),
    RequestQuestion('Zakres', ['Prowadzenie profilu', 'Kampania reklamowa', 'Jednorazowa konsultacja']),
  ],
  'Tworzenie stron www': [
    RequestQuestion('Rodzaj', ['Strona wizytówka', 'Sklep internetowy', 'Aplikacja', 'Poprawki istniejącej strony']),
    RequestQuestion('Treści i zdjęcia', ['Mam gotowe', 'Do przygotowania']),
  ],
  // Montaż i naprawa
  'Fotowoltaika': [
    RequestQuestion('Rodzaj', ['Nowa instalacja', 'Serwis / naprawa', 'Rozbudowa / magazyn energii']),
    RequestQuestion('Miejsce montażu', ['Dach domu', 'Grunt', 'Budynek gospodarczy / firma']),
    RequestQuestion('Moc', ['Do 5 kW', '5–10 kW', 'Ponad 10 kW', 'Nie wiem']),
  ],
  'Montaż alarmów i monitoringu': [
    RequestQuestion('System', ['Alarm', 'Kamery', 'Alarm i kamery', 'Domofon / wideodomofon']),
    RequestQuestion('Rodzaj', ['Nowy montaż', 'Rozbudowa', 'Naprawa / serwis']),
    _obiekt,
  ],
  'Montaż balustrad i poręczy': _montazNaMiejscu,
  'Montaż drzwi': _montazNaMiejscu,
  'Montaż klimatyzacji i wentylacji': _ogrzewanieChlodzenie,
  'Montaż kominków i pieców': _ogrzewanieChlodzenie,
  'Montaż konstrukcji stalowych': [
    RequestQuestion('Rodzaj', ['Hala / wiata', 'Schody / antresola', 'Konstrukcja na zamówienie']),
    RequestQuestion('Projekt', ['Mam projekt', 'Potrzebuję projektu']),
    _materialy,
  ],
  'Montaż mebli': [
    RequestQuestion('Co do montażu', ['Pojedynczy mebel', 'Kilka mebli', 'Kuchnia', 'Szafa / zabudowa']),
    RequestQuestion('Wniesienie', ['Potrzebne', 'Niepotrzebne']),
  ],
  'Montaż okien': _montazNaMiejscu,
  'Montaż pieców gazowych': _ogrzewanieChlodzenie,
  'Montaż rolet i żaluzji': _montazNaMiejscu,
  'Pompy ciepła': _ogrzewanieChlodzenie,
  'Serwis wind i dźwigów': [
    RequestQuestion('Rodzaj', ['Awaria / naprawa', 'Przegląd / konserwacja', 'Modernizacja', 'Nowy montaż']),
    RequestQuestion('Obiekt', ['Blok / wspólnota', 'Biuro / firma', 'Inny']),
  ],
  // Motoryzacja
  'Auto detailing i oklejanie szyb': [
    _pojazd,
    RequestQuestion('Usługa', ['Detailing wnętrza', 'Korekta lakieru / powłoka', 'Przyciemnianie szyb', 'Oklejanie folią']),
  ],
  'Myjnia ręczna': [
    _pojazd,
    RequestQuestion('Zakres', ['Mycie zewnętrzne', 'Wnętrze', 'Kompleksowo']),
  ],
  'Wulkanizacja': [
    _pojazd,
    RequestQuestion('Usługa', ['Wymiana sezonowa', 'Naprawa opony', 'Nowe opony', 'Wyważanie']),
    RequestQuestion('Czy pojazd jeździ?', ['Tak', 'Nie — potrzebna laweta']),
  ],
  // Organizacja imprez
  'Escape room': [
    RequestQuestion('Okazja', ['Urodziny', 'Integracja firmowa', 'Wieczór kawalerski / panieński', 'Bez okazji']),
    RequestQuestion('Liczba osób', ['2–3', '4–5', '6 i więcej']),
  ],
  'Wypożyczalnia sprzętu eventowego': [
    RequestQuestion('Sprzęt', ['Nagłośnienie / oświetlenie', 'Namiot / meble', 'Dmuchańce / atrakcje', 'Inne']),
    RequestQuestion('Dostawa i montaż', ['Potrzebne', 'Odbiorę sam']),
    RequestQuestion('Liczba gości', ['Do 20', '20–50', '50–150', 'Ponad 150']),
  ],
  'Wypożyczalnia strojów': [
    RequestQuestion('Strój', ['Przebranie / kostium', 'Wieczorowy', 'Ślubny', 'Inny']),
    RequestQuestion('Dla kogo', ['Dziecko', 'Dorosły']),
    RequestQuestion('Na ile', ['1 dzień', 'Weekend', 'Dłużej']),
  ],
  // Projektowanie
  'Architekt': [
    RequestQuestion('Co projektujemy', ['Dom jednorodzinny', 'Rozbudowa / przebudowa', 'Budynek usługowy', 'Adaptacja gotowego projektu']),
    RequestQuestion('Etap', ['Pomysł', 'Mam szkice', 'Potrzebna korekta']),
  ],
  'Projektant graficzny': [
    RequestQuestion('Co projektujemy', ['Logo / identyfikacja', 'Ulotka / plakat', 'Grafika do internetu', 'Opakowanie', 'Inne']),
    RequestQuestion('Etap', ['Pomysł', 'Mam szkice', 'Potrzebna korekta']),
  ],
  // Sprzątanie
  'Pralnia chemiczna': [
    RequestQuestion('Co do czyszczenia', ['Odzież', 'Pościel / zasłony', 'Obuwie', 'Inne']),
    RequestQuestion('Odbiór / dostawa', ['Sam przyniosę', 'Odbiór z domu']),
  ],
  'Pranie dywanów': [
    RequestQuestion('Co do prania', ['Dywan', 'Wykładzina', 'Tapicerka', 'Materac']),
    RequestQuestion('Powierzchnia', ['Do 10 m²', '10–30 m²', '30–60 m²', 'Ponad 60 m²']),
    RequestQuestion('Gdzie', ['U mnie', 'Odbiór do pralni']),
  ],
  // Stolarskie i Ciesielskie
  'Budowa domów drewnianych': [
    RequestQuestion('Etap', ['Stan surowy', 'Dom pod klucz', 'Rozbudowa']),
    RequestQuestion('Technologia', ['Szkieletowa', 'Z bali', 'Obojętnie']),
    RequestQuestion('Projekt', ['Mam projekt', 'Potrzebuję projektu']),
  ],
  'Cieśla': [
    RequestQuestion('Rodzaj', ['Więźba dachowa', 'Taras / altana', 'Konstrukcja drewniana', 'Inne']),
    _materialy,
  ],
  'Podłogi Parkiety': [
    RequestQuestion('Rodzaj prac', ['Nowa podłoga', 'Cyklinowanie / renowacja', 'Naprawa']),
    RequestQuestion('Powierzchnia', ['Do 20 m²', '20–50 m²', '50–100 m²', 'Ponad 100 m²']),
    _materialy,
  ],
  // Transport
  'Pomoc drogowa': [
    _pojazd,
    RequestQuestion('Co się stało', ['Nie odpala', 'Wypadek / kolizja', 'Przebita opona', 'Brak paliwa', 'Inne']),
    RequestQuestion('Holowanie', ['Potrzebne', 'Wystarczy pomoc na miejscu', 'Nie wiem']),
  ],
  'Przewóz osób': [
    RequestQuestion('Liczba osób', ['1–4', '5–8', '9–20', 'Ponad 20']),
    RequestQuestion('Trasa', ['W mieście', 'Poza miasto', 'Lotnisko', 'Za granicę']),
    RequestQuestion('Rodzaj', ['Jednorazowo', 'Regularnie']),
  ],
  'Wynajem lawet i przyczep': [
    RequestQuestion('Co wynająć', ['Laweta', 'Przyczepa towarowa', 'Przyczepa kempingowa']),
    _naIle,
  ],
  'Wynajem samochodów': [
    RequestQuestion('Samochód', ['Osobowy', 'Dostawczy / bus', 'Premium', 'Obojętnie']),
    RequestQuestion('Na ile', ['1 dzień', 'Kilka dni', 'Tydzień', 'Miesiąc i dłużej']),
    RequestQuestion('Odbiór', ['W wypożyczalni', 'Podstawienie pod adres']),
  ],
  // Usługi
  'Agroturystyka': [
    RequestQuestion('Liczba osób', ['1–2', '3–4', '5–8', 'Ponad 8']),
    RequestQuestion('Pobyt', ['Weekend', 'Tydzień', 'Dłużej']),
    RequestQuestion('Wyżywienie', ['Tak', 'Nie', 'Obojętnie']),
  ],
  'Biuro turystyczne': [
    RequestQuestion('Rodzaj wyjazdu', ['Wczasy', 'Wycieczka objazdowa', 'Last minute', 'Wyjazd firmowy']),
    RequestQuestion('Kierunek', ['Polska', 'Europa', 'Świat']),
    RequestQuestion('Liczba osób', ['1–2', '3–5', 'Grupa']),
  ],
  'Czyszczenie dachów i elewacji': [
    RequestQuestion('Co do czyszczenia', ['Dach', 'Elewacja', 'Kostka / taras', 'Kilka']),
    RequestQuestion('Rodzaj obiektu', ['Dom', 'Blok / kamienica', 'Lokal / firma']),
  ],
  'Fotograf': [
    RequestQuestion('Okazja', ['Ślub', 'Chrzest / komunia', 'Sesja rodzinna', 'Biznes / produkty', 'Inna']),
    RequestQuestion('Gdzie', ['Plener', 'Studio', 'U mnie']),
  ],
  'Jubiler': [
    RequestQuestion('Usługa', ['Naprawa', 'Wykonanie na zamówienie', 'Grawerowanie', 'Wycena / skup']),
  ],
  'Nieruchomości': [
    RequestQuestion('Cel', ['Kupno', 'Sprzedaż', 'Wynajem', 'Wycena']),
    RequestQuestion('Nieruchomość', ['Mieszkanie', 'Dom', 'Działka', 'Lokal']),
  ],
  'Ochrona': [
    RequestQuestion('Rodzaj', ['Obiekt', 'Impreza', 'Ochrona osobista', 'Monitoring / patrol']),
    RequestQuestion('Na ile', ['Jednorazowo', 'Stała współpraca']),
  ],
  'Piekarnia': [
    RequestQuestion('Zamówienie', ['Codzienne pieczywo', 'Na okazję', 'Dla firmy / sklepu']),
    RequestQuestion('Odbiór', ['Dostawa', 'Odbiór osobisty']),
  ],
  'Serwis rowerów': [
    RequestQuestion('Rodzaj', ['Naprawa', 'Przegląd', 'Złożenie roweru']),
    RequestQuestion('Rower', ['Miejski / trekkingowy', 'Górski / szosowy', 'Elektryczny', 'Dziecięcy']),
    RequestQuestion('Gdzie', ['W serwisie', 'Z dojazdem do mnie']),
  ],
  'Spawanie': [
    RequestQuestion('Rodzaj', ['Naprawa', 'Wykonanie na zamówienie', 'Spawanie na miejscu']),
    RequestQuestion('Materiał', ['Stal', 'Stal nierdzewna', 'Aluminium', 'Nie wiem']),
  ],
  'Szewc': [
    RequestQuestion('Usługa', ['Fleki / zelówki', 'Klejenie / szycie', 'Wymiana zamka', 'Inne']),
    RequestQuestion('Obuwie', ['Damskie', 'Męskie', 'Dziecięce']),
  ],
  'Ślusarz': [
    RequestQuestion('Usługa', ['Otwarcie zamka', 'Wymiana / montaż zamka', 'Dorobienie klucza', 'Kraty / konstrukcje']),
    RequestQuestion('Gdzie', ['Mieszkanie', 'Dom', 'Samochód', 'Lokal / firma']),
  ],
  'Tłumaczenia': [
    RequestQuestion('Rodzaj', ['Pisemne', 'Przysięgłe', 'Ustne']),
    RequestQuestion('Język', ['Angielski', 'Niemiecki', 'Ukraiński', 'Inny']),
    RequestQuestion('Objętość', ['Do 2 stron', '3–10 stron', 'Ponad 10 stron']),
  ],
  'Usługi HR': [
    RequestQuestion('Usługa', ['Rekrutacja', 'Kadry i płace', 'Doradztwo / szkolenia']),
    RequestQuestion('Wielkość firmy', ['Do 10 osób', '10–50 osób', 'Ponad 50 osób']),
  ],
  'Usługi koparką': [
    RequestQuestion('Rodzaj prac', ['Wykop pod fundamenty', 'Przyłącza / rowy', 'Niwelacja terenu', 'Wywóz ziemi']),
    RequestQuestion('Czas pracy', ['Kilka godzin', '1 dzień', 'Kilka dni']),
  ],
  'Usługi ogrodnicze': [
    RequestQuestion('Usługa', ['Koszenie trawy', 'Przycinanie drzew i krzewów', 'Zakładanie ogrodu', 'Stała opieka']),
    RequestQuestion('Powierzchnia', ['Do 200 m²', '200–500 m²', '500–1000 m²', 'Ponad 1000 m²']),
  ],
  // Zdrowie i uroda
  'Dentyści': [
    RequestQuestion('Czego dotyczy', ['Ból zęba', 'Przegląd / higienizacja', 'Leczenie', 'Protetyka / implanty', 'Ortodoncja']),
    _pierwszaWizyta,
  ],
  'Dietetyk': _gabinetLubOnline,
  'Joga': [
    RequestQuestion('Forma', ['Zajęcia grupowe', 'Indywidualnie', 'Online']),
    RequestQuestion('Poziom', ['Początkujący', 'Średnio zaawansowany', 'Zaawansowany']),
  ],
  'Lekarz': [
    RequestQuestion('Gdzie', ['W gabinecie', 'Wizyta domowa', 'Teleporada']),
    _pierwszaWizyta,
  ],
  'Logopeda': [
    RequestQuestion('Dla kogo', ['Dziecko', 'Dorosły']),
    RequestQuestion('Gdzie', ['W gabinecie', 'Online', 'Z dojazdem do mnie']),
  ],
  'Przychodnie lekarskie': [
    RequestQuestion('Gdzie', ['W gabinecie', 'Wizyta domowa', 'Teleporada']),
    _pierwszaWizyta,
  ],
  'Psycholog dziecięcy': _gabinetLubOnline,
  'Psychoterapeuta': _gabinetLubOnline,
  'Siłownia': [
    RequestQuestion('Rodzaj', ['Karnet miesięczny', 'Wejście jednorazowe', 'Zajęcia grupowe']),
    RequestQuestion('Pora', ['Rano', 'Popołudnie', 'Wieczór']),
  ],
  'Tatuaże': [
    RequestQuestion('Rozmiar', ['Mały', 'Średni', 'Duży / rękaw']),
    RequestQuestion('Projekt', ['Mam swój', 'Do zaprojektowania']),
    RequestQuestion('Pierwszy tatuaż', ['Tak', 'Nie']),
  ],
  'Trener personalny': [
    RequestQuestion('Cel', ['Redukcja wagi', 'Budowa mięśni', 'Kondycja', 'Powrót po kontuzji']),
    RequestQuestion('Gdzie', ['Na siłowni', 'Z dojazdem do mnie', 'Online']),
  ],
  // Zwierzęta
  'Hotel dla zwierząt': [
    RequestQuestion('Zwierzę', ['Pies', 'Kot', 'Inne']),
    RequestQuestion('Wielkość', ['Małe', 'Średnie', 'Duże']),
    RequestQuestion('Na ile', ['1–3 dni', 'Do tygodnia', 'Dłużej']),
  ],
  'Weterynarz': [
    RequestQuestion('Czego dotyczy', ['Nagły przypadek', 'Szczepienie / kontrola', 'Leczenie', 'Zabieg']),
    RequestQuestion('Zwierzę', ['Pies', 'Kot', 'Inne']),
    RequestQuestion('Gdzie', ['W gabinecie', 'Wizyta domowa']),
  ],
};

/// Pytania branży mają pierwszeństwo przed pytaniami kategorii.
List<RequestQuestion> requestQuestionsFor(String? category, String? sector) =>
    kSectorQuestions[sector] ?? kCategoryQuestions[category] ?? const [];

/// Jedna linia podsumowania zgłoszenia dla firmy, np. „W tym tygodniu · do 800 zł · Mieszkanie, Remont części”.
String requestBriefLabel({String timing = '', int? budget, Map<String, String> answers = const {}}) {
  return [
    if (kRequestTiming[timing] != null) kRequestTiming[timing]!,
    if (budget != null) 'budżet do $budget zł',
    ...answers.values,
  ].join(' · ');
}
