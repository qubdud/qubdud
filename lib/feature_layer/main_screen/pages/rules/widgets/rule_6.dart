import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule6() {
  return WCard(
    color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
         TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "Prizes, their distribution and rankings\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text: 'We mentioned earlier that this was going to be a very rewarding journey, didn\'t we? Well, it is, literally!\n\nIn Nexi Explorers you stand a chance of winning 4 different types of prizes!',
        ),
      ],
    )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n\n1. Grand Prize: A Trip to Dubai!",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: '\nPack your bags! The votes are in, and the winning destination is… Dubai! \nThe top 2 teams and the best individual performers will win a 4-day dream trip to this dazzling city. Let’s make every challenge count!',
                ),
              ],
            )),


        SizedBox(height: 16,),
        Image.asset('assets/images/rule_6.png', fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "Invitations for this trip will be given to: \n\n ◦ all members of the top 2 teams in the gamification with the highest score in all categories \n\n ◦ 9 people with the highest individual scores in the educational challenges\n\n ◦ 9 people with the highest individual score in the business tasks.\n\n\nVoting for one of the two destinations will be available when you first log in to the platform or app.",
                  style: TextStyle(color: cDarkBrown),
                ),
              ],
            )),

        SizedBox(height: 16,),

        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n2. Halftime prizes",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: '\nEvery 45 days, we will award prizes to the 10 teams with the most points overall.',
                ),
              ],
            )),


        SizedBox(height: 16,),
        Image.asset('assets/images/rule_7.png', fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),

        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n3. Vouchers worth €20",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: ' for the top 30 users in the Knowledge Duels at a given stage. You can redeem the vouchers in the online shop or on the shopping platform, depending on your country:',
                ),
              ],
            )),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: '\n  ◦  Greece - electroholic.gr - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Slovenia - mimovrste.com - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Czech Republic - alza.cz -  500 CZK (20 EUR)',
                ),
                TextSpan(
                  text: '\n  ◦  Hungary - edenred.com - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Poland - allegro.pl - 80 PLN (20 EUR)',
                ),
                TextSpan(
                  text: '\n  ◦  Slovakia - alza.sk - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Italy - amazon.it - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Croatia - edenred.com - 20 EUR',
                ),
                TextSpan(
                  text: '\n  ◦  Serbia - edenred.com - 20 EUR',
                ),
              ],
            )),
        SizedBox(height: 16,),
        Image.asset('assets/images/rule_8.png', fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),
        SelectableText.rich(
             TextSpan(
              style: TextStyle(fontSize: 16.0, color: cDarkBrown),
              children: [
                TextSpan(
                  text: "\n4. Souvenir stickers ",
                  style: TextStyle(fontWeight: FontWeight.bold, color: cDarkBrown),
                ),
                TextSpan(
                  text: '\nThese are virtual souvenirs from the visited country with a significant bonus! At the end of each stage, these stickers will be given to the 30 teams with the highest score in the educational category (duels + modules) at the end of the given stage. Each sticker means a bonus of 30 points for the whole team in the checkpoint ranking.',
                ),
              ],
            )),
        SizedBox(height: 16,),
        Image.asset('assets/images/rule_9.png', fit: BoxFit.fitWidth,),
        SizedBox(height: 16,),


  ]));
}
