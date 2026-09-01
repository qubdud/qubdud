# Nowa struktura projektu

## Stack
- Flutter (mobile + web)
- Firebase Auth + Firestore + Storage + Realtime Database
- BLoC / Cubit (state management)

## Role użytkowników
| Rola | Opis |
|------|------|
| **User** | Dodaje zgłoszenia, przegląda firmy, ogląda promo, wystawia recenzje, pisze na czacie |
| **Firma** | Wszystko co User + zarządza filmami promo + widzi zgłoszenia pasujące do jej kategorii |

---

## Struktura katalogów

```
lib/
├── app/
│   └── app.dart                  ✅ Router + BLoC providers
│
├── core/
│   ├── firebase_service.dart     ✅ Auth, Firestore, Storage
│   └── chat_service.dart         ✅ Realtime Database (czat)
│
├── domain/
│   └── models/
│       ├── app_user.dart         ✅ User + Firma (isCompany)
│       ├── promo_video.dart      ✅ Film promocyjny firmy
│       ├── service_request.dart  ✅ Zgłoszenie awarii
│       ├── review.dart           ✅ Ocena firmy (1-5 + opis)
│       └── chat_message.dart     ✅ Wiadomość czatu + ChatOverview
│
├── features/
│   ├── auth/                     ✅ BLoC gotowy
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   └── view/
│   │       ├── login_page.dart           🔲 TODO
│   │       ├── register_page.dart        🔲 TODO (z wyborem: user/firma)
│   │       └── forgot_password_page.dart 🔲 TODO
│   │
│   ├── home/                     🔲 TODO
│   │   └── view/
│   │       ├── user_home_page.dart    (mapa/lista firm + zgłoszenia)
│   │       └── company_home_page.dart (dashboard + lista zgłoszeń w pobliżu)
│   │
│   ├── profile/                  ✅ BLoC gotowy, 4 widoki szkielet
│   │   ├── bloc/
│   │   └── view/
│   │       ├── my_company_profile_page.dart     ✅ szkielet
│   │       ├── public_company_profile_page.dart ✅ szkielet
│   │       ├── my_user_profile_page.dart        ✅ szkielet
│   │       └── public_user_profile_page.dart    ✅ szkielet
│   │
│   ├── promo/                    🔲 TODO
│   │   └── view/
│   │       ├── promo_list_page.dart    (lista filmów — dla usera/browsing)
│   │       ├── promo_detail_page.dart  (odtwarzacz)
│   │       └── add_promo_page.dart     (tylko firma: upload video)
│   │
│   ├── requests/                 🔲 TODO
│   │   └── view/
│   │       ├── my_requests_page.dart   (moje zgłoszenia — user)
│   │       ├── add_request_page.dart   (dodaj zgłoszenie — user)
│   │       ├── request_detail_page.dart
│   │       └── nearby_requests_page.dart (widok firmy — zgłoszenia w pobliżu)
│   │
│   ├── search/                   🔲 TODO
│   │   └── view/
│   │       └── search_page.dart  (wyszukaj firmę po nazwie/kategorii/lokalizacji)
│   │
│   ├── reviews/                  🔲 TODO
│   │   └── view/
│   │       └── add_review_page.dart (user wystawia ocenę firmie)
│   │
│   ├── chat/                     🔲 TODO (przepiąć na ChatService)
│   │   └── view/
│   │       ├── chat_list_page.dart     (lista konwersacji)
│   │       └── messaging_page.dart     (okno rozmowy)
│   │
│   └── notifications/            🔲 TODO
│       └── view/
│           └── notifications_page.dart
│
└── shared/
    ├── constants/
    │   └── app_constants.dart    ✅ kategorie, sektory
    ├── widgets/                  🔲 TODO (przepisać z oryginału)
    │   ├── w_button.dart
    │   ├── w_input_field.dart
    │   └── loading.dart
    └── functions/
        └── show_toast.dart       🔲 TODO
```

---

## Firestore — kolekcje

| Kolekcja | Opis |
|----------|------|
| `users/{uid}` | Dane użytkownika/firmy (`isCompany: true/false`) |
| `users/{uid}/favoritePromos` | Ulubione promo usera |
| `users/{uid}/skippedRequests` | Pominięte zgłoszenia (firma) |
| `promos/{id}` | Filmy promocyjne firm |
| `requests/{id}` | Zgłoszenia awarii/usług |
| `reviews/{id}` | Recenzje firm |

## Realtime Database — struktura czatu

```
messages/{uid_A}/{uid_B}/{msgId}    → wiadomości 1:1
unread_counts/{uid}/{from_uid}      → licznik nieprzeczytanych
users/{uid}/online                  → status online
```

---

## Co zostało z oryginalnego projektu

| Plik | Status |
|------|--------|
| `firebase_service.dart` | ✅ Przepisany (rozszerzony) |
| `chat_service.dart` | ✅ Skopiowany bez zmian |
| `firebase_options.dart` | ⚠️ Skopiuj ręcznie z oryginału |
| Widoki czatu | 🔲 Przepiąć na nowe BLoC |
| `shared/widgets/` | 🔲 Przepiąć komponenty UI |

## Co wyleciało

- Cały REST API (Dio, mocki)
- Rankingi, challenges, duel, vote, wall, news (stare)
- Team/vehicle system
- E-learnings, business tasks, stickers
- Sales / scratch card
- Stare 3 duplikaty profilu
