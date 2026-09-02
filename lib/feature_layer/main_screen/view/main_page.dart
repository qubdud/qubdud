
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/firebase_service.dart';

import '../../../shared/constants.dart';
import '../../../shared/functions/effective_role.dart';
import '../../../shared/globals.dart';
import '../../../shared/theme_controller.dart';
import '../../core_screen/bloc/core_screen_bloc.dart';
import '../bloc/main_appbar_cubit.dart';
import '../bloc/main_bloc.dart';
import '../widgets/app_bar_component.dart';
import '../widgets/backdrop_blur.dart';
import '../widgets/build_from_state.dart';
import '../widgets/menu_component.dart';
import '../widgets/nav_bar_component.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  build(BuildContext context) {
    return BlocProvider<MainScreenBloc>(
      create: (_) => MainScreenBloc(
        appBarCubit: context.read<MainScreenControlCubit>(),
        appChatService: context.read<ChatService>(),
        appFirebaseService: context.read<FirebaseService>(),
      ),
      child: const MainView(),
    );
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with SingleTickerProviderStateMixin {
  int _selectedIndex = 99;
  bool _showMenu = false;
  bool _lastAppBarVisibility = false;
  int _lastMenuIndex = 0;
  bool _animationEnded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool isMenuEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationEnded = true; // Animation finished
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _animationEnded = false; // Animation reset
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MainScreenBloc, MainScreenState>(
      listener: (context, state) {
        if (state is StartMainScreenState) _selectedIndex = 0;

        if (state is LogoutMainScreenState) {
          context.read<CoreScreenBloc>().add(CoreScreenCheckAuthenticationEvent());
        }
        if (state is InitialMainState) {
          context.read<MainScreenBloc>().add(InitEvent());
        }
      },
      builder: (context, state) {

        List<NavItem> navItems = [
          NavItem(
              index: 0,
              label: "Start",
              iconPath:  Icons.home_outlined,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToHomeEvent());
              }),
          if (!isCompanyMode(state.user))
            NavItem(
                index: 2,
                label: "Dodaj",
                iconPath: Icons.add_box_outlined,
                isEnabled: isMenuEnabled,
                locked: Globals.instance.anonim,
                onTap: () {
                  context.read<MainScreenBloc>().add(GoToDodajEvent());
                }),
          NavItem(
              index: 3,
              label: "Kontakty",
              iconPath: Icons.chat_outlined,
              locked: Globals.instance.anonim,
              count: state.chatCounter,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToChatEvent(''));
              }),

          NavItem(
              index: 5,
              label: "Alerty",
              iconPath: Icons.notifications_none,
              locked: Globals.instance.anonim,
              count: state.notifCounter,
              onTap: () {
                context.read<MainScreenBloc>().add(GoToPowiadomieniaEvent());
              }),
          NavItem(
            index: 4,
            label: "Profil",
            iconPath: Icons.account_circle_outlined,
            locked: Globals.instance.anonim,
              onTap: () {
                  context.read<MainScreenBloc>().add(GoToProfilFirmaEvent());
                }
              ),
          NavItem(
              index: 10,
              label: "Menu",
              iconPath: Icons.menu,
              onTap: () {}),
        ];

        List<MenuItem> menuItems = [
          if (state.user?.firma == true)
            MenuItem(
                text: Globals.instance.companyView
                    ? 'Przełącz na: Użytkownik'
                    : 'Przełącz na: Firma',
                onTap: () async {
                  await setCompanyView(!Globals.instance.companyView);
                  if (context.mounted) {
                    context.read<MainScreenBloc>().add(InitEvent());
                  }
                }),
          MenuItem(
              text: 'Regulamin',
              onTap: () {
                context.read<MainScreenBloc>().add(GoToRulesEvent());
              }),
          MenuItem(
              text: 'Wyloguj się',
              onTap: () {
                context.read<MainScreenBloc>().add(LogoutEvent());
              }),
        ];

        return BlocBuilder<MainScreenControlCubit, MainScreenControlState>(
          builder: (context, controlState) {


            return


              PopScope(
                canPop: state is StartMainScreenState,
                onPopInvokedWithResult: (didPop, res){

                  if(!didPop){
                   context.read<MainScreenBloc>().add(GoToHomeEvent());
                  }
                },


                child: Scaffold(
                resizeToAvoidBottomInset: true, // Dopuszczamy przesuwanie innych elementów

                bottomNavigationBar: controlState.isMenuVisible
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MenuComponent(
                      showMenu: _showMenu,
                      menuItems: menuItems,
                      onMenuItemTapped: (item) => _onMenuItemTapped(item),
                    ),
                    NavBarComponent(
                      selectedIndex: _selectedIndex,
                      onNavItemTapped: (index) => _onNavItemTapped(
                          navItems.firstWhere((n) => n.index == index)),
                      navItems: navItems,
                    ),
                  ],
                )
                    : null,
                backgroundColor: Colors.transparent,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppBarComponent(key: ValueKey('AppBarCompKey')),
                    Expanded(
                      child: Stack(
                        children: [
                          AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
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
                              child: Align(
                                key: ValueKey(state),
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: maxColumnSize),
                                  child: buildWidgetBasedOnState(state),
                                ),
                              )),
                         // if (_showMenu || _animationEnded) BackdropBlur(_animation),
                         // if (controlState.isMenuVisible) NavBarGradientComponent(context),
                        ],
                      ),
                    ),
                  ],
                ),
                            ),
              );

          },
        );


      },
    );
  }

  void _onNavItemTapped(NavItem item) {
    if (item.isMenu) {
      setState(() {
        if (_showMenu) {
          _showMenu = false;
          _animationController.reverse();
          _selectedIndex = _lastMenuIndex;
          context.read<MainScreenControlCubit>().setIsVisible(_lastAppBarVisibility);
        } else {
          _lastMenuIndex = _selectedIndex;
          _selectedIndex = item.index;
          _animationController.forward();
          _showMenu = true;
          _lastAppBarVisibility = context.read<MainScreenControlCubit>().getIsVisible();
          context.read<MainScreenControlCubit>().setIsVisible(false);
        }
      });
    } else {
      if (item.isEnabled) {
        setState(() {
          _animationController.reverse();
          _selectedIndex = item.index;
          _lastMenuIndex = item.index;
          _showMenu = false;
          context.read<MainScreenControlCubit>().setIsVisible(_lastAppBarVisibility);
        });
      }

      if (item.onTap != null) {
        item.onTap!();
      }
    }
  }

  void _onMenuItemTapped(MenuItem item) {
    setState(() {
      _selectedIndex = 99;
      _showMenu = false;
      _animationController.reverse();
    });
    if (item.onTap != null) {
      item.onTap!();
    }
  }
}
