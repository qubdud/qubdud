import 'dart:ui';
import 'package:flutter/material.dart';

Widget BackdropBlur(Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final value = animation.value;
      return Positioned.fill(
        child: Stack(
          children: [
            Container(
              color: Colors.black.withOpacity(value / 2),
            ),
            //   Positioned.fill(
            //     child: BackdropFilter(
            //       filter: ImageFilter.blur(
            //         sigmaX: value * 10,
            //         sigmaY: value * 10,
            //       ),
            //       child: Container(color: Colors.transparent),
            //     ),
            //   ),
          ],
        ),
      );
    },
  );
}
