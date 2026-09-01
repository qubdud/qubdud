import 'package:flutter/material.dart';
import 'package:qb/feature_layer/main_screen/pages/profil_publiczny/view/profil_publiczny_page.dart';
import '../pages/profil_user/view/profil_user_page.dart';
import '../pages/profil_user/view/profil_user_page.dart';
import 'package:qb/feature_layer/main_screen/pages/show_promo/view/show_promo_page.dart';
import 'package:qb/feature_layer/main_screen/pages/show_request/view/show_request_page.dart';

import '../../../shared/widgets/loading.dart';
import '../bloc/main_bloc.dart';
import '../pages/account/view/account_page.dart';
import '../pages/chat/view/chat_page.dart';
import '../pages/dodaj/view/dodaj_page.dart';
import '../pages/dodaj_review/view/dodaj_rev_page.dart';
import '../pages/find_team/view/find_team_page.dart';
import '../pages/invite_team/view/invite_team_page.dart';
import '../pages/news/view/news_page.dart';
import '../pages/notifications/view/notifications_page.dart';
import '../pages/profil_my/view/profil_my_page.dart';
import '../pages/rules/view/rules_page.dart';
import '../pages/start/view/start_page.dart';
import '../pages/wideo/single_video.dart';
import '../pages/wyszukaj/view/wyszukaj_page.dart';

Widget buildWidgetBasedOnState(MainScreenState state) {
  if (state is StartMainScreenState) {
    return StartPage(key: ValueKey('StartPage'));


  }

  else if (state is VideoFirmyMainScreenState) {
    return SingleVideoPage(promo:state.promo, key: ValueKey('RankPage'));



  } else if (state is NewsMainScreenState) {
    return NewsPage();
  } else if (state is CardsMainScreenState) {
    return SizedBox();
  } else if (state is RulesMainScreenState) {
    return RulesPage(key: ValueKey('RulesPage'));
  } else if (state is ProfilFirmaMainScreenState) {
    return MyProfilPage(key: ValueKey('ProfilFirmaPage'));
  } else if (state is FindTeamMainScreenState) {
    return FindTeamPage(key: ValueKey('FindTeamPage'));
  } else if (state is ProfilPublicznyFirmyMainScreenState) {
    return ProfilPubliczyPage(userId: state.id, key:ValueKey('ProfPub'));
  } else if (state is ChatMainScreenState) {
    return ChatPage(key: ValueKey('ChattPage'), id: state.id );
  } else if (state is WyszukajFirmyMainScreenState) {
    return WyszukajPage(key: ValueKey('WyszukajPage'));
  } else if (state is InviteTeamMainScreenState) {
    return InviteTeamPage(key: ValueKey('InviteTeamPage'));



  } else if (state is NotificationMainScreenState) {
    return NotificationPage(key: ValueKey('NotificationPage'));
  } else if (state is ChallengesMainScreenState) {
    return DodajPage(key: ValueKey('DodajFilm'));
  }


  else if (state is DodajReviewMainScreenState) {
    return DodajReviewPage(key: ValueKey('DodajRevFilm'));
  }







  else if (state is ShowRequestMainScreenState) {
    return ShowRequestPage(key: ValueKey('DuelsPage'));
  }

  else if (state is ShowPromoMainScreenState) {
    return ShowPromoPage(key: ValueKey('DuelsStartPage'));



} else if (state is ProfilPublicznyUseraMainScreenState) {
return ProfilPublicznyUseraPage(userId: state.userId, key: ValueKey('ProfilUsera'));
} else {
return Loading(noText: true, key: ValueKey('Loading'));
}
}