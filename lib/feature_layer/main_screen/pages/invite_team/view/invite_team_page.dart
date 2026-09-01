import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/feature_layer/main_screen/pages/invite_team/view/invite_invite_team_page.dart';
import 'package:qb/feature_layer/main_screen/pages/invite_team/view/offer_invite_team_page.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/team_invite.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/invite_team_page_bloc.dart';

class InviteTeamPage extends StatelessWidget {
  const InviteTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InviteTeamPageBloc(repository: context.read<AppRepository>()),
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
  List<TeamInvite> filter = [];
  TextEditingController search = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController department = TextEditingController();
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  Widget build(BuildContext context) {
    return BlocConsumer<InviteTeamPageBloc, InviteTeamPageState>(
      listener: (context, state) {
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

  Widget _buildWidgetBasedOnState(InviteTeamPageState state, BuildContext context) {
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
                    'Send invitations',textAlign: TextAlign.center,
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
                  'Offer received',textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              if (state.usersRequests.isNotEmpty) const SizedBox(width: 8),
              if (state.usersRequests.isNotEmpty)
                CircleAvatar(
                  radius: 8,
                  foregroundColor: Colors.white,
                  backgroundColor: cMidPink,
                  child: Text(
                    state.usersRequests.length.toString(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          )),
        ],
        onTap: (value) {
          if(value==0){
            context.read<InviteTeamPageBloc>().add(GoToMainInviteTeamPageEvent());
          } else {
            context.read<InviteTeamPageBloc>().add(GoToOfferTeamPageEvent());
          }

        },
      );
    }

    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is InviteTeamPageLoadingState) {
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          backgroundColor: cLighterBrown,
          title: 'Invite passengers',
          height: 105,
          isVisible: true,
          child: SizedBox(
            width: maxColumnSize,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: tabBar()),
          ));

      return const Loading(key: ValueKey('Loading'));
    } else if (state is! InviteTeamPageLoadingState) {
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          backgroundColor: cLighterBrown,
          title: 'Invite passengers',
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
              if (isWideScreen) WLabel(text: 'Find a team'),
              SizedBox(
                height: 24,
              ),
              if (isWideScreen) tabBar(),
              if (isWideScreen)  SizedBox(
              height: 24,
              ),
              if(state is InviteTeamPageInviteState)   InviteInviteTeamPage(key: UniqueKey()),
              if(state is InviteTeamPageOfferState)  OfferInviteTeamPage(),
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
