import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule3() {
  return WCard(
    color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
        TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "Duration\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text: 'The Nexi Explorers programme is very much like a real road trip across Europe. There is a beginning, stages along the way and an end.\n\nNexi Explorers programme lasts 90 calendar days, starting on 07.04.2025 and ending on 05.07.2025.\n\n  ◦  The gamification is divided into ',
        ),
        TextSpan(
          text: '9 stages of 10 calendar days each.',
          style: TextStyle(fontWeight: FontWeight.bold),


        ),
        TextSpan(
          text: '\n\n  ◦  Each stage is a country that the participants will pass through as part of our journey',
        ),



      ],
    )),
        SizedBox(height: 24,),

        Image.asset('assets/images/srule_1.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_2.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_3.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_4.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_5.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_6.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_7.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_8.png',fit: BoxFit.fitHeight,),
        SizedBox(height: 16,),
        Image.asset('assets/images/srule_9.png',fit: BoxFit.fitHeight,),


        
  ]));
}
