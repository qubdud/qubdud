import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

import '../../feature_layer/main_screen/widgets/shaking_bell.dart';
import '../constants.dart';
import '../../app/app.dart';

showToastPush({required String message,required String tittle, Color color = Colors.red, int milliseconds = 4000, bool positioned = true}) {
  var fToast = FToast();
  fToast.init(NavigationService.navigatorKey.currentContext!);
  fToast.removeQueuedCustomToasts();
  fToast.showToast(
    gravity: ToastGravity.TOP_RIGHT,
    positionedToastBuilder: positioned
        ? (context, child, gravity) {
            return Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 10,
              child: child,
            );
          }
        : null,
    toastDuration: Duration(milliseconds: milliseconds),
    child: SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Material(
          color: Colors.white, // Ustawienie koloru tła na biały
          elevation: 8, // Ustawienie cienia
          borderRadius: BorderRadius.circular(8), // Opcjonalnie, jeśli chcesz zaokrąglić rogi
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                SizedBox(width: 8,),
                ShakingBellIcon(),
                SizedBox(width: 16,),
                Expanded(
                  child: Column(
                    children: [
                      SelectableText(
                        tittle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SelectableText(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
