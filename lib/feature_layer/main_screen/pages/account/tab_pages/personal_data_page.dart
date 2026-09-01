import 'package:qb/feature_layer/main_screen/pages/account/bloc/account_page_bloc.dart';
import 'package:qb/shared/constants.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qb/shared/widgets/w_small_label.dart';
import '../../../../../domain_layer/domain_models/business_task.dart';
import '../../../../../domain_layer/domain_models/user_stats.dart';

import '../../../../../shared/widgets/w_button.dart';
import '../../../../../shared/widgets/w_card.dart';

import '../../../../../shared/widgets/w_semi_circle_chart.dart';
import '../../../bloc/main_bloc.dart';

class PersonalAccountPage extends StatelessWidget {
  const PersonalAccountPage({super.key});

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
  late BuildContext con;

  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    con = context;
    final isWideScreen = MediaQuery.of(context).size.width > minWideScreen;
    var user = context.read<MainScreenBloc>().state.user;

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

            SizedBox(height: 16),
            WButton(text: 'Delete account',

              onPressed: () {
                var parentContext = con;
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
                                  'Do you want to delete your account?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                ),
                                SizedBox(height: 20),
                                SelectableText('This action cannot be undone.', textAlign: TextAlign.center,),
                                SizedBox(height: 20),
                                WButton(
                                    text: 'Yes, delete account',
                                    onPressed: () {
                                      if (mounted) {
                                        parentContext.read<AccountPageBloc>().add(TryDeleteAccountPageEvent());
                                      }
                                      Navigator.of(context, rootNavigator: true).pop();
                                    }),
                                SizedBox(height: 24,),
                                WButton(
                                    colorType: ButtonColorType.white,
                                    text: 'No, go back',
                                    onPressed: () {
                                      Navigator.of(context, rootNavigator: true).pop();
                                    }),

                              ],
                            ),
                          )),
                    );
                  },
                );
              },

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
                SelectableText(
                  '${task.number} • ${task.points} PTS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
