import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/constants.dart';
import 'menu_component.dart';

Widget MenuLabel(BuildContext context, MenuItem item) {
  final color = item.isEnabled
      ? (Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black)
      : cDarkBrown.withOpacity(0.3);
  return ListTile(
    minTileHeight: 48,
    leading: item.icon == null ? null : Icon(item.icon, color: color),
    title: Text(
      item.text,
      style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w600, color: color),
    ),
    trailing: item.count > 0
        ? CircleAvatar(
            radius: 8,
            foregroundColor: Colors.white,
            backgroundColor: cMidPink,
            child: Text(
              item.count.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          )
        : null,
  );
}
