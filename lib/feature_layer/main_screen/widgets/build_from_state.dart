import 'package:flutter/material.dart';
import 'package:qb/feature_layer/main_screen/pages/profil_publiczny/view/profil_publiczny_page.dart';
import '../pages/profil_user/view/profil_user_page.dart';
import 'package:qb/feature_layer/main_screen/pages/show_request/view/show_request_page.dart';

import '../../../shared/globals.dart';
import '../../../shared/widgets/anonim_gate.dart';
import '../../../shared/widgets/loading.dart';
import '../bloc/main_bloc.dart';
import '../pages/chat/view/chat_page.dart';
import '../pages/dodaj/view/dodaj_page.dart';
import '../pages/dodaj_review/view/dodaj_rev_page.dart';
import '../pages/profil_my/view/profil_my_page.dart';
import '../pages/rules/view/rules_page.dart';
import '../pages/start/view/start_page.dart';
import '../pages/wideo/single_video.dart';
import '../pages/wyszukaj/view/wyszukaj_page.dart';

Widget buildWidgetBasedOnState(MainScreenState state) {
  // Anonim: tylko szukanie i oglądanie. Wszystko, co pokazuje dane firmy
  // lub pozwala na kontakt, jest za bramką logowania.
  if (Globals.instance.anonim) {
    if (state is ProfilPublicznyFirmyMainScreenState) {
      return const AnonimGateView(
          key: ValueKey('GateProfilFirmy'),
          icon: Icons.storefront_outlined,
          what: 'Profil firmy, jej dane i kontakt zobaczysz po zalogowaniu.');
    }
    if (state is ProfilPublicznyUseraMainScreenState ||
        state is ShowRequestMainScreenState) {
      return const AnonimGateView(
          key: ValueKey('GateProfilUsera'),
          icon: Icons.person_outline,
          what: 'Profile i zgłoszenia użytkowników są widoczne po zalogowaniu.');
    }
    if (state is ChatMainScreenState) {
      return const AnonimGateView(
          key: ValueKey('GateChat'),
          icon: Icons.chat_bubble_outline,
          what: 'Rozmowy, kontakty i rezerwacje są dostępne po zalogowaniu.');
    }
    if (state is DodajMainScreenState || state is DodajReviewMainScreenState) {
      return const AnonimGateView(
          key: ValueKey('GateDodaj'),
          icon: Icons.add_box_outlined,
          what: 'Aby dodać zgłoszenie lub recenzję, zaloguj się.');
    }
    if (state is ProfilFirmaMainScreenState) {
      return const AnonimGateView(
          key: ValueKey('GateProfil'),
          icon: Icons.account_circle_outlined,
          what: 'Zarejestruj się lub zaloguj, aby korzystać z pełnych możliwości.');
    }
  }

  if (state is StartMainScreenState) {
    return StartPage(key: ValueKey('StartPage'));
  } else if (state is VideoFirmyMainScreenState) {
    return SingleVideoPage(
        promo: state.promo,
        playlist: state.playlist,
        initialIndex: state.initialIndex,
        key: ValueKey('SingleVideoPage'));
  } else if (state is RulesMainScreenState) {
    return RulesPage(key: ValueKey('RulesPage'));
  } else if (state is ProfilFirmaMainScreenState) {
    return MyProfilPage(key: ValueKey('ProfilFirmaPage'));
  } else if (state is ProfilPublicznyFirmyMainScreenState) {
    return ProfilPubliczyPage(userId: state.id, key: ValueKey('ProfPub'));
  } else if (state is ChatMainScreenState) {
    return ChatPage(key: ValueKey('ChatPage'), id: state.id);
  } else if (state is WyszukajFirmyMainScreenState) {
    return WyszukajPage(key: ValueKey('WyszukajPage'));
  } else if (state is DodajMainScreenState) {
    return DodajPage(key: ValueKey('DodajFilm'));
  } else if (state is DodajReviewMainScreenState) {
    return DodajReviewPage(key: ValueKey('DodajRevFilm'));
  } else if (state is ShowRequestMainScreenState) {
    return ShowRequestPage(key: ValueKey('ShowRequestPage'));
  } else if (state is ProfilPublicznyUseraMainScreenState) {
    return ProfilPublicznyUseraPage(userId: state.userId, key: ValueKey('ProfilUsera'));
  } else {
    return Loading(noText: true, key: ValueKey('Loading'));
  }
}
