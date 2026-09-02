import 'dart:async';
import 'dart:io';
import 'package:app_links/app_links.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/domain_models/app_user.dart';
import '../../../domain_layer/domain_models/promoVideo.dart';
import '../../../domain_layer/firebase_service.dart';
import '../../../shared/client_notes.dart';
import '../../../shared/push_service.dart';
import '../../../shared/functions/effective_role.dart';
import '../../../shared/functions/show_toast.dart';
import '../../../shared/globals.dart';
import 'main_appbar_cubit.dart';

part 'main_event.dart';

part 'main_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainScreenState> {
  StreamSubscription<Uri>? _linkSub;

  @override
  Future<void> close() {
    _linkSub?.cancel();
    return super.close();
  }

  MainScreenBloc({
    required MainScreenControlCubit appBarCubit,
    required ChatService appChatService,
    required FirebaseService appFirebaseService,
  }) : super(LoadingMainScreenState()) {
    on<HandleDeepLinkEvent>((event, emit) async {
      final uri = event.uri;
      if (uri.scheme != 'qubdud' || uri.pathSegments.isEmpty) return;
      final id = uri.pathSegments.first;
      if (uri.host == 'firma') {
        add(GoToProfilPublicznyFirmyEvent(id));
      } else if (uri.host == 'promo') {
        final promo = await appFirebaseService.getPromoById(id);
        if (promo != null) add(GoToPromoFirmyEvent(promo));
      }
    });

    _linkSub = AppLinks().uriLinkStream.listen((uri) {
      add(HandleDeepLinkEvent(uri));
    });
    on<ShowToastEvent>((event, emit) async {
      showToast(text: event.message);
    });

    on<UpdateMenuVisibilityEvent>((event, emit) async {
      state.menuIsVisible = event.isVisible;
    });

    on<GoToHomeEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          backgroundColor: Colors.transparent,
          title: '',
          isVisible: false,
          height: 56,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(StartMainScreenState());
    });

    on<GoToProfilPublicznyFirmyEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Profil firmy',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(ProfilPublicznyFirmyMainScreenState(event.id));
    });

    on<GoToProfilPublicznyUseraEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Profil użytkownika',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ProfilPublicznyUseraMainScreenState(event.userId));
    });

    on<GoToPromoFirmyEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Wideo',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(VideoFirmyMainScreenState(event.promo,
          playlist: event.playlist, initialIndex: event.initialIndex));
    });

    on<GoToWyszukajFirmyEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          backgroundColor: Colors.transparent,
          title: 'Wyszukaj',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(WyszukajFirmyMainScreenState(
        autoCategory: event.autoCategory,
        autoSector: event.autoSector,
        autoLat: event.autoLat,
        autoLng: event.autoLng,
      ));
    });

    on<GoToChatEvent>((event, emit) async {
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
            add(GoToHomeEvent());
          });
      emit(ChatMainScreenState(event.id));
    });

    on<GoToProfilFirmaEvent>((event, emit) async {
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
            add(GoToHomeEvent());
          });
      emit(ProfilFirmaMainScreenState());
    });

    on<GoToShowRequestEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Zgłoszenie',
          isVisible: true,
          height: 56,
          child: SizedBox(height: 1),
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ShowRequestMainScreenState());
    });

    on<GoToDodajEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: false,
          title: 'Dodaj',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(DodajMainScreenState());
    });

    on<GoToDodajReviewEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Dodaj recenzje',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(DodajReviewMainScreenState());
    });

    on<GoToRulesEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          showBack: true,
          title: 'Regulamin',
          isVisible: true,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(RulesMainScreenState());
    });

    on<LogoutEvent>((event, emit) async {
      await PushService.unregister(appFirebaseService);
      await FirebaseAuth.instance.signOut();
      Globals.instance.anonim = false;
      // tryb widoku jest per sesja — nowe konto zaczyna jako Firma
      await setCompanyView(true);
      ClientNotes.clear();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', false);
      emit(LogoutMainScreenState());
    });

    on<InitEvent>((event, emit) async {
      state.menuIsVisible = false;
      emit(LoadingMainScreenState());

      await loadCompanyView();

      if (!kIsWeb) {
        if (Platform.isIOS) {
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      }

      final currentUser = FirebaseAuth.instance.currentUser;

      // Użytkownik anonimowy lub brak sesji → tryb przeglądania
      if (currentUser == null || currentUser.isAnonymous || Globals.instance.anonim == true) {
        Globals.instance.anonim = true;
        state.user = AppUser(id: '');
        // anonim startuje na Odkrywaj (siatka prezentacji + szukaj)
        add(GoToHomeEvent());
        return;
      }

      // Zalogowany normalny użytkownik
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!doc.exists) {
        emit(LogoutMainScreenState());
        return;
      }
      final userFB = AppUser.fromDoc(doc);
      if (userFB.firma == true) {
        await ClientNotes.load(appFirebaseService, userFB.id);
      } else {
        ClientNotes.clear();
      }
      appChatService.updateUserOnlineStatus();
      state.chatCounter = await appChatService.getTotalUnreadCount();
      state.user = userFB;
      add(GoToHomeEvent());

      // push: token na konto + co robić po kliknięciu w powiadomienie
      PushService.register(userFB.id, appFirebaseService, (data) {
        switch (data['type']) {
          case 'offer':          // nowa oferta → Start → Zgłoszenia (user)
            Globals.instance.startTab = 3;
            add(GoToHomeEvent());
            break;
          case 'booking':        // nowa rezerwacja → Start → Kalendarz (firma)
          case 'booking_decision': // decyzja firmy → Start → Rezerwacje (user)
            Globals.instance.startTab = 1;
            add(GoToHomeEvent());
            break;
          case 'review':         // prośba o recenzję → profil firmy
            final id = data['companyId'] as String?;
            if (id != null && id.isNotEmpty) {
              add(GoToProfilPublicznyFirmyEvent(id));
            }
            break;
          default:               // pilne zgłoszenie, decyzja klienta → Start
            add(GoToHomeEvent());
        }
      });

      // Firma (w trybie firmowym): powiadomienie o pilnych zgłoszeniach
      if (userFB.firma == true &&
          Globals.instance.companyView &&
          userFB.companyCategory != null &&
          userFB.companyLocation != null) {
        try {
          final urgent = await appFirebaseService.getUrgentNearbyCount(
            companyId: userFB.id,
            category: userFB.companyCategory!,
            myLocation: userFB.companyLocation!,
          );
          if (urgent > 0) {
            showToast(
                text: urgent == 1
                    ? 'Masz 1 pilne zgłoszenie w pobliżu!'
                    : 'Masz $urgent pilne zgłoszenia w pobliżu!');
          }
        } catch (_) {}
      }
    });

    add(InitEvent());
  }
}
