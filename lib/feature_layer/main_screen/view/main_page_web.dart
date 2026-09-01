import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/repository.dart';
import '../../core_screen/bloc/core_screen_bloc.dart';
import '../bloc/main_appbar_cubit.dart';
import '../bloc/main_bloc.dart';
import '../widgets/build_from_state.dart';
import '../widgets/nav_bar_component.dart';
import '../widgets/nav_web_component.dart';

class MainScreenWeb extends StatelessWidget {
  const MainScreenWeb({super.key});

  @override
  build(BuildContext context) {
    return BlocProvider<MainScreenBloc>(
      create: (_) => MainScreenBloc(
        repository: context.read<AppRepository>(),
        appChatService: context.read<ChatService>(), // Przekazanie instancji AppBarCubit
        appBarCubit: context.read<MainScreenControlCubit>(), // Przekazanie instancji AppBarCubit
      ),
      child: const MainView(),
    );

    //  final appBarCubit = MainScreenControlCubit(); // Ręczna inicjalizacja
    //  appBarCubit.updateAppBar(
    //    title: '', // Domyślny tytuł AppBar
    //    isVisible: false, // Pokazanie AppBar
    //    onBackPressed: () {},
    //  );
    //  return MultiBlocProvider(
    //    providers: [
    //      BlocProvider<MainScreenBloc>(
    //        create: (_) => MainScreenBloc(
    //         repository: context.read<AppRepository>(),
    //         appBarCubit: context.read<MainScreenControlCubit>(), // Przekazanie instancji AppBarCubit
    //       ),
    //     ),
    //   ],
    //   child: const MainView(),
    //  );
    //  return const MainView();
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showMenu = false;
  int _lastMenuIndex = 0;
  int chatCounter = 0 ;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainScreenBloc, MainScreenState>(
      listener: (context, state) {
        if (state is StartMainScreenState) _selectedIndex = 0;
        if (state is DuelsMainScreenState) _selectedIndex = 2;
        if (state is NotificationMainScreenState) _selectedIndex = 1;
        if (state is RanksMainScreenState) _selectedIndex = 3;
        if (state is StatsMainScreenState) _selectedIndex = 5;
        if (state is CardsMainScreenState) _selectedIndex = 5;
        if (state is NewsMainScreenState) _selectedIndex = 5;
        if (state is ContactMainScreenState) _selectedIndex = 5;

        if (state is LogoutMainScreenState) {
          context.read<CoreScreenBloc>().add(CoreScreenCheckAuthenticationEvent());
        }
      },
      builder: (context, state) {
        var user = state.user;
        var menuLock = (state.stageData?.stageNumber??0)!=0;
        var notificationCounters = state.notificationCounters;
        chatCounter = state.chatCounter;




        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
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
                        child: Row(
                          children: [
                            if (state.menuIsVisible)
                              NavBarComponent(),





                              //   NavWebComponent(
                           //     selectedIndex: _selectedIndex,
                           //     onNavItemTapped: (index) => _onNavItemTapped(navItems[index]),
                           //     navItems: navItems,
                           //   ),
                            Expanded(
                              child: Align(
                                key: UniqueKey(),
                                alignment: Alignment.topCenter,
                                child: buildWidgetBasedOnState(state),
                              ),
                            )
                          ],
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onNavItemTapped(NavItem item) {
    if (item.isEnabled) {
      setState(() {
        _selectedIndex = item.index;
        _lastMenuIndex = item.index;
      });
    }

    if (item.onTap != null) {
      item.onTap!();
    }
  }

}


class NavBarComponent extends StatefulWidget {
  const NavBarComponent({super.key});

  @override
  _NavBarComponentState createState() => _NavBarComponentState();
}

class _NavBarComponentState extends State<NavBarComponent> {
  int _selectedIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Uruchamiamy Timer, który odświeża się co 5 sekund
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {}); // Odświeżenie UI, aby pobrać nowe wartości
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Zatrzymujemy Timer przy zamykaniu widgetu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainScreenBloc, MainScreenState>(
      builder: (context, state) {
        var menuLock = (state.stageData?.stageNumber ?? 0) != 0;
        var notificationCounters = state.notificationCounters;
        var chatCounter = state.chatCounter + state.groupChatCounter;

        final List<NavItem> navItems = [
          NavItem(
              index: 0,
              label: "Vehicle",
              iconPath: Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToHomeEvent());
              }),
          NavItem(
              count: state.notificationCounter,
              index: 1,
              label: "Notifications",
              iconPath:  Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToNotificationEvent());
              }),
          NavItem(
              index: 2,
              label: "Duels",
              iconPath:  Icons.abc,
              isEnabled: menuLock,
              onTap: () {
                context.read<MainScreenBloc>().add(ShowToastEvent(message: ''));
              }),
          NavItem(
              index: 3,
              label: "Challenges",
              iconPath:  Icons.abc,
              isEnabled: menuLock,
              onTap: () {
                context.read<MainScreenBloc>().add(ShowToastEvent(message: ''));
              }),
          NavItem(
              index: 4,
              label: "Rankings",
              iconPath:  Icons.abc,
              isEnabled: menuLock,
              onTap: () {
                context.read<MainScreenBloc>().add(ShowToastEvent(message: ''));
              }),
          NavItem(
              count: state.newsCounter,
              index: 5,
              label: "News",
              iconPath: Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToNewsEvent());
              }),
          NavItem(
              index: 6,
              label: "Wall",
              iconPath: Icons.abc,
              isEnabled: menuLock,
              onTap: () {
                context.read<MainScreenBloc>().add(ShowToastEvent(message: ''));
              }),
          NavItem(
              index: 7,
              count: chatCounter,
              label: "Rozmowy",
              iconPath:  Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToChatEvent(''));
              }),
          NavItem(
              index: 8,
              label: "Your Account",
              iconPath: Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToAccountEvent());
              }),
          NavItem(
              index: 9,
              label: "Contact",
              iconPath:  Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToContactEvent());
              }),
          NavItem(
              index: 10,
              label: "Rules",
              iconPath:  Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(LogoutEvent());
              }),
          NavItem(
              index: 11,
              label: "Log out",
              iconPath: Icons.abc,
              onTap: () {
                context.read<MainScreenBloc>().add(LogoutEvent());
              }),
        ];

        return NavWebComponent(
          selectedIndex: _selectedIndex,
          onNavItemTapped: (index) => _onNavItemTapped(navItems[index]),
          navItems: navItems,
        );
      },
    );
  }

  void _onNavItemTapped(NavItem item) {
    if (item.isEnabled) {
      setState(() {
        _selectedIndex = item.index;
      });
    }
    item.onTap?.call();
  }
}
