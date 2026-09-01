import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../../app/app.dart';

showToastError({required String text, Color color = Colors.red, int milliseconds = 4000, bool positioned = true}) {
  var fToast = FToast();
  fToast.init(NavigationService.navigatorKey.currentContext!);
  fToast.removeQueuedCustomToasts();
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
        child: SizedBox(
          width: 350,
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
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: cMidPink,
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Center(
                      child: SelectableText(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
