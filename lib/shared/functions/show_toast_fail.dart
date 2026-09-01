import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../../app/app.dart';

showToastFail({required String text, Color color = Colors.red, int milliseconds = 3000, bool positioned = true}) {
  var fToast = FToast();
  fToast.init(NavigationService.navigatorKey.currentContext!);
  fToast.showToast(
    gravity: ToastGravity.CENTER,
    positionedToastBuilder: positioned
        ? (context, child, gravity) {
            return Positioned(
              bottom: 150,
              child: child,
            );
          }
        : null,
    toastDuration: Duration(milliseconds: milliseconds),
    child: SizedBox(
      width: MediaQuery.of(NavigationService.navigatorKey.currentContext!).size.width,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Material(
            color: Theme.of(NavigationService.navigatorKey.currentContext!).brightness == Brightness.dark ? const Color(0xFF2A2930) : Colors.white,
            elevation: 8, // Ustawienie cienia
            borderRadius: BorderRadius.circular(8), // Opcjonalnie, jeśli chcesz zaokrąglić rogi
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_outlined,
                    size: 50,
                    color: Colors.red,
                  ),
                  Center(
                    child: SelectableText(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
