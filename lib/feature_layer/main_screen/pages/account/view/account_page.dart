import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import 'package:qb/feature_layer/main_screen/pages/account/tab_pages/password/view/passowrd_page.dart';
import 'package:qb/feature_layer/main_screen/pages/account/tab_pages/personal_data_page.dart';
import 'package:qb/feature_layer/main_screen/pages/account/tab_pages/statistics_page.dart';
import 'package:qb/shared/widgets/w_card.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:qb/shared/widgets/w_smallest_label.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../shared/constants.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_label.dart';
import '../../../bloc/main_appbar_cubit.dart';
import '../bloc/account_page_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AccountPageBloc(repository: context.read<AppRepository>()),
      child: const View(),
    );
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {


  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    return BlocConsumer<AccountPageBloc, AccountPageState>(
      listener: (context, state) {
        if(state is AccountPageDeletedState){
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return Center(
                child: WCard(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: isWideScreen ? 16 : 0, horizontal: isWideScreen ? 40 : 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SelectableText(
                            'Your account will be deleted in 3 days',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                          SizedBox(height: 20),
                          SelectableText('After removal you won’t be able to log into your acconut.', textAlign: TextAlign.center,),
                          SizedBox(height: 24,),
                          WButton(
                              colorType: ButtonColorType.white,
                              text: 'Close',
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).pop();
                              }),

                        ],
                      ),
                    )),
              );
            },
          );

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

  Widget _buildWidgetBasedOnState(AccountPageState state, BuildContext context) {
    tabBar() {
      return TabBar(
        isScrollable: false,
        labelColor: cDarkerBlue,
        unselectedLabelColor: cDarkerBlue.withOpacity(0.5),
        labelStyle: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
        indicator: CustomTabIndicator(),
        dividerColor: Colors.transparent,
        dividerHeight: 5,
        indicatorSize: TabBarIndicatorSize.tab,
        controller: tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Statistics',textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Personal data',textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Password',textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        onTap: (value) {
          if(value==0){
            context.read<AccountPageBloc>().add(GoToStatisticsAccountPageEvent());
          } else if(value==1) {
            context.read<AccountPageBloc>().add(GoToPersonalAccountPageEvent());
          } else{
            context.read<AccountPageBloc>().add(GoToPasswordAccountPageEvent());
          }

        },
      );
    }

    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is AccountPageLoadingState) {
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          backgroundColor: cLighterBrown,
          title: 'Your Account',
          height: 105,
          isVisible: true,
          child: SizedBox(
            width: maxColumnSize,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: tabBar()),
          ));

      return const Loading(key: ValueKey('Loading'));
    } else if (state is! AccountPageLoadingState) {
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          backgroundColor: cLighterBrown,
          title: 'Your Account',
          height: 105,
          isVisible: true,
          child: SizedBox(
            width: maxColumnSize,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: tabBar()),
          ));


      return SingleChildScrollView(
        key:ValueKey(state),// key: ValueKey(state.runtimeType),
        child: SizedBox(
          width: maxColumnSize,
          child: Column(
            children: [
              if (isWideScreen)
                SizedBox(
                  height: 60,
                ),
              if (isWideScreen) WLabel(text: 'Your Account'),
              SizedBox(
                height: 24,
              ),
              if (isWideScreen) tabBar(),
              if (isWideScreen)  SizedBox(
                height: 24,
              ),
              if(state is StatisticsAccountPageState)   StatisticsAccountPage(key: ValueKey('StatsAccountPage'),),
              if(state is PersonalAccountPageState)  PersonalAccountPage(key: ValueKey('PersonalAccountPage'),),
              if(state is PasswordAccountPageState)  PasswordAccountPage(key: ValueKey('PassAccountPag'),),
            ],
          ),
        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }
}

class CustomTabIndicator extends Decoration {
  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPainter();
  }
}

class _CustomPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = cDarkerBlue // Kolor podkreślenia
      ..style = PaintingStyle.fill;

    final double width = configuration.size!.width; // Szerokość zakładki
    final double height = 5; // Grubość podkreślenia
    final double radius = 10; // Zaokrąglenie rogów

    final Rect rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + configuration.size!.height - height, // Umiejscowienie pod tekstem
      width,
      height,
    );

    final RRect roundedRect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(radius / 2),
      topRight: Radius.circular(radius / 2),
      bottomLeft: Radius.circular(radius / 2),
      bottomRight: Radius.circular(radius / 2),
    );

    canvas.drawRRect(roundedRect, paint);
  }
}