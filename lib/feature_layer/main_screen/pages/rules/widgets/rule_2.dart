import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule2() {
  return WCard( color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
        TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "What is gamification?\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text: 'Nexi Explorers is a gamification',
          style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text:' - a special, engaging programme that uses elements of game design to combine the fun of games with everyday learning and work. What are these?'
        ),
      ],
    )),
        SizedBox(height: 16,),
        Center(child: Image.asset('assets/images/rule_1.png')),

        SizedBox(height: 16,),

        SelectableText.rich(
            TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: 'In Nexi Explorers you embark on a road trip across Central and Southern Europe, visiting ',
                ),
                TextSpan(
                    text:'9 Nexi countries along the way: Poland, Czech Republic, Slovakia, Hungary, Serbia, Greece, Croatia, Slovenia and Italy.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: 'Each of these countries represents a separate stage of the journey, with unique tasks and challenges. Your goal is to collect as many points as possible by completing tasks. Below, you can explore the different types of tasks we have prepared for you. Your engagement is rewarded with points, and those points grant you truly priceless prizes!\n\nAnd you’re never alone in this fantastic journey, as you’re in a team that is made of your fellow Nexi colleagues from different countries and different departments! So you\'re not only competing for prizes for yourself but also for your entire team!',
                ),
              ],
            )),
        SizedBox(height: 24,),

        Center(child: Image.asset('assets/images/rule_2.png')),
        
        
  ]));
}
