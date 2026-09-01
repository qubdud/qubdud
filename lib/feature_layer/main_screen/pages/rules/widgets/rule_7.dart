import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:qb/shared/widgets/w_button.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule7() {
  return WCard(
    color: cLighterBrown,
      child: Column(children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: SelectableText.rich(
        textAlign: TextAlign.center,
           TextSpan(
        style: TextStyle(fontSize: 16.0, color: cDarkBrown),
        children: [
          TextSpan(
            text: 'For detailed information on the Nexi Explorers rules, mechanics and prizes,  please refer to the Nexi Explorers Rulebook.',
          ),
        ],
      )),
    ),
SizedBox(height: 16,),
        WButton(text: 'Nexi Explorers Rulebook',onPressed: () async {
          if (await canLaunchUrl(Uri.parse('https://nexiexplorers.com/documents/regulation.pdf'))) {
          await launchUrl(Uri.parse('https://nexiexplorers.com/documents/regulation.pdf'));
          }
        },),
        SizedBox(height: 16,),
  ]));
}
