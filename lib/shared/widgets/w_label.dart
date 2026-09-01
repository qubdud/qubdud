import 'package:flutter/material.dart';

Widget WLabel({required String text, Color? color}) {
  return Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Center(
        child: Text(
          textAlign: TextAlign.center,
          text,
          style: TextStyle(
            color: color,
            fontFamily: 'Poppins',
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
    const SizedBox(
      height: 24,
    ),
  ]);
}
