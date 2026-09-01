import 'package:qb/feature_layer/main_screen/pages/account/bloc/account_page_bloc.dart';
import 'package:qb/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import '../../../../../domain_layer/domain_models/business_task.dart';
import '../../../../../domain_layer/domain_models/user_stats.dart';

import '../../../../../shared/widgets/w_card.dart';

import '../../../../../shared/widgets/w_semi_circle_chart.dart';
import '../../../bloc/main_bloc.dart';

class StatisticsAccountPage extends StatelessWidget {
  const StatisticsAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return View();
  }
}

class View extends StatefulWidget {
  const View({super.key});

  @override
  State<View> createState() => _ViewState();
}

class _ViewState extends State<View> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;
    var user = context.read<MainScreenBloc>().state.user;
    var team = context.read<AccountPageBloc>().state.teamInfo;
    var userStatistics = context.read<AccountPageBloc>().state.userStatistics;
    UserStatistics userStat;
    var businessTasks = context.read<AccountPageBloc>().state.businessTasks;

    if (userStatistics != null) {
      userStat = userStatistics;
    } else {
      var stats = [
        UserDetailStat(name: 'name', points: 0),
        UserDetailStat(name: 'name', points: 0),
        UserDetailStat(name: 'name', points: 0),
        UserDetailStat(name: 'name', points: 0),
        UserDetailStat(name: 'name', points: 0),
      ];
      userStat = UserStatistics(detailStats: stats, points: 0, rank: 0);
    }

    var sum = userStat.detailStats[0].points + userStat.detailStats[1].points + userStat.detailStats[2].points + userStat.detailStats[3].points + userStat.detailStats[4].points;

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
      child: SizedBox(
        width: maxColumnSize,
        child: Column(
          children: [
            SizedBox(
              height: 8,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ],
                )),
            const SizedBox(height: 60),
            Column(
              children: [
                WSmallLabel(text: 'Score Details'.toUpperCase()),
                SizedBox(
                  height: 16,
                ),
                WCard(
                  color: cLighterBrown,
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 300,
                                child: WSemiCircleChart(
                                    values: sum == 0
                                        ? [1, 1, 1, 1, 1]
                                        : [userStat.detailStats[3].points, userStat.detailStats[0].points, userStat.detailStats[1].points, userStat.detailStats[2].points , userStat.detailStats[4].points],
                                    colors: sum == 0 ? [Colors.grey, Colors.grey, Colors.grey, Colors.grey, Colors.grey] : [cDarkBlue, cMidCyan, cMidRed, cMidOrange, cMidPurple]),
                              ),
                            ),
                            Center(
                                child: Container(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 70,
                                  ),
                                  SelectableText(
                                    'Your score:',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      SelectableText(
                                        userStat.points.toString(),
                                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                                      ),
                                      SelectableText(
                                        ' PTS',
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ))
                          ],
                        ),
                        SizedBox(
                          height: 24,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cDarkBlue,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            SelectableText(
                              'Business Tasks',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                                child: SizedBox(
                              width: 10,
                            )),
                            SelectableText(
                              '${userStat.detailStats[3].points.toString()} PTS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cDarkBlue),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cMidCyan,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            SelectableText(
                              'Duels',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                                child: SizedBox(
                              width: 10,
                            )),
                            SelectableText(
                              '${userStat.detailStats[0].points.toString()} PTS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cMidCyan),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cMidRed,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            SelectableText(
                              'Educational Tasks',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                                child: SizedBox(
                              width: 10,
                            )),
                            SelectableText(
                              '${userStat.detailStats[1].points.toString()} PTS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cMidRed),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cMidOrange,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            SelectableText(
                              'Challenges',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                                child: SizedBox(
                              width: 10,
                            )),
                            SelectableText(
                              '${userStat.detailStats[2].points.toString()} PTS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cMidOrange),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: cMidPurple,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            SelectableText(
                              'Others',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                                child: SizedBox(
                                  width: 10,
                                )),
                            SelectableText(
                              '${userStat.detailStats[4].points.toString()} PTS',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cMidPurple),
                            ),
                          ],
                        ),



                        SizedBox(
                          height: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (businessTasks.isNotEmpty) const SizedBox(height: 60),
            if (businessTasks.isNotEmpty) WSmallLabel(text: 'Business tasks'.toUpperCase()),
            if (businessTasks.isNotEmpty)
              WCard(
                color: cLighterBrown,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: businessTasks.map((task) => _buildTaskItem(task)).toList(),
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(BusinessTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SelectableText(
                          '${task.number}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SelectableText(
                        ' •',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SelectableText(
                        '${task.points} PTS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                SelectableText(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, Color> groupColors = {
  'OP': cMidRed,
  'OT': cMidOrange,
  'IT': cMidPurple,
};
