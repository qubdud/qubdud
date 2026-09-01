import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants.dart';
import 'menu_component.dart';

Widget MenuLabel(BuildContext context, MenuItem item) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
    child: Row(
      children: [
        Text(
          item.text,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: item.isEnabled
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  : cDarkBrown.withOpacity(0.3)),
        ),
        const SizedBox(width: 8),
        if (item.count > 0)
          CircleAvatar(
            radius: 8,
            foregroundColor: Colors.white,
            backgroundColor: cMidPink,
            child: Text(
              item.count.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );
}
