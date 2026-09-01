import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/domain_models/app_user.dart';
import '../../../domain_layer/domain_models/notification_counters.dart';
import '../../../domain_layer/domain_models/promoVideo.dart';
import '../../../domain_layer/domain_models/stage.dart';
import '../../../domain_layer/repository.dart';
import '../../../shared/functions/show_toast.dart';
import '../../../shared/functions/show_toast_push.dart';
import '../../../shared/globals.dart';
import 'main_appbar_cubit.dart';

part 'main_event.dart';

part 'main_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainScreenState> {
  MainScreenBloc({
    required AppRepository repository,
    required MainScreenControlCubit appBarCubit,
    required ChatService appChatService,
  }) : super(LoadingMainScreenState()) {
    on<ShowToastEvent>((event, emit) async {

      showToast(text: event.message.isEmpty ? 'Team required! Join a team to unlock this menu.' : event.message);
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
          backgroundColor: Colors.transparent,
          title: 'Profil użytkownika',
          isVisible: true,
          onBackPressed: () { add(GoToHomeEvent()); });
      emit(ProfilPublicznyUseraMainScreenState(event.userId));
    });

    on<GoToPromoFirmyEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          backgroundColor: Colors.transparent,
          title: 'Wideo',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(VideoFirmyMainScreenState(event.promo));
    });


    on<GoToWyszukajFirmyEvent>((event, emit) async {
      appBarCubit.updateAppBar(
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

    on<GoToFindTeamEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });

      emit(FindTeamMainScreenState());
    });

    on<GoToNewsEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'News',
          isVisible: true,
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(NewsMainScreenState());
    });

    on<GoToNotificationEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(NotificationMainScreenState());
    });

    on<GoToStatsEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'STATYSTYKI',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(StatsMainScreenState());
    });

    on<GoToChatEvent>((event, emit) async {
      if (Globals.instance.anonim) return;
      appBarCubit.updateAppBar(
          title: 'Kontakty',
          isVisible: true,
          isMenuVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ChatMainScreenState(event.id));
    });

    on<GoToProfilFirmaEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Profil',
          isVisible: true,
          isMenuVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ProfilFirmaMainScreenState());
    });



    on<GoToShowRequestEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Zgłoszenie',
          isVisible: true,
          height: 56,
          child: SizedBox(height: 1,),
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ShowRequestMainScreenState());
    });

    on<GoToPostEvent>((event, emit) async {
      appBarCubit.setIsMenuVisible(false);
      appBarCubit.updateAppBar(
          backgroundColor: Colors.transparent,
          title: 'Post',
          child: SizedBox(),
          height: 56,
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });




      emit(PostMainScreenState(event.id));
    });

    on<GoToInviteTeamEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Invite passengers',
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(InviteTeamMainScreenState());
    });

    on<GoToContactEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Contact',
          backgroundColor: Colors.transparent,
          isVisible: true,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ContactMainScreenState());
    });

    on<GoToAddPostEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Add post',
          backgroundColor: Colors.transparent,
          isVisible: true,
          child: SizedBox.shrink(),
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(AddPostMainScreenState(event.id));
    });

    on<GoToAccountEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Your Account'.toUpperCase(),
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(AccountMainScreenState());
    });

    on<GoToRanksEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Ranking'.toUpperCase(),
          isVisible: true,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(RanksMainScreenState());
    });


    on<GoToChallengesEvent>((event, emit) async {
    });

    on<GoToDodajEvent>((event, emit) async {
      if (Globals.instance.anonim) return;
      appBarCubit.updateAppBar(
          title: 'Dodaj',
          isVisible: true,
          height: 56,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(ChallengesMainScreenState());
    });

    on<GoToDodajReviewEvent>((event, emit) async {
      if (Globals.instance.anonim) return;
      appBarCubit.updateAppBar(
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




    on<GoToWallEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Wall',
          height: 56,
          isVisible: true,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(WallMainScreenState());
    });

    on<GoToDuelsEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Duels',
          height: 56,
          isVisible: true,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToHomeEvent());
          });
      emit(DuelsMainScreenState());
    });

    on<GoToDuelsSummaryEvent>((event, emit) async {
      appBarCubit.updateAppBar(
          title: 'Duel Summary',
          height: 56,
          isVisible: true,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToDuelsEvent());
          });
      emit(DuelsSummaryMainScreenState());
    });

    on<GoToDuelStartEvent>((event, emit) async {

      appBarCubit.setIsMenuVisible(false);
      appBarCubit.updateAppBar(
          title: 'Duel',
          height: 56,
          isVisible: true,
          child: SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          onBackPressed: () {
            add(GoToDuelsEvent());
          });
      emit(DuelsStartMainScreenState());
    });

    on<LogoutEvent>((event, emit) async {
      await FirebaseAuth.instance.signOut();
      Globals.instance.anonim = false;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', false);
      emit(LogoutMainScreenState());
    });

    on<UpdateUserDataMainScreenEvent>((event, emit) async {


    });



    on<InitEvent>((event, emit) async {
      state.menuIsVisible = false;
      emit(LoadingMainScreenState());




      String? tokenPus = '';
      if (!kIsWeb) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (Platform.isIOS) {
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          NotificationSettings settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          print("iOS Permission: ${settings.authorizationStatus}");

          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

          if (apnsToken != null) {
            tokenPus = await FirebaseMessaging.instance.getToken() ?? '';
          }
        } else {
          tokenPus = await FirebaseMessaging.instance.getToken() ?? '';
        }

        if (tokenPus.isNotEmpty) {
          print(tokenPus);

          final String tok = prefs.getString('tokenPush') ?? '';
          if (tok.isNotEmpty) {
            if (tok != tokenPus) {
              //           var res = await repository.storePushToken(tokenPus);
              //           res.when((success) => prefs.setString('tokenPush', tokenPus!), (error) => null);
            }
          } else {
            //       var res = await repository.storePushToken(tokenPus);
            //       res.when((success) => prefs.setString('tokenPush', tokenPus!), (error) => null);
          }
        }

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (state is ChatMainScreenState) {
            //       if ((message.notification?.title ?? '').toLowerCase().contains('chat')) {
            //       } else {
            //         showToastPush(message: message.notification?.body ?? 'New notification', tittle: message.notification?.title ?? '');
            //       }
            //     } else {
            //       showToastPush(message: message.notification?.body ?? 'New notification', tittle: message.notification?.title ?? '');
          }
        });
      }




      final currentUser = FirebaseAuth.instance.currentUser;

      // Użytkownik anonimowy lub brak sesji → tryb przeglądania
      if (currentUser == null || currentUser.isAnonymous || Globals.instance.anonim == true) {
        Globals.instance.anonim = true;
        state.user = AppUser(id: '');
        add(GoToWyszukajFirmyEvent());
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
      appChatService.updateUserOnlineStatus();
      state.chatCounter = await appChatService.getTotalUnreadCount();
      state.user = userFB;
      add(GoToHomeEvent());


    });

    add(InitEvent());
  }
}