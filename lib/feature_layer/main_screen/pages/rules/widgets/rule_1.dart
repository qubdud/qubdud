import 'package:qb/shared/constants.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/widgets/w_card.dart';

Widget Rule1() {
  return WCard(color: cLighterBrown,
      child: Column(children: [
    SelectableText.rich(
       TextSpan(
      style: TextStyle(fontSize: 16.0, color: cDarkBrown),
      children: [
        TextSpan(
          text: "Hello Nexi Explorers!\n\n",
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: cDarkBrown),
        ),
        TextSpan(
          text:
              "We're so glad you could join us. We hope you'll have an unforgettable and rewarding experience on the incredible adventure you're now a part of.\n\nNexi Explorers, like any great journey, has it's own set of rules. Like 'be friendly', 'wear sunscreen in sunny places' and 'enjoy the ride.\n\nOur list of rules and definitions will help you learn more about your role in Nexi Explorers, your activities and your prizes.\n\nWe encourage you to consult our \"RULES OF THE ROAD\" guide whenever you want to check the dates or points for a particular activity.",
        ),
      ],
    ))
  ]));
}
