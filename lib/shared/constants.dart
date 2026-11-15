import 'dart:ui';

import 'package:flutter/material.dart';



const cMidBrown       = Color(0xFF888888); // Piaskowy beż (zamiast ciemnego)
const cLightBrown     = Color(0xFFdddddd); // Jaśniutki krem
const cLighterBrown   = Color(0xFFeeeeee); // Bardzo jasny, prawie biały beż

// Jasne odcienie niebieskiego – bardziej świeże i przyjazne
const cDarkBlue       = Color(0xFF2A4Cd7); // Nasycony ale "lekki" niebieski
const cDarkerBlue     = Color(0xFF102FaE); // Klasyczny, czysty niebieski (material blue)


const cDarkBrown = Color(0xFF222222);
//const cMidBrown = Color(0xFF61553A);
//const cLightBrown = Color(0xFFECE0C6);
//const cLighterBrown = Color(0xFFFAF7F0);

//const cDarkBlue = Color(0xFF2D32AA);
//const cDarkerBlue = Color(0xFF212861);

const cMidOrange = Color(0xFFF39323);
const cMidPurple = Color(0xFFAF5DFF);
const cMidCyan = Color(0xFF2BD4D9);

const Color cGradientOrangeStart = Color(0xFFD7B059);
const Color cGradientOrangeEnd = Color(0xFFF8E278);

const cMidPink = Color(0xFFFF6065);
const cMidRed = Color(0xFFED285B);

final cDisabledBorderColor = Colors.grey.withOpacity(0.1);
final cDisabledColor = Colors.grey.withOpacity(0.5);

const double minWideScreen = 1200.0;
const double maxColumnSize = 600.0;



final Map<String, List<String>> categories = {
  'Budowlane i Remontowe': [
    'Brukarz',
    'Budowa domów murowanych',
    'Dekarz',
    'Elektryk',
    'Geodeta',
    'Glazurnik',
    'Hydraulik',
    'Kominiarz',
    'Murarz',
    'Posadzki',
    'Remonty',
    'Tynkarz',
    'Wykończenia wnętrz',
    'Wynajem sprzętu budowlanego',
    'Złota rączka',
  ],
  'Edukacja Kursy Szkolenia': [
    'Korepetycje',
    'Kurs kosmetyczny',
    'Kurs makijażu',
    'Kurs nurkowania',
    'Kurs prawa jazdy',
    'Kurs programowania dla dzieci',
    'Kursy językowe',
    'Nauka jazdy konnej',
    'Nauka tańca',
    'Przedszkola',
    'Szkolenia BHP',
    'Szkolenia i kursy',
    'Szkoła',
    'Żłobek',
  ],
  'Finansowe': [
    'Biuro rachunkowe i księgowe',
    'Doradztwo inwestycyjne',
    'Ubezpieczenia',
    'Usługi finansowe',
  ],
  'Gastronomiczne': [
    'Catering',
    'Cukiernia',
    'Food truck',
    'Kawiarnia',
    'Pizzeria',
    'Restauracja',
  ],
  'IT i Informatyczne': [
    'Cyberbezpieczeństwo',
    'E-commerce',
    'Internet i telekomunikacja',
    'Naprawa telefonów',
    'Odzyskiwanie danych',
    'Social media',
    'Tworzenie stron www',
    'Usługi IT',
  ],
  'Montaż i naprawa': [
    'Fotowoltaika',
    'Montaż alarmów i monitoringu',
    'Montaż balustrad i poręczy',
    'Montaż drzwi',
    'Montaż klimatyzacji i wentylacji',
    'Montaż kominków i pieców',
    'Montaż konstrukcji stalowych',
    'Montaż mebli',
    'Montaż okien',
    'Montaż pieców gazowych',
    'Montaż rolet i żaluzji',
    'Pompy ciepła',
    'Serwis RTV AGD',
    'Serwis urządzeń biurowych',
    'Serwis wind i dźwigów',
  ],
  'Motoryzacja': [
    'Auto detailing i oklejanie szyb',
    'Blacharz samochodowy',
    'Elektryk samochodowy',
    'Lakiernik',
    'Mechanik samochodowy',
    'Myjnia ręczna',
    'Serwis klimatyzacji samochodowej',
    'Serwis motocykli i skuterów',
    'Warsztat tuningowy',
    'Wulkanizacja',
  ],
  'Organizacja imprez': [
    'Escape room',
    'Organizacja imprez',
    'Wypożyczalnia sprzętu eventowego',
    'Wypożyczalnia strojów',
    'Zespół muzyczny',
  ],
  'Prawne i Administracyjne': [
    'Adwokat',
    'Kancelaria prawnicza',
    'Notariusz',
    'Radca prawny',
    'Usługi windykacyjne',
  ],
  'Projektowanie': [
    'Architekt',
    'Architekt krajobrazu',
    'Projektant graficzny',
    'Projektant wnętrz',
    'Projektowanie ogrodów',
  ],
  'Sklepy': [
    'Sklep BHP',
    'Sklep bio i eko',
    'Sklep budowlany',
    'Sklep ceramika rekodzieło',
    'Sklep chemiczny',
    'Sklep dekoracji i art. eventowych',
    'Sklep elektryczny',
    'Sklep farby lakiery',
    'Sklep fotograficzny',
    'Sklep galanterii skórzanej',
    'Sklep hydrauliczny',
    'Sklep internetowy',
    'Sklep kawy i herbaty',
    'Sklep komputerowy',
    'Sklep kosmetyków i chemii prof.',
    'Sklep materiałów do pakowania',
    'Sklep meblowy',
    'Sklep medyczny',
    'Sklep mięsny',
    'Sklep motoryzacyjny',
    'Sklep muzyczny',
    'Sklep myśliwski',
    'Sklep narzędza ręczne i elektronarzędzia',
    'Sklep obuwniczy',
    'Sklep odzież robocza',
    'Sklep odzieżowy',
    'Sklep ogrodniczy',
    'Sklep opał  pellet  drewno',
    'Sklep papierniczy i biurowy',
    'Sklep rowerowy',
    'Sklep RTV AGD',
    'Sklep sportowy',
    'Sklep spożywczy',
    'Sklep wędkarski',
    'Sklep winiarski',
    'Sklep zabawki',
    'Sklep zoologiczny',
  ],
  'Sprzątanie': [
    'Pralnia chemiczna',
    'Pranie dywanów',
    'Sprzątanie',
  ],
  'Stolarskie i Ciesielskie': [
    'Budowa domów drewnianych',
    'Cieśla',
    'Meble i zabudowa',
    'Podłogi Parkiety',
    'Renowacja mebli',
    'Stolarz',
  ],
  'Transport': [
    'Pomoc drogowa',
    'Przewóz osób',
    'Transport',
    'Wynajem lawet i przyczep',
    'Wynajem samochodów',
  ],
  'Usługi': [
    'Agroturystyka',
    'Biuro turystyczne',
    'Czyszczenie dachów i elewacji',
    'Fotograf',
    'Jubiler',
    'Nieruchomości',
    'Ochrona',
    'Piekarnia',
    'Serwis rowerów',
    'Spawanie',
    'Szewc',
    'Ślusarz',
    'Tłumaczenia',
    'Usługi HR',
    'Usługi koparką',
    'Usługi ogrodnicze',
  ],
  'Zdrowie i uroda': [
    'Barber',
    'Dentyści',
    'Depilacja laserowa',
    'Dietetyk',
    'Fizjoterapia',
    'Fryzjer damski',
    'Fryzjer męski',
    'Joga',
    'Kosmetyczka',
    'Lekarz',
    'Logopeda',
    'Makijaż',
    'Manicure i pedicure',
    'Masażysta',
    'Medycyna estetyczna',
    'Przedłużanie rzęs',
    'Przychodnie lekarskie',
    'Psycholog dziecięcy',
    'Psychoterapeuta',
    'Rehabilitacja',
    'Siłownia',
    'Solarium',
    'SPA',
    'Tatuaże',
    'Trener personalny',
  ],
  'Zwierzęta': [
    'Behaviorysta zwierzęcy',
    'Groomer',
    'Hotel dla zwierząt',
    'Opieka nad zwierzętami',
    'Tresura psów',
    'Weterynarz',
  ],
};

/// Branże, w których klient może wysłać zgłoszenie awaryjne (is24, czerwony push).
/// Ta sama lista jest w functions/index.js (EMERGENCY_SECTORS).
const kEmergencySectors = {
  'Elektryk',
  'Hydraulik',
  'Montaż pieców gazowych',
  'Pompy ciepła',
  'Serwis RTV AGD',
  'Pomoc drogowa',
  'Ślusarz',
  'Weterynarz',
};

