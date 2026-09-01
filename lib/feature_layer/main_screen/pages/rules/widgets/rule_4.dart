import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule4() {
  return WCard(
    color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
       TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "Scored activities\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text: 'As you travel through Nexi\'s European countries, you\'re sure to be filled with incredible sights, local experiences and rewarding activities!',
        ),
      ],
    )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n\n1. Business tasks - ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: 'this type of task is assigned to you and members of your team  based on your country and department affiliation. These tasks will be displayed under the \'Your Account\' tab on the gamification platform. For team rankings the completion of the task is scored only once per month.  Completing business tasks will earn points for the team and individually for you. They are divided into three levels of difficulty:',
                ),
              ],
            )),

        SizedBox(height: 16,),
        Image.asset('assets/images/rule_3.png',fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: 'The points for the business tasks are updated once a month, after the closed calendar month.',
                ),
              ],
            )),
        SizedBox(height: 16),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "2. Open business tasks - ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: 'this task type is assigned to specific users based on their country, department affiliation and position. These tasks can be completed multiple times. Every open business task will be marked as such clearly in its description available in the ‘Your Account’ tab on the gamification platform.',
                ),
              ],
            )),

        Row(
          children: [
            SelectableText.rich(
              textAlign: TextAlign.start,
                 TextSpan(
                  style: TextStyle(fontSize: 16.0, color: cDarkBrown),
                  children: [
                    TextSpan(
                      text: '\n  ◦  Each completion earns points:',
                    ),
                  ],
                )),
          ],
        ),

        SizedBox(height: 16,),
        Image.asset('assets/images/rule_3.png',fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),


        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\nRemember:\n',  style: TextStyle(fontSize: 16.0, color: cDarkBrown,fontWeight: FontWeight.bold),

                ),


                TextSpan(
                  text: 'Repeated completions only count toward your individual business ranking that selects the grand prize winners. For team rankings, all business tasks are treated as closed—only the first completion earns points. To reassure the fairness of the game and make sure all users bring the same value to the team we count the percentage of accomplished tasks and reevaluate it into points.',
                ),
  TextSpan(
  text: '\n\nFor example: \nTeam A (consisting of 5 members) accumulated a total of 2,100 points for Business Tasks completion during the Competition. The maximum number of points Team A could have earned for Business Tasks if all Team members had completed all assigned tasks was 3,000.\n\nTeam B (consisting of 4 members) accumulated a total of 1,200 points Business Tasks completion during the Competition. The maximum number of points Team B could have earned for Business Tasks if all Team members had completed all assigned tasks was 1,500.\n\nTeam A completed Tasks at a level of 70% by the end of the Competition (2,100/3,000 * 100%), while Team B completed tasks at a level of 80% (1,200/1,500 * 100%). In this case, Team B ranks higher in the Overall Ranking Team.',
  ),

  TextSpan(
  text: '\n\nReminder:\n',style: TextStyle(fontSize: 16.0, color: cDarkBrown,fontWeight: FontWeight.bold),
  ),
  TextSpan(
  text: 'This system is only relevant for the team rankings. Individual users competing in individual rankings accumulate points every time they complete an assigned Business Task whether it’s closed (then the points are counted once) or open (then every completion counts toward individual ranking).',
  ),

              ],
            )),


        SizedBox(height: 24,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "3. Educational tasks - ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: 'this type of task consists of:',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  knowledge duels - duels are held every 5 calendar days. In each duel there are 9 questions. Correctness and quickness of answering are taken into account. Each correct answer is worth 10 points and winning the duel is worth a bonus of 20 points. Points for duels are awarded to both the whole team and you as a individual user;',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  learning modules - there are links in the main view of the platform/app that will take you to the currently running modules. Each level requires 2 modules to be completed. Completion of 1 module is worth 50 points for the team and you as the individual user.',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  learning modules - there are links in the main view of the platform/app that will take you to the currently running modules. Each level requires 2 modules to be completed. Completion of 1 module is worth 50 points for the team and you as the individual user.',
                ),
              ],
            )),

        SizedBox(height: 24,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "4. Special missions - ",
                  style: TextStyle( fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: 'each stage will have 2 missions of this type, each lasting 5 days, with themes based on:',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  the culture of the country in which the stage takes place,',
                ),
              ],
            )),
        Row(
          children: [
            SelectableText.rich(
                 TextSpan(
                  style: TextStyle(fontSize: 16.0, color: cDarkBrown),
                  children: [
                    TextSpan(
                      text: '\n  ◦  Nexi as an international organisation,',
                    ),
                  ],
                )),
          ],
        ),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  integration with other participants in the gamification.',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\nCompleted special mission earns 160 points for the team and for you as an individual user. You will be also able to share the result of your participation in the mission with other explorers on a shared digital board, where others can post their reactions and give their tips in the comments. Don’t keep these big and small successes for yourself!',
                ),
              ],
            )),


  ]));
}
