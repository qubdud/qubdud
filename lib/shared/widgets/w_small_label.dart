import 'package:flutter/material.dart';

Widget WSmallLabel({required String text, Color? color}) {
  return Column(children: [
    Center(
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const SizedBox(
      height: 16,
    ),
  ]);
}
