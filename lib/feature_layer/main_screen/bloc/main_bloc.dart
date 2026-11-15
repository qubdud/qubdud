import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/domain_models/app_user.dart';
import '../../../domain_layer/domain_models/promoVideo.dart';
import '../../../domain_layer/firebase_service.dart';
import '../../../shared/client_notes.dart';
import '../../../shared/moderation.dart';
import '../../../shared/push_service.dart';
import '../../../shared/new_counts.dart';
import '../../../shared/functions/effective_role.dart';
import '../../../shared/functions/plural.dart';
import '../../../shared/functions/show_toast.dart';
import '../../../shared/globals.dart';
import 'main_appbar_cubit.dart';

part 'main_event.dart';

part 'main_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainScreenState> {
  StreamSubscription<Uri>? _linkSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notifSub;
  StreamSubscription<int>? _chatSub;
  StreamSubscription<User?>? _authSub;
  List<Map<String, dynamic>> _notifs = [];
  bool _loggingOut = false;

  @override
  Future<void> close() {
    _linkSub?.cancel();
    _notifSub?.cancel();
    _chatSub?.cancel();
    _authSub?.cancel();
    return super.close();
  }

  /// Historia ekranów „w głąb” — „wstecz” wraca tam, skąd się przyszło,
  /// a nie zawsze na Start.
  final List<MainScreenEvent> _backStack = [];
  MainScreenEvent? _currentNav;

  void _pushNav(MainScreenEvent event) {
    if (!event.restoring && _currentNav != null) {
      _backStack.add(_currentNav!);
      if (_backStack.length > 20) _backStack.removeAt(0);
    }
    _currentNav = event;
  }

  /// Zakładka dolnego paska — historia od nowa.
  void _rootNav(MainScreenEvent event) {
    _backStack.clear();
    _currentNav = event;
  }

  MainScreenBloc({
    required MainScreenControlCubit appBarCubit,
    required ChatService appChatService,
    required FirebaseService appFirebaseService,
  }) : super(LoadingMainScreenState()) {
    // nowa sesja — nic z poprzedniego konta nie może mignąć przed wczytaniem
    state.user = null;
    state.chatCounter = 0;
    state.notifCounter = 0;
    Globals.instance.resetSession();

    // konto wylogowane poza apką (reset hasła, blokada, usunięcie)
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && !_loggingOut) add(LogoutEvent());
    });

    void recountNotifs() {
      final company = isCompanyMode(state.user);
      final n = _notifs
          .where((e) =>
              e['read'] != true &&
              FirebaseService.isNotificationForMode(e, company))
          .length;
      if (n == state.notifCounter) return;
      state.notifCounter = n;
      add(RefreshBadgesEvent());
    }

    void listenBadges(String uid) {
      _notifSub?.cancel();
      _notifSub = appFirebaseService.notificationsStream(uid).listen((list) {
        _notifs = list;
        recountNotifs();
      }, onError: addError);
      _chatSub?.cancel();
      _chatSub = appChatService.unreadTotalStream().listen((n) {
        if (n == state.chatCounter) return;
        state.chatCounter = n;
        add(RefreshBadgesEvent());
      }, onError: addError);
    }

    // link otwierający apkę przychodzi przy pierwszym nasłuchu — dopiero
    // po starcie, inaczej końcowy GoToHomeEvent nadpisałby wskazany ekran
    void listenLinks() {
      _linkSub ??= AppLinks()
          .uriLinkStream
          .listen((uri) => add(HandleDeepLinkEvent(uri)), onError: addError);
    }

    Future<void> toastUrgent(AppUser user) async {
      if (user.companyCategory == null ||
          user.companySector == null ||
          user.companyLocation == null) {
        return;
      }
      try {
        final urgent = await appFirebaseService.getUrgentNearbyCount(
          companyId: user.id,
          category: user.companyCategory!,
          sector: user.companySector!,
          myLocation: user.companyLocation!,
        );
        if (urgent > 0) {
          showToast(
              text: 'Masz $urgent ${plural(urgent, 'pilne zgłoszenie', 'pilne zgłoszenia', 'pilnych zgłoszeń')} w pobliżu!');
        }
      } catch (e, s) {
        addError(e, s);
      }
    }

    Future<void> switchMode(bool company) async {
      await setCompanyView(company);
      recountNotifs();
    }

    on<HandleDeepLinkEvent>((event, emit) async {
      final uri = event.uri;
      if (uri.scheme != 'qubdud' || uri.pathSegments.isEmpty) return;
      final id = uri.pathSegments.first;
      if (uri.host == 'firma') {
        add(GoToProfilPublicznyFirmyEvent(id));
      } else if (uri.host == 'promo') {
        try {
          final promo = await appFirebaseService.getPromoById(id);
          if (promo != null) {
            add(GoToPromoFirmyEvent(promo));
          } else {
            showToast(text: 'Ta prezentacja nie jest już dostępna.');
          }
        } catch (e, s) {
          showToast(text: 'Nie udało się otworzyć linku.');
          addError(e, s);
        }
      }
    });

    on<RefreshBadgesEvent>((event, emit) async {
      // przerysowanie paska z licznikami (stan trzymany statycznie)
      final s = state;
      emit(LoadingMainScreenState());
      emit(s);
    });

    on<ShowToastEvent>((event, emit) async {
      showToast(text: event.message);
    });

    on<UpdateMenuVisibilityEvent>((event, emit) async {
      state.menuIsVisible = event.isVisible;
    });

    on<GoBackEvent>((event, emit) async {
      if (state.user == null) {
        // np. Regulamin otwarty z menu po nieudanym starcie
        if (state is! LoadingMainScreenState) add(InitEvent());
        return;
      }
      if (_backStack.isEmpty) {
        add(GoToHomeEvent());
        return;
      }
      final prev = _backStack.removeLast();
      prev.restoring = true;
      // Start ma wrócić na tę samą zakładkę, z której użytkownik wyszedł
      if (prev is GoToHomeEvent) {
        Globals.instance.startTab = Globals.instance.lastStartTab;
      }
      add(prev);
    });

    on<GoToHomeEvent>((event, emit) async {
      _rootNav(event);
      appBarCubit.updateAppBar(
          backgroundColor: Colors.transparent,
          title: '',
          isVisible: false,
          height: 56,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoBackEvent());
          });

      emit(StartMainScreenState());
    });

    on<GoToProfilPublicznyFirmyEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Profil firmy',
          isVisible: true,
          onBackPressed: () {
            add(GoBackEvent());
          });

      emit(ProfilPublicznyFirmyMainScreenState(event.id));
    });

    on<GoToProfilPublicznyUseraEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Profil użytkownika',
          isVisible: true,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(ProfilPublicznyUseraMainScreenState(event.userId));
    });

    on<GoToPromoFirmyEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Wideo',
          isVisible: true,
          onBackPressed: () {
            add(GoBackEvent());
          });

      emit(VideoFirmyMainScreenState(event.promo,
          playlist: event.playlist, initialIndex: event.initialIndex));
    });

    on<GoToWyszukajFirmyEvent>((event, emit) async {
      _pushNav(event);
      if (!event.restoring) {
        Globals.instance.lastSearch = [];
        Globals.instance.lastSearchIndex = 0;
      }
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Wyszukaj',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoBackEvent());
          });

      emit(WyszukajFirmyMainScreenState(
        autoCategory: event.autoCategory,
        autoSector: event.autoSector,
        autoLat: event.autoLat,
        autoLng: event.autoLng,
        restore: event.restoring,
      ));
    });

    on<GoToChatEvent>((event, emit) async {
      if (event.id.isEmpty) {
        _rootNav(event);
      } else {
        _pushNav(event);
      }
      appBarCubit.updateAppBar(
          showBack: event.id.isNotEmpty,
          title: event.chatName?.isNotEmpty == true
              ? event.chatName!
              : 'Kontakty',
          isVisible: true,
          isMenuVisible: true,
          isChildTitle: false,
          child: const SizedBox.shrink(),
          height: 56,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(ChatMainScreenState(event.id));
    });

    on<GoToPowiadomieniaEvent>((event, emit) async {
      _rootNav(event);
      appBarCubit.updateAppBar(
          showBack: false,
          title: 'Powiadomienia',
          isVisible: true,
          isMenuVisible: true,
          isChildTitle: false,
          child: const SizedBox.shrink(),
          height: 56,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(PowiadomieniaMainScreenState());
    });

    on<GoToProfilFirmaEvent>((event, emit) async {
      _rootNav(event);
      appBarCubit.updateAppBar(
          showBack: false,
          title: 'Profil',
          isVisible: true,
          isMenuVisible: true,
          isChildTitle: false,
          child: const SizedBox.shrink(),
          height: 56,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(ProfilFirmaMainScreenState());
    });

    on<GoToShowRequestEvent>((event, emit) async {
      if (event.request != null) Globals.instance.selectedRequest = event.request;
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Zgłoszenie',
          isVisible: true,
          height: 56,
          child: SizedBox(height: 1),
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(ShowRequestMainScreenState());
    });

    on<GoToDodajEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: false,
          title: 'Dodaj',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(DodajMainScreenState());
    });

    on<GoToDodajReviewEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Dodaj recenzje',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(DodajReviewMainScreenState());
    });

    on<GoToRulesEvent>((event, emit) async {
      _pushNav(event);
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Regulamin',
          isVisible: true,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoBackEvent());
          });
      emit(RulesMainScreenState());
    });

    on<SwitchModeEvent>((event, emit) async {
      await switchMode(event.company);
      final user = state.user;
      if (user != null && isCompanyMode(user)) toastUrgent(user);
      add(GoToHomeEvent());
    });

    on<OpenNotificationEvent>((event, emit) async {
      if (event.notifId.isNotEmpty && !event.read) {
        appFirebaseService
            .markNotificationRead(event.notifId)
            .catchError((Object e, StackTrace s) => addError(e, s));
      }

      // powiadomienie dla drugiego trybu konta firmowego → przełącz tryb
      final user = state.user;
      if (user?.firma == true &&
          (event.audience == 'company' || event.audience == 'user')) {
        final company = event.audience == 'company';
        if (company != Globals.instance.companyView) await switchMode(company);
      }

      switch (event.type) {
        case 'chat':
          add(GoToChatEvent(event.senderId, chatName: event.senderName));
          return;
        case 'contact_request': // firma: Kontakty → Aktywność (numer i „skontaktowałem się”)
          Globals.instance.contactsTab = 0;
          add(GoToChatEvent(''));
          return;
        case 'review':
          if (event.companyId.isNotEmpty) {
            add(GoToProfilPublicznyFirmyEvent(event.companyId));
          } else {
            add(GoToHomeEvent());
          }
          return;
        case 'offer': // klient: oferty przyjmuje się na karcie zgłoszenia
        case 'request_reopened':
        case 'request_expired':
          Globals.instance.startTab = 3;
          add(GoToHomeEvent());
          return;
      }

      // rezerwacje: firma → Kalendarz, klient → Rezerwacje
      if (event.type.startsWith('booking')) {
        Globals.instance.startTab = 1;
        add(GoToHomeEvent());
        return;
      }

      if (event.requestId.isNotEmpty) {
        Request? request;
        try {
          request = await appFirebaseService.getRequestById(event.requestId);
        } catch (e, s) {
          addError(e, s);
        }
        if (request != null) {
          Globals.instance.selectedRequest = request;
          add(GoToShowRequestEvent());
          return;
        }
        // zgłoszenia już nie ma — lista zgłoszeń na Starcie
        Globals.instance.startTab = isCompanyMode(state.user) ? 0 : 3;
      }
      add(GoToHomeEvent());
    });

    on<LogoutEvent>((event, emit) async {
      if (_loggingOut) return;
      _loggingOut = true;
      emit(LoadingMainScreenState());
      await _notifSub?.cancel();
      await _chatSub?.cancel();
      await PushService.unregister(appFirebaseService);
      // online=false i anulowanie onDisconnect, póki reguły RTDB wpuszczają ten uid
      await appChatService.stopPresence();
      await FirebaseAuth.instance.signOut();
      Globals.instance.anonim = false;
      // tryb widoku jest per sesja — nowe konto zaczyna jako Firma
      await setCompanyView(true);
      ClientNotes.clear();
      NewCounts.clear();
      BlockedUsers.clear();
      emit(LogoutMainScreenState(toRegister: event.toRegister));
    });

    on<DeleteAccountEvent>((event, emit) async {
      emit(LoadingMainScreenState());
      await appChatService.stopPresence();
      try {
        await appFirebaseService.deleteAccount();
      } catch (e, s) {
        appChatService.startPresence();
        showToast(text: 'Nie udało się usunąć konta. Sprawdź połączenie i spróbuj ponownie.');
        add(GoToHomeEvent());
        addError(e, s);
        return;
      }
      showToast(text: 'Konto zostało usunięte.');
      add(LogoutEvent());
    });

    on<InitEvent>((event, emit) async {
      state.menuIsVisible = false;
      emit(LoadingMainScreenState());
      try {
        await loadCompanyView();

        final currentUser = FirebaseAuth.instance.currentUser;

        // Użytkownik anonimowy lub brak sesji → tryb przeglądania
        if (currentUser == null || currentUser.isAnonymous || Globals.instance.anonim == true) {
          Globals.instance.anonim = true;
          state.user = AppUser(id: '');
          // anonim startuje na Odkrywaj (siatka prezentacji + szukaj)
          add(GoToHomeEvent());
          listenLinks();
          return;
        }

        final (doc, contact) = await (
          FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
          appFirebaseService.privateContact(currentUser.uid),
        ).wait;
        if (!doc.exists) {
          showToast(
              text: 'Nie znaleziono profilu tego konta. Zaloguj się ponownie albo załóż nowe konto.');
          add(LogoutEvent());
          return;
        }
        final userFB = AppUser.fromDoc(doc, contact: contact);
        if (userFB.firma == true) {
          await ClientNotes.load(appFirebaseService, userFB.id);
        } else {
          ClientNotes.clear();
        }
        await BlockedUsers.load(appFirebaseService, userFB.id);
        state.user = userFB;
        appChatService.startPresence();
        listenBadges(userFB.id);
        add(GoToHomeEvent());
        listenLinks();

        // push: token na konto + ten sam router co dzwonek
        PushService.register(userFB.id, appFirebaseService,
            (data) => add(OpenNotificationEvent.fromPush(data)));

        // Firma (w trybie firmowym): powiadomienie o pilnych zgłoszeniach
        if (isCompanyMode(userFB)) await toastUrgent(userFB);
      } catch (e, s) {
        emit(ErrorMainScreenState(
            'Nie udało się wczytać konta. Sprawdź połączenie i spróbuj ponownie.'));
        addError(e, s);
      }
    });

    add(InitEvent());
  }
}
