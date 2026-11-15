# QUBDUD — do zrobienia

Stan: 15.11.2026, wersja 1.4.1+23 (APK testowy pod prywatnym linkiem, pakiety A+B wdrożone).
Kolejność ≈ priorytet. Przy każdym punkcie: co dokładnie zrobić.

## Produkt / UX

1. **„Zgłoszenie 24” tylko w branżach awaryjnych**
   - Dziś checkbox „Wyślij jako zgłoszenie 24” jest przy każdej kategorii (np. sprzątanie, księgowość), a pilne zgłoszenie idzie czerwonym pushem do firm.
   - Pokazywać tylko dla branż awaryjnych: hydraulik, elektryk, ślusarz/zamki, szklarz, ogrzewanie/gaz, pomoc drogowa, dezynsekcja (lista do potwierdzenia).
   - Nazwa: „🔴 Awaria — potrzebuję pomocy w ciągu 24 h”.
   - Najlepiej jako pole `urgentAllowed` w konfiguracji branży (pkt 2).

2. **Pytania kreatora zgłoszenia w bazie, per branża**
   - Dziś na sztywno w `lib/shared/request_questions.dart` (17 kategorii, 41 pytań) — zmiana = nowa wersja apki.
   - Przenieść do Firestore `config/requestQuestions` (edycja w konsoli), apka czyta przy starcie z fallbackiem na wersję w kodzie.
   - Pytania per **branża**, nie per kategoria: dziś „Pralnia chemiczna” i „Pranie dywanów” dostają pytania o metraż i rodzaj sprzątania.
   - Uwaga: reguły pozwalają na max 10 odpowiedzi (`answers.size() <= 10`).

3. **„wystawione wczoraj” przy zgłoszeniu sprzed 2 dni** — liczyć dni kalendarzowe (data lokalna), nie pełne doby.

4. **Tablet: zdjęcie w widoku zgłoszenia zajmuje cały ekran** — ograniczyć wysokość obrazka (np. max 50% ekranu) na szerokich ekranach.

5. **Powiadomienia zgrupowane przez Androida** — tap w zwiniętą grupę otwiera apkę bez przejścia do celu (Android nie przekazuje danych).
   - Częściowo załatwione tagiem per wątek.
   - Pełne rozwiązanie: wiadomości data-only + własne powiadomienia lokalne z podsumowaniem grupy, które otwiera „Alerty”.

6. **Opinie** — reguły są otwarte jak w Google (decyzja), ale apka pokazuje „Dodaj opinię” tylko klientom ze zleceniem albo wizytą u tej firmy (`canReviewCompany`). Do decyzji: zostawić tak (lepsza jakość opinii) czy otworzyć w apce dla wszystkich. Opcjonalnie odznaka „Zweryfikowany klient” liczona w Cloud Function.

7. **Opinia bez zdjęcia — dokończyć test** zapisu i wyświetlania przy pierwszej nowej realizacji (15.11 nie było firmy, której klient testowy jeszcze nie ocenił). Opcja „Bez zdjęcia — tylko ocena i opis” jest w apce, reguły ją przepuszczają.

8. **„Moje zgłoszenia” klienta nie odświeżają się na żywo** po „Zlecenie wykonane (bez zdjęć)” — „Potwierdź / Jeszcze nie” widać dopiero po przełączeniu zakładki (push przychodzi od razu). Nasłuchiwać zmian `realizationStatus` na liście.

9. **Aktualizacje dla testerów z apki** — w `config/app` ustawić `androidUrl` na prywatny link z APK i przy nowej wersji podnosić `minBuild`: testerzy ze starą wersją zobaczą ekran „Zaktualizuj” z przyciskiem do pobrania. Link (Firebase Hosting, kanał podglądu) jest ważny 30 dni od ostatniego wgrania — każde wgranie przedłuża.

## Strona WWW dla gości (zgłoszenie bez apki)

10. **Strona (np. qubdud.pl/zglos)**: gość zgłasza bez instalacji, loguje się linkiem z maila, widzi oferty, przyjmuje, pisze z firmą.
   - Osobny projekt `/web` (Vite + TypeScript + Firebase JS SDK), Firebase Hosting.
   - Gość = zwykły użytkownik Firebase (email link) → reguły, funkcje i apka firmy bez zmian.
   - Etapy: logowanie i profil → formularz (te same pola co apka, zdjęcia bez GPS) → „Moje zgłoszenie” z ofertami → czat → maile → testy i wdrożenie.
   - Do decyzji: **domena** i **dostawca maili** (np. Resend; wysyłka z @domeny wymaga rekordów DNS).
   - Później: rezerwacje terminów i opinie dla gości.

## Wydajność i koszty (pakiet D z przeglądu)

11. **Lista zgłoszeń firmy czyta całą historię branży** + osobny odczyt oferty na każde zgłoszenie. Czytać tylko otwarte z ostatnich ~14 dni (zapytanie po `status` i `timestamp`), oferty jednym zapytaniem.
12. **Listy klientów/firm ładowane „po jednym” (N+1)** — równoległe pobieranie (`Future.wait`) i mniej danych na starcie.
13. **Każdy film w feedzie pobiera wszystkie opinie firmy** — trzymać średnią i liczbę opinii w dokumencie firmy (liczone w Cloud Function).
14. **Filmy prezentacji = główny koszt transferu** — kompresja do 720p (~1–2 MB), cache w telefonie, docelowo tańszy hosting (Cloudflare R2 albo własny serwer).
15. **Drobne z przeglądu**: „Pokazuj telefon/adres” nie ukrywa danych w bazie; brak ochrony przed nakładającymi się terminami; dzwonek: limit 60 przed filtrem trybu; licznik „Kontakty” liczy rozmowy z zablokowanymi; usunięcie slotu poza apką zostawia „przyjętą” wizytę.
16. **Kategorie firm w danych** — część zaimportowanych firm ma złą kategorię (np. „Tuszyk Tattoo” — studio tatuażu — w „Opieka nad zwierzętami”). Przejrzeć `users` z `firma: true` i poprawić `companyCategory`/`companySector`.

## Wydanie

17. **Klucz release** — APK testowy jest podpisany kluczem debug. Przed Sklepem Play: znaleźć/utworzyć keystore, `android/key.properties`, Play App Signing.
18. **iOS** — `ios/Runner/Info.plist`: NSCameraUsageDescription, NSPhotoLibraryUsageDescription, NSMicrophoneUsageDescription; konto Apple Developer; TestFlight.
19. **Regulamin i polityka RODO** — w apce są puste miejsca zamiast danych administratora (prawnicy). Dane prawdziwych firm z publicznych źródeł w bazie — zgody albo usunięcie przed publicznym startem.
20. **Pilotaż** — 2–3 konta firm testowych obsługiwane przez zespół, żeby testerzy dostawali oferty.
21. **Wybierak kont testowych w APK dla testerów** — od 1.4.2 lista „⚡ Wybierz konto testowe” jest w buildzie z `--dart-define=DEMO_LOGIN=true` (gradle: `-Pdart-defines=<base64 "DEMO_LOGIN=true">`). Konta firm to prawdziwe firmy ze wspólnym, prostym hasłem — każdy z plikiem APK może działać jako taka firma. Przed szerszym udostępnieniem: podmienić na fikcyjne firmy demo (np. „Demo Sprzątanie”, „Demo Hydraulik”) z osobnym hasłem, a buildy do Sklepu budować bez DEMO_LOGIN.

## Techniczne

22. **Test reguł z repo** — `node demo/_seed/test_rules.js` (wymaga klucza konta serwisowego, uruchamia właściciel).
23. **Limit CPU Cloud Run w europe-central2 (20 vCPU)** — gdy będzie historia zużycia, złożyć wniosek o zwiększenie (Quotas → „Total CPU allocation… europe-central2”). Do tego czasu funkcje mają `cpu: 'gcf_gen1'` i wdrażamy paczkami po 4.
24. **Sprzątanie po migracjach** — po potwierdzeniu, że w `users` nie ma już `fcmTokens`, usunąć fragmenty oznaczone `EXPIRES` w `functions/index.js`.
25. **Pusty `test/widget_test.dart`** — usunąć albo dodać prawdziwy test.
