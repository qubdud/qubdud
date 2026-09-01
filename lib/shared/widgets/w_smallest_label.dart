import 'package:flutter/material.dart';

Widget WSmallestLabel({required String text, Color? color}) {
  return Column(children: [
    Center(
      child: Text(
        textAlign: TextAlign.center,
        text,
        style: TextStyle(
          color: color,
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    const SizedBox(
      height: 8,
    ),
  ]);
}
