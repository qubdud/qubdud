import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/widgets/w_smallest_label.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/notification.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../../../shared/widgets/w_dropdown.dart';
import '../../../bloc/main_appbar_cubit.dart';
import '../../news/widgets/news_card.dart';
import '../bloc/notifications_page_bloc.dart';
import '../widgets/notification_card.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationPageBloc(repository: context.read<AppRepository>(), mainBloc: context.read<MainScreenBloc>()),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> {
  TextEditingController controller = TextEditingController();
  List<NotificationModel> filter = [];
  List<NotificationModel> filterOld = [];
  bool openFilter = false;
  bool blockUpdate = false;

  Widget build(BuildContext context) {
    context.read<MainScreenControlCubit>().updateAppBar(height: 56, child: null);
    return BlocConsumer<NotificationPageBloc, NotificationPageState>(
      listener: (context, state) {
        if (state is NotificationPageMainState) {
          filter = state.notifications;
          filterOld = state.notificationsOld;
        }
      },
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildWidgetBasedOnState(state, context),
        );
      },
    );
  }

  Widget _buildWidgetBasedOnState(NotificationPageState state, BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is NotificationPageLoadingState) {
      return const Loading(key: ValueKey('Loading'));
    } else if (state is! NotificationPageInitialState && state is! NotificationPageLoadingState) {
      searchBar() {
        return SizedBox(
          width: maxColumnSize,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                WAnimatedDropdown(
                  label: '',
                  items: ["Invitation Received", "Join Request", "Challenge", "Duel", "Post Commented", "Post Liked", "All"],
                  hintText: 'Filter by category',
                  controller: controller,
                  onDropdownVisibleChanged: (a) {
                    setState(() {
                      openFilter = a;
                    });
                  },

                  onItemSelected: (selectedCategory) {


                    if (selectedCategory == "All" || selectedCategory.isEmpty) {
                      setState(() {
                        filter = state.notifications;
                        filterOld = state.notificationsOld;
                        controller.clear();
                      });
                      return;
                    }

                    // Znajdź pasujący klucz w notificationFilters
                    final fil = notificationFilters.firstWhere(
                      (element) => element["label"] == selectedCategory,
                      orElse: () => {"key": ""}, // Domyślnie pusta mapa, jeśli nie znaleziono
                    );

                    String categoryKey = fil["key"] ?? "";

                    // Filtrowanie powiadomień
                    setState(() {

                      filter = state.notifications.where((notification) {
                        return notification.category == categoryKey;
                      }).toList();

                      filterOld = state.notificationsOld.where((notification) {
                        return notification.category == categoryKey;
                      }).toList();

                    });
                  },
                ),
              ],
            ),
          ),
        );
      }

      if(!blockUpdate)
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          key: 'NotificationFilter',
          backgroundColor: cLighterBrown,
          title: 'Notifications',
          height: openFilter ? 374 : 174,
          isVisible: true,
          isMenuVisible: true,
          child: searchBar());

      return SizedBox(
        width: maxColumnSize,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (isWideScreen) const SizedBox(height: 50),
              if (isWideScreen) WLabel(text: 'Notifications'),
              if (isWideScreen) searchBar(),
              const SizedBox(height: 16),
              if (filter.isNotEmpty) WSmallestLabel(text: 'New'),
              if (filter.isNotEmpty) Column(
                children: filter.map((newsItem) {
                  return GestureDetector(
                    onTap: (){
                      if(newsItem.route=='post'){
                        if(newsItem.postId.isNotEmpty){
                          context.read<NotificationPageBloc>().add(GoToLoadingNotificationPageEvent());
                          context.read<MainScreenBloc>().add(GoToPostEvent(newsItem.postId));
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0), // Margines góra-dół
                      child: NotificationCard(
                        date: newsItem.readAt,
                        title: newsItem.title,
                        news: newsItem.body,
                        isNew: true,
                        avatar: newsItem.avatar.countryCode,
                        createdAt: newsItem.createdAtFormatted,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (filterOld.isNotEmpty)SizedBox(height: 16),
              if (filterOld.isNotEmpty)WSmallestLabel(text: 'Old'),
              if (filterOld.isNotEmpty)Column(
                children: filterOld.map((newsItem) {
                  return GestureDetector(
                    onTap: (){
                      if(newsItem.route=='post'){
                        if(newsItem.postId.isNotEmpty){
                          setState(() {
                            blockUpdate = true;
                          });
                          context.read<NotificationPageBloc>().add(GoToLoadingNotificationPageEvent());
                          context.read<MainScreenBloc>().add(GoToPostEvent(newsItem.postId));
                        }
                      }
                      if(newsItem.route=='duels'){
                        context.read<NotificationPageBloc>().add(GoToLoadingNotificationPageEvent());
                        context.read<MainScreenBloc>().add(GoToDuelsEvent());
                      }
                      if(newsItem.route=='challenge'){
                        context.read<NotificationPageBloc>().add(GoToLoadingNotificationPageEvent());
                        context.read<MainScreenBloc>().add(GoToChallengesEvent());
                      }

                    },



                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0), // Margines góra-dół
                      child: NotificationCard(
                        date: newsItem.readAt,
                        title: newsItem.title,
                        news: newsItem.body,
                        isNew: false,
                        avatar: newsItem.avatar.countryCode,
                        createdAt: newsItem.createdAtFormatted,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (filter.isEmpty && filterOld.isEmpty) WLabel(text: 'No notifications available.'),

              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}

final List<Map<String, String>> notificationFilters = [
  {"key": "camper_invitation_received", "label": "Invitation Received"},
  {"key": "camper_join_request_received", "label": "Join Request"},
  {"key": "challenge", "label": "Challenge"},
  {"key": "duel", "label": "Duel"},
  {"key": "post_commented", "label": "Post Commented"},
  {"key": "post_liked", "label": "Post Liked"},
];
