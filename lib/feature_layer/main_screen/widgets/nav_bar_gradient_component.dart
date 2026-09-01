import 'package:flutter/material.dart';

Widget NavBarGradientComponent(BuildContext context) {
  return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 22,
        child: Image.asset(
          'assets/images/menu_mob.png',
          fit: BoxFit.fill,
        ),
      ));
}
