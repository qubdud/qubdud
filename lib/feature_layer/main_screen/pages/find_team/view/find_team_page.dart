import 'package:qb/feature_layer/main_screen/bloc/main_appbar_cubit.dart';
import 'package:qb/shared/constants.dart';
import 'package:qb/shared/widgets/w_input_field.dart';
import 'package:qb/shared/widgets/w_label.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../domain_layer/repository.dart';
import '../../../../../../shared/widgets/loading.dart';
import '../../../../../domain_layer/domain_models/team_invite.dart';
import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';
import '../../../../../shared/widgets/w_smallest_label.dart';
import '../../../bloc/main_bloc.dart';
import '../../news/widgets/news_card.dart';
import '../bloc/find_team_page_bloc.dart';

class FindTeamPage extends StatelessWidget {
  const FindTeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FindTeamPageBloc(repository: context.read<AppRepository>()),
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
  List<TeamInvite> filter = [];
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<FindTeamPageBloc>().state;
    if (state is FindTeamPageMainState) {
      filter = state.invitableTeams;
    }
  }

  Widget build(BuildContext context) {
    return BlocConsumer<FindTeamPageBloc, FindTeamPageState>(
      listener: (context, state) {
        if (state is FindTeamPageMainState) {
          setState(() {
            filter = state.invitableTeams;
          });
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

  Widget _buildWidgetBasedOnState(FindTeamPageState state, BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;

    if (state is FindTeamPageLoadingState) {
      context.read<MainScreenControlCubit>().updateAppBar(
          onBackPressed: () {
            context.read<MainScreenBloc>().add(GoToHomeEvent());
          },
          backgroundColor: cLighterBrown,
          title: 'Find a Team',
          height: 144,
          isVisible: true,
          child: SizedBox(
            width: maxColumnSize,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: WInputField(
                controller: controller,
                onChanged: (val) {
                  setState(() {
                    filter = state.invitableTeams.where((a) {
                      return a.teamName.toLowerCase().contains(val.toLowerCase());
                    }).toList();
                  });
                },
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                focusColor: cDarkBlue,
              ),
            ),
          ));

      return const Loading(key: ValueKey('Loading'));
    } else if (state is! FindTeamPageInitialState) {
      return SingleChildScrollView(
        key: isWideScreen ? ValueKey('key') : UniqueKey(),
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
            SelectableText(
              'You can offer to join the teams below.  The team leader has 24 hours to respond  to your offer. After this time, you can reapply  to join the team again.',
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: 24,
            ),
            if (!isWideScreen)
              Column(
                children: filter.map((item) {
                  print(item.teamName);

                  return _buildInviteCard(item);
                }).toList(),
              ),
            if (isWideScreen)
              SizedBox(
                width: maxColumnSize,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: WInputField(
                    controller: controller,
                    onChanged: (val) {
                      setState(() {
                        filter = state.invitableTeams.where((a) {
                          return a.teamName.toLowerCase().contains(val.toLowerCase());
                        }).toList();
                      });
                    },
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search',
                    focusColor: cDarkBlue,
                  ),
                ),
              ),
            if (isWideScreen)
              SizedBox(
                height: 24,
              ),
            if (isWideScreen)
              Wrap(
                children: filter.map((item) {
                  return SizedBox(width: 380, child: _buildInviteCard(item));
                }).toList(),
              ),
            if (filter.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0), // Margines góra-dół
                child: WCard(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        'No search results',
                        style: TextStyle(fontSize: 20),
                      )), // Margines góra-dół),
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      );
    } else {
      return const Loading(key: ValueKey('Loading'));
    }
  }

  Widget _buildInviteCard(TeamInvite invite) {
    return Column(
      children: [
        WCard(
          color: cLighterBrown,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SelectableText(
                  invite.teamName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        SelectableText('Team score:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            SelectableText(
                              "${invite.points}",
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            SelectableText('  PTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                          ],
                        )
                      ],
                    ),
                    Column(
                      children: [
                        SelectableText('Members:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SelectableText(
                          "${invite.memberCount}",
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                if(!invite.isInvitationSent)WButton(
                  text: 'Offer to join',
                  onPressed: () {
                    context.read<FindTeamPageBloc>().add(TryRequestToJoinFindTeamPageEvent(invite.teamId));
                    
                  },
                ),
                if(invite.isInvitationSent)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(Icons.check),
                    SizedBox(width: 8,),
                    SelectableText('Invitation sent',style: TextStyle(fontWeight: FontWeight.bold),)
                  ]),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 16,
        )
      ],
    );
  }
}
