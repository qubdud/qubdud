
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain_layer/chat_service.dart';
import '../../../domain_layer/firebase_service.dart';

import '../../../shared/constants.dart';
import '../../../shared/globals.dart';
import '../../core_screen/bloc/core_screen_bloc.dart';
import '../bloc/main_appbar_cubit.dart';
import '../bloc/main_bloc.dart';
import '../widgets/app_bar_component.dart';
import '../widgets/build_from_state.dart';
import '../widgets/menu_component.dart';
import '../widgets/nav_bar_component.dart';
import '../../../shared/widgets/offline_banner.dart';

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
  late AnimationController _animationController;
  bool isMenuEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
        // dolny pasek podąża za ekranem także przy nawigacji z alertów/pushy
        if (state is StartMainScreenState) _selectedIndex = 0;
        if (state is ChatMainScreenState && state.id.isEmpty) _selectedIndex = 3;
        if (state is PowiadomieniaMainScreenState) _selectedIndex = 5;
        if (state is ProfilFirmaMainScreenState) _selectedIndex = 4;

        if (state is LogoutMainScreenState) {
          context
              .read<CoreScreenBloc>()
              .add(CoreScreenCheckAuthenticationEvent(toRegister: state.toRegister));
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
                onTap: () => context
                    .read<MainScreenBloc>()
                    .add(SwitchModeEvent(!Globals.instance.companyView))),
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
          if (state.user?.id.isNotEmpty == true)
            MenuItem(text: 'Usuń konto', onTap: _confirmDeleteAccount),
        ];

        return BlocBuilder<MainScreenControlCubit, MainScreenControlState>(
          builder: (context, controlState) {


            return


              PopScope(
                canPop: state is StartMainScreenState,
                onPopInvokedWithResult: (didPop, res){

                  if(!didPop){
                   context.read<MainScreenBloc>().add(GoBackEvent());
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
                body: OfflineBanner(
                  child: Column(
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
                         // if (controlState.isMenuVisible) NavBarGradientComponent(context),
                        ],
                      ),
                    ),
                  ],
                ),
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
      // przed wczytaniem konta ekrany nie mają użytkownika
      if (context.read<MainScreenBloc>().state.user == null) return;
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

  Future<void> _confirmDeleteAccount() async {
    final bloc = context.read<MainScreenBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć konto?'),
        content: const Text(
            'Profil, zgłoszenia, rezerwacje, opinie i pliki zostaną trwale usunięte. Wysłane wiadomości zostaną u rozmówców, podpisane jako „Konto usunięte”. Tego nie da się cofnąć.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usuń konto',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) bloc.add(DeleteAccountEvent());
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
