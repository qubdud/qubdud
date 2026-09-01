import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule5() {
  return WCard(
    color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
         TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "Counting the scores\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text: 'As you and your team embark on this journey and complete the tasks laid before you, you score points. There are several ways points contribute to the final scores that determine the winners',
        ),
      ],
    )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n\nWhat does the individual points count up to?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
              ],
            )),

        SizedBox(height: 16,),

        Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child:  Column(
              children: [
                Image.asset('assets/images/rule_4.png',width: 500,),
                SizedBox(height:16,)
              ],
            ),
          
          ),
        ),
        SizedBox(height: 16,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n\nWhat does the teams’ points count up to?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
              ],
            )),

        SizedBox(height: 16,),

        Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child:  Column(
              children: [
                Image.asset('assets/images/rule_5.png',width: 500,),
                SizedBox(height: 16,)
              ],
            ),
          
          ),
        ),





  ]));
}
